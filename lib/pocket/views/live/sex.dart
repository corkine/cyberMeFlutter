import 'dart:io';

import 'package:cyberme_flutter/pocket/viewmodels/sex.dart';
import 'package:cyberme_flutter/pocket/views/util.dart';
import 'package:flutter/foundation.dart' as f;
import 'package:flutter/material.dart';
import 'package:health_kit_reporter/health_kit_reporter.dart';
import 'package:health_kit_reporter/model/predicate.dart';
import 'package:health_kit_reporter/model/type/category_type.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../main.dart';
import 'health.dart';

Icon buildIcon(BlueData activity, {double opacity = 1}) {
  return Icon(
      activity.protected == null
          ? Icons.handshake
          : activity.protected == true
              ? Icons.shield
              : Icons.warning,
      color: (activity.protected == null
              ? Colors.orange
              : activity.protected == true
                  ? Colors.green
                  : Colors.red)
          .withOpacity(opacity),
      size: 30);
}

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
    doSync();
  }

  doSync() async {
    if (f.kIsWeb || !Platform.isIOS) return;
    await ref.read(bluesDbProvider.future);
    final ok = await requestAuthorization(
        readTypes: [CategoryType.sexualActivity.identifier],
        writeTypes: [CategoryType.sexualActivity.identifier]);
    if (ok.$1) {
      final now = DateTime.now();
      final threeMonthsAgo = now.subtract(const Duration(days: 90));
      final activities = await HealthKitReporter.categoryQuery(
          CategoryType.sexualActivity, Predicate(threeMonthsAgo, now));
      final healthKitMiss =
          await ref.read(bluesDbProvider.notifier).sync(activities);
      if (healthKitMiss.isNotEmpty) {
        debugPrint('kit missed: ${healthKitMiss.length}');
        for (var e in healthKitMiss) {
          addSexualActivity(
              DateTime.fromMillisecondsSinceEpoch((e.time * 1000).toInt()),
              e.protected);
        }
      }
    } else {
      await showSimpleMessage(context, content: ok.$2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(bluesDbProvider).value ?? [];
    return Scaffold(
        floatingActionButton: FloatingActionButton(
            onPressed: _showAddDialog, child: const Icon(Icons.add)),
        backgroundColor: Colors.white,
        body: CustomScrollView(slivers: [
          SliverAppBar(
              expandedHeight: 250,
              flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  title: const Text("Sexual Activity",
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(blurRadius: 10, color: Colors.black54)
                          ],
                          color: Colors.white,
                          fontFamily: "Sank")),
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 10),
                  background: Image.network(
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      "https://static2.mazhangjing.com/cyber/202408/d510fe8e_Snipaste_2024-08-06_17-07-00.jpg")),
              actions: [
                IconButton(
                    icon: const Icon(Icons.calendar_month, size: 19),
                    onPressed: _showCalDialog),
                const SizedBox(width: 10)
              ]),
          buildList(data)
        ]));
  }

  SliverList buildList(List<BlueData> data) {
    return SliverList.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          final activity = data[index];
          return Dismissible(
              key: ValueKey(activity.time),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.endToStart) {
                  if (await showSimpleMessage(context, content: "确定删除此记录吗?")) {
                    await ref
                        .read(bluesDbProvider.notifier)
                        .delete(activity.time);
                    await deleteSample(CategoryType.sexualActivity.identifier,
                        activity.time.toDouble());
                    return true;
                  }
                } else {
                  await _showEditDialog(activity);
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
                  onTap: () => _showEditDialog(activity),
                  subtitle: Text(activity.note.isEmpty ? "--" : activity.note,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  leading: buildIcon(activity),
                  trailing: Text(
                      DateFormat('HH:mm').format(
                          DateTime.fromMillisecondsSinceEpoch(
                              (activity.time * 1000).toInt())),
                      style: const TextStyle(
                          fontFamily: 'Sank',
                          fontWeight: FontWeight.bold,
                          fontSize: 18))));
        });
  }

  void _showCalDialog() {
    showAdaptiveBottomSheet(
        context: context, child: const BlueCalView(), divideHeight: 1.3);
  }

  Future<void> _showEditDialog(BlueData data) async {
    await showAdaptiveBottomSheet<BlueData>(
        context: context, child: SexualActivityEditView(data, false));
  }

  void _showAddDialog() async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    var dateTime =
        DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 0);
    await showAdaptiveBottomSheet<BlueData>(
        context: context,
        child: SexualActivityEditView(
            BlueData(time: dateTime.millisecondsSinceEpoch / 1000, note: ""),
            true));
  }
}

class SexualActivityEditView extends ConsumerStatefulWidget {
  final BlueData data;
  final bool isAdd;
  const SexualActivityEditView(this.data, this.isAdd, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SexualActivityEditViewState();
}

class _SexualActivityEditViewState
    extends ConsumerState<SexualActivityEditView> {
  late final BlueData data = widget.data;
  late final noteController = TextEditingController(text: data.note);
  late var useProtected = data.protected;
  late var dateTime =
      DateTime.fromMillisecondsSinceEpoch((data.time * 1000).toInt());

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(
            left: 20, right: 20, top: 20, bottom: Platform.isWindows ? 10 : 0),
        child: SafeArea(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              Row(children: [
                const Text("日期"),
                TextButton(
                    child:
                        Text(DateFormat('yyyy-MM-dd HH:mm').format(dateTime)),
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: dateTime,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        final TimeOfDay? timePicked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(dateTime));
                        if (timePicked != null) {
                          setState(() {
                            dateTime = DateTime(picked.year, picked.month,
                                picked.day, timePicked.hour, timePicked.minute);
                          });
                        }
                      }
                    })
              ]),
              Row(children: [
                const Text("保护"),
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
                  onTapOutside: (e) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(labelText: '备注')),
              const Spacer(),
              SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                      onPressed: () async {
                        if (widget.isAdd) {
                          addSexualActivity(dateTime, useProtected);
                          await ref.read(bluesDbProvider.notifier).add(
                              data.copyWith(
                                  note: noteController.text,
                                  protected: useProtected));
                        } else {
                          await ref.read(bluesDbProvider.notifier).edit(
                              data.copyWith(
                                  note: noteController.text,
                                  protected: useProtected));
                        }
                        Navigator.of(context).pop();
                      },
                      child: Text(widget.isAdd ? "添加" : "更新")))
            ])));
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
          DateFormat.yMd().format(
              DateTime.fromMillisecondsSinceEpoch((d.time * 1000).toInt())),
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
              final dateFmt = DateFormat.yMd().format(date);
              if (!_map.containsKey(dateFmt)) return null;
              return Center(child: buildIcon(_map[dateFmt]!, opacity: 0.6));
            })));
  }
}
