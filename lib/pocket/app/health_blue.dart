import 'dart:convert';
import 'dart:io';

import 'package:cyberme_flutter/api/health_blue.dart';
import 'package:cyberme_flutter/pocket/app/util.dart';
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
import 'package:json_pretty/json_pretty.dart';
import 'package:uuid/uuid.dart';

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
    weekDayOne = now.subtract(Duration(
        days: now.weekday - 1,
        hours: now.hour,
        minutes: now.minute,
        seconds: now.second,
        milliseconds: now.millisecond,
        microseconds: now.microsecond));
    lastWeekDayOne = weekDayOne.subtract(const Duration(days: 7));
    if (!f.kIsWeb && Platform.isIOS) doSync();
  }

  doSync() async {
    await ref.read(bluesDbProvider.future);
    await _requestAuthorizationAndFetch((d) async {
      final healthKitMiss = await ref
          .read(bluesDbProvider.notifier)
          .sync(d.map((e) => e.startTimestamp as int).toSet());
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
        final harmonized = CategoryHarmonized(0, "", "",
            {"HKMetadataKeySexualActivityProtectionUsed": protected});
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
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog)
        ]),
        body: ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final activity = data[index];
              return Dismissible(
                  key: ValueKey(activity.time),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      if (await showSimpleMessage(context,
                          content: "确定删除此纪录吗?")) {
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
                      color: Colors.green,
                      child: const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                              padding: EdgeInsets.only(left: 20),
                              child: Text("",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 15))))),
                  child: ListTile(
                      title: buildRichDate(ts2DateTime(activity.time),
                          today: today,
                          weekDayOne: weekDayOne,
                          lastWeekDayOne: lastWeekDayOne),
                      onTap: () => showSimpleMessage(context,
                          content:
                              activity.note.isEmpty ? "无备注" : activity.note),
                      onLongPress: () => _edit(activity),
                      subtitle: Text(
                          activity.note.isEmpty ? "--" : activity.note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
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
            }));
  }

  void _edit(BlueData data) {
    final noteController = TextEditingController(text: data.note);
    var useProtected = data.protected;
    showDialog(
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
