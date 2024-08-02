import 'dart:io';

import 'package:cyberme_flutter/pocket/viewmodels/health_blue.dart';
import 'package:cyberme_flutter/pocket/views/util.dart';
import 'package:flutter/foundation.dart' as f;
import 'package:flutter/material.dart';
import 'package:health_kit_reporter/health_kit_reporter.dart';
import 'package:health_kit_reporter/model/payload/category.dart';
import 'package:health_kit_reporter/model/payload/source.dart';
import 'package:health_kit_reporter/model/payload/source_revision.dart';
import 'package:health_kit_reporter/model/predicate.dart';
import 'package:health_kit_reporter/model/type/category_type.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';

import '../../../main.dart';

class SexualActivityView extends ConsumerStatefulWidget {
  const SexualActivityView({super.key});

  @override
  _SexualActivityViewState createState() => _SexualActivityViewState();
}

class _SexualActivityViewState extends ConsumerState<SexualActivityView> {
  late DateTime weekDayOne;
  late DateTime lastWeekDayOne;
  late DateTime today;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    today = DateTime(now.year, now.month, now.day);
    weekDayOne = getThisWeekMonday();
    lastWeekDayOne = weekDayOne.subtract(const Duration(days: 7));
    if (!f.kIsWeb && Platform.isIOS) doSync();
  }

  doSync() async {
    await ref.read(bluesDbProvider.future);
    await _requestAuthorizationAndFetch((d) async {
      final healthKitMiss = await ref.read(bluesDbProvider.notifier).sync(d);
      if (healthKitMiss.isNotEmpty) {
        debugPrint('kit missed: ${healthKitMiss.length}');
        for (var e in healthKitMiss) {
          _addSexualActivity(
              DateTime.fromMillisecondsSinceEpoch(e.time * 1000), e.protected);
        }
      }
    });
  }

  Future<String> _requestAuthorizationAndFetch(
      Future Function(List<Category>)? callback) async {
    try {
      final readTypes = <String>[CategoryType.sexualActivity.identifier];
      final writeTypes = <String>[CategoryType.sexualActivity.identifier];
      final isRequested =
          await HealthKitReporter.requestAuthorization(readTypes, writeTypes);
      if (isRequested) {
        final now = DateTime.now();
        final threeMonthsAgo = now.subtract(const Duration(days: 90));
        final activities = await HealthKitReporter.categoryQuery(
            CategoryType.sexualActivity, Predicate(threeMonthsAgo, now));
        // showSimpleMessage(context,
        //     content: activities
        //         .map((a) {
        //           final m = jsonEncode(a.map);
        //           final used = a.harmonized.metadata?["double"]?["dictionary"]
        //               ?["HKSexualActivityProtectionUsed"];
        //           final test = a.map["HKSexualActivityProtectionUsed"];
        //           final dt = DateTime.fromMillisecondsSinceEpoch(
        //               a.startTimestamp * 1000 as int);
        //           return "$dt: $used ${used.runtimeType}, $test ${test.runtimeType}, ${prettyPrintJson(m)}\n";
        //         })
        //         .toList()
        //         .toString());
        if (callback != null) {
          await callback(activities);
        }
        return "Done";
      } else {
        return "Authorization not requested";
      }
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
    }
    return "Error";
  }

  Future<void> _addSexualActivity(DateTime dateTime, bool? protected) async {
    if (f.kIsWeb || !Platform.isIOS) return;
    try {
      final canWrite = await HealthKitReporter.isAuthorizedToWrite(
          CategoryType.sexualActivity.identifier);
      if (canWrite) {
        const _source = Source('CyberMe', 'com.mazhangjing.cyberme');
        const _operatingSystem = OperatingSystem(1, 2, 3);
        const _sourceRevision =
            SourceRevision(_source, null, null, "1.0", _operatingSystem);
        final harmonized = CategoryHarmonized(
            0, "", "", {"HKSexualActivityProtectionUsed": protected});
        final data = Category(
            const Uuid().v4(),
            CategoryType.sexualActivity.identifier,
            dateTime.millisecondsSinceEpoch,
            dateTime.millisecondsSinceEpoch,
            null,
            _sourceRevision,
            harmonized);
        debugPrint('try to save: ${data.map}');
        final saved = await HealthKitReporter.save(data);
        debugPrint('data saved: $saved');
      } else {
        debugPrint('error canWrite steps: $canWrite');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  DateTime ts2DateTime(num ts) {
    return DateTime.fromMillisecondsSinceEpoch(ts * 1000 as int);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(bluesDbProvider).value ?? [];
    return Scaffold(
        appBar: AppBar(title: const Text('Sexual Activity'), actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog),
          IconButton(
              icon: const Icon(Icons.calendar_month, size: 19),
              onPressed: _showDialog),
          const SizedBox(width: 10)
        ]),
        body: buildList(data));
  }

  ListView buildList(List<BlueData> data) {
    return ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          final activity = data[index];
          return Dismissible(
              key: ValueKey(activity.time),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.endToStart) {
                  if (await showSimpleMessage(context, content: "确定删除此纪录吗?")) {
                    await ref
                        .read(bluesDbProvider.notifier)
                        .delete(activity.time);
                    if (Platform.isIOS) {
                      await HealthKitReporter.deleteObjects(
                          CategoryType.sexualActivity.identifier,
                          Predicate(ts2DateTime(activity.time),
                              ts2DateTime(activity.time + 1)));
                    }
                    return true;
                  }
                } else {
                  await _edit(activity);
                  return false;
                }
                return false;
              },
              secondaryBackground: Container(
                  color: Colors.red,
                  child: const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                          padding: EdgeInsets.only(right: 20),
                          child: Text("删除",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 15))))),
              background: Container(
                  color: Colors.blue,
                  child: const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: Text("编辑",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 15))))),
              child: ListTile(
                  title: buildRichDate(ts2DateTime(activity.time),
                      today: today,
                      weekDayOne: weekDayOne,
                      lastWeekDayOne: lastWeekDayOne),
                  onTap: () => showSimpleMessage(context,
                      content: activity.note.isEmpty ? "无备注" : activity.note),
                  onLongPress: () => _edit(activity),
                  subtitle: Text(activity.note.isEmpty ? "--" : activity.note,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  leading: Icon(
                      activity.protected == null
                          ? Icons.handshake
                          : activity.protected == true
                              ? Icons.shield
                              : Icons.warning,
                      color: activity.protected == null
                          ? Colors.orange
                          : activity.protected == true
                              ? Colors.green
                              : Colors.red,
                      size: 30),
                  trailing: Text(DateFormat('HH:mm').format(
                      DateTime.fromMillisecondsSinceEpoch(
                          activity.time * 1000)))));
        });
  }

  Future<void> _edit(BlueData data) async {
    final noteController = TextEditingController(text: data.note);
    var useProtected = data.protected;
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                      title: const Text('Edit Sexual Activity'),
                      content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 10),
                            Row(children: [
                              const Text("Protected"),
                              const SizedBox(width: 5),
                              IgnorePointer(
                                  child: Checkbox(
                                      tristate: true,
                                      value: useProtected,
                                      onChanged: (value) {
                                        setState(() {
                                          useProtected = value;
                                        });
                                      }))
                            ]),
                            const SizedBox(height: 10),
                            TextField(
                                autofocus: true,
                                controller: noteController,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                decoration:
                                    const InputDecoration(labelText: 'Note'))
                          ]),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(null),
                            child: const Text("取消")),
                        TextButton(
                            onPressed: () async {
                              await ref.read(bluesDbProvider.notifier).edit(
                                  data.copyWith(
                                      note: noteController.text,
                                      protected: useProtected));
                              Navigator.of(context).pop(null);
                            },
                            child: const Text("确定"))
                      ]));
        });
  }

  void _showDialog() {
    // Navigator.of(context).push(MaterialPageRoute(
    //     builder: (context) => Scaffold(
    //         appBar: AppBar(title: const Text("View")),
    //         body: const BlueCalView())));
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => SizedBox(
            height: MediaQuery.of(context).size.height / 1.3,
            child: const BlueCalView()));
  }

  void _showAddDialog() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final noteController = TextEditingController();
    var dateTime =
        DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 0);
    bool? useProtected;

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                      title: const Text('Add Sexual Activity'),
                      content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                                child: Text(DateFormat('yyyy-MM-dd HH:mm')
                                    .format(dateTime)),
                                onPressed: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: dateTime,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    final TimeOfDay? timePicked =
                                        await showTimePicker(
                                            context: context,
                                            initialTime: TimeOfDay.fromDateTime(
                                                dateTime));
                                    if (timePicked != null) {
                                      setState(() {
                                        dateTime = DateTime(
                                            picked.year,
                                            picked.month,
                                            picked.day,
                                            timePicked.hour,
                                            timePicked.minute);
                                      });
                                    }
                                  }
                                }),
                            const SizedBox(height: 10),
                            Row(children: [
                              const Text("Protected"),
                              const SizedBox(width: 5),
                              Checkbox(
                                  tristate: true,
                                  value: useProtected,
                                  onChanged: (value) {
                                    setState(() {
                                      useProtected = value;
                                    });
                                  })
                            ]),
                            TextField(
                                controller: noteController,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                decoration:
                                    const InputDecoration(labelText: 'Note'))
                          ]),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(null),
                            child: const Text("取消")),
                        TextButton(
                            onPressed: () async {
                              await ref.read(bluesDbProvider.notifier).add(
                                  BlueData(
                                      time: dateTime.millisecondsSinceEpoch ~/
                                          1000,
                                      note: noteController.text,
                                      protected: useProtected));
                              _addSexualActivity(dateTime, useProtected);
                              Navigator.of(context).pop(null);
                            },
                            child: const Text("确定"))
                      ]));
        });
  }
}

class BlueCalView extends ConsumerStatefulWidget {
  const BlueCalView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BlueCalViewState();
}

class _BlueCalViewState extends ConsumerState<BlueCalView> {
  DateTime now = DateTime.now();
  Map<String, BlueData> _map = {};
  @override
  void initState() {
    super.initState();
    ref.read(bluesDbProvider.future).then((v) {
      final r = v.map((d) => MapEntry(
          DateFormat.yMd()
              .format(DateTime.fromMillisecondsSinceEpoch(d.time * 1000)),
          d));
      _map = Map.fromEntries(r);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(left: 8, right: 8, top: 10),
        child: TableCalendar(
            daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle:
                    TextStyle(color: appThemeData.colorScheme.onSurface)),
            locale: 'zh_CN',
            firstDay: now.subtract(const Duration(days: 30)),
            lastDay: now.add(const Duration(days: 30)),
            focusedDay: now,
            calendarFormat: CalendarFormat.month,
            headerVisible: true,
            daysOfWeekHeight: 22,
            startingDayOfWeek: StartingDayOfWeek.monday,
            selectedDayPredicate: (d) => d == now,
            headerStyle: const HeaderStyle(
                titleCentered: true, formatButtonVisible: false),
            calendarBuilders:
                CalendarBuilders(markerBuilder: (context, date, events) {
              if (!_map.containsKey(DateFormat.yMd().format(date))) return null;
              return Icon(Icons.stacked_line_chart_sharp,
                  size: 50, color: Colors.redAccent.withOpacity(0.2));
            })));
  }
}
