import 'dart:math';

import 'package:cyberme_flutter/pocket/viewmodels/work.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../main.dart';

class WorkView extends ConsumerStatefulWidget {
  const WorkView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _WorkViewState();
}

class _WorkViewState extends ConsumerState<WorkView> {
  DateTime now = DateTime.now();
  var _allSummary = false;
  final df = DateFormat('yyyy-MM-dd');
  DateTime _selectedDay = DateTime.now();
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(getWorkItemsProvider.call(_allSummary)).value ?? {};
    final body = Transform.translate(
      offset: const Offset(0, -8),
      child: Padding(
          padding: const EdgeInsets.only(left: 8, right: 8, top: 0),
          child: Column(children: [
            TableCalendar(
                daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle:
                        TextStyle(color: appThemeData.colorScheme.onPrimary)),
                locale: 'zh_CN',
                firstDay: now.subtract(const Duration(days: 300)),
                lastDay: now.add(const Duration(days: 30)),
                focusedDay: _selectedDay,
                calendarFormat: CalendarFormat.month,
                headerVisible: true,
                daysOfWeekHeight: 22,
                startingDayOfWeek: StartingDayOfWeek.monday,
                selectedDayPredicate: (d) => d == _selectedDay,
                onDaySelected: (pre, day) {
                  setState(() {
                    _selectedDay = day;
                  });
                },
                headerStyle: const HeaderStyle(
                    titleCentered: true, formatButtonVisible: false),
                calendarBuilders:
                    CalendarBuilders(markerBuilder: (context, date, events) {
                  final key = df.format(date);
                  final item = data[key] ?? WorkItem();
                  if (item.date.isEmpty) return null;
                  final opacity = item.workHour / 10;
                  return Container(
                      padding: const EdgeInsets.only(right: 5, left: 5),
                      color: Colors.pink.withOpacity(max(0, min(opacity, 1))),
                      child: Text(
                          !item.workDay
                              ? "休"
                              : item.workHour > 8
                                  ? "班*"
                                  : "班",
                          style: TextStyle(
                              fontSize: 10,
                              color: !item.workDay
                                  ? Colors.black
                                  : opacity > 0.5
                                      ? Colors.white
                                      : Colors.black.withOpacity(
                                          max(0, min(4 * opacity, 1))))));
                })),
            Padding(
                padding: const EdgeInsets.only(top: 10),
                child: buildDetail(data))
          ])),
    );
    return Scaffold(
        appBar: AppBar(title: const Text('工作日历'), actions: [
          TextButton.icon(
              label: Text(_allSummary ? "全部" : "本月"),
              icon: Icon(
                  _allSummary ? Icons.calendar_month : Icons.calendar_today),
              onPressed: () {
                setState(() {
                  _allSummary = !_allSummary;
                });
              }),
          IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () {
                launchUrlString("https://cyber.mazhangjing.com/work-at-inspur");
              }),
          const SizedBox(width: 3)
        ]),
        body: data.isEmpty
            ? const Center(
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 10),
                Text("正在加载")
              ]))
            : body);
  }

  Widget buildDetail(data) {
    final item = data[df.format(_selectedDay)] as WorkItem?;
    if (item == null) return const Text("未打卡");
    final card1 =
        item.checkStart?.time.toString().split('T').last.substring(0, 5);
    var card2 = item.checkEnd?.time.toString().split('T').last.substring(0, 5);
    if (card2 == card1) card2 = null;
    final workHours = Row(children: [
      if (card1 != null)
        Container(
          child: Text(card1, style: const TextStyle(color: Colors.white)),
          decoration: BoxDecoration(
            color: Colors.pink,
            borderRadius: BorderRadius.circular(5),
          ),
          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 1),
        ),
      const SizedBox(width: 4),
      if (card2 != null)
        Container(
          child: Text(card2, style: const TextStyle(color: Colors.white)),
          decoration: BoxDecoration(
            color: Colors.pink,
            borderRadius: BorderRadius.circular(5),
          ),
          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 1),
        )
    ]);
    final today = df.parse(item.date);
    final weekOne = today.subtract(Duration(days: today.weekday - 1));
    var summary = 0.0;
    for (int i = 0; i < 7; i++) {
      final d = df.format(weekOne.add(Duration(days: i)));
      summary += (data[d] as WorkItem?)?.workHour ?? 0;
    }
    return Card(
        elevation: 10,
        child: Padding(
            padding:
                const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
            child: SizedBox(
                width: double.infinity,
                child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(df.format(_selectedDay),
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: "Consolas")),
                          workHours
                        ],
                      ),
                      const Divider(thickness: 0.2),
                      item.workDay
                          ? Text("工作时长：${item.workHour} 小时")
                          : const Text("休息日"),
                      Text("本周累计：${summary.toStringAsFixed(1)} 小时"),
                      const SizedBox(height: 2),
                      const SizedBox(height: 5),
                    ]))));
  }
}
