import 'package:cyberme_flutter/api/notes.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class BlueView extends ConsumerStatefulWidget {
  const BlueView({super.key});

  @override
  ConsumerState<BlueView> createState() => _BlueViewState();
}

class _BlueViewState extends ConsumerState<BlueView> {
  late DateTime dayMon;
  late DateTime now;
  late DateTime daySun;

  @override
  void initState() {
    super.initState();
    now = DateTime.now();
    dayMon = now
        .subtract(Duration(days: now.weekday - 1))
        .subtract(const Duration(days: 7));
    daySun = dayMon.add(const Duration(days: 14));
  }

  @override
  Widget build(BuildContext context) {
    final rangeData =
        ref.watch(blueDataRangeProvider(dayMon, daySun)).value ?? {};
    final data = ref.watch(blueDataProvider(now)).value;
    return Scaffold(
        appBar: AppBar(
          title: const Text('BLUE BLUE...'),
          actions: [
            IconButton(onPressed: handleAddBlue, icon: const Icon(Icons.add))
          ],
        ),
        body: Center(
            child: Column(children: [
          TableCalendar(
              locale: 'zh_CN',
              firstDay: dayMon,
              lastDay: daySun,
              focusedDay: now,
              calendarFormat: CalendarFormat.week,
              headerVisible: true,
              daysOfWeekHeight: 22,
              startingDayOfWeek: StartingDayOfWeek.monday,
              selectedDayPredicate: (d) => d == now,
              onDaySelected: (s, f) => setState(() => now = s),
              headerStyle: const HeaderStyle(
                  titleCentered: true, formatButtonVisible: false),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  return rangeData.contains(DateFormat.yMd().format(date))
                      ? Icon(Icons.stacked_line_chart_sharp,
                          size: 50, color: Colors.redAccent.withOpacity(0.2))
                      : null;
                },
              )),
          const Divider(color: Colors.grey, thickness: 0.2),
          data == null
              ? Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text("${now.day} 号暂无记录"),
                )
              : buildCard(data)
        ])));
  }

  Widget buildCard(DateTime data) {
    return Stack(children: [
      Image.asset("images/blue.png", fit: BoxFit.cover),
      Positioned(
          left: 20,
          top: 10,
          child: Text(DateFormat("HH:mm").format(data),
              style: const TextStyle(fontSize: 30))),
      Positioned(
          right: 2,
          bottom: 2,
          child: TextButton(
            onPressed: () {
              removeBlueData(now);
              makeInvalid();
            },
            child: const Text("删除"),
          ))
    ]);
  }

  void handleAddBlue() async {
    final data =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (data != null) {
      await setBlueData(
          now.add(Duration(hours: data.hour, minutes: data.minute)));
      makeInvalid();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("已添加 ${now.day} 号数据")));
    }
  }

  void makeInvalid() {
    ref.invalidate(blueDataProvider(now));
    ref.invalidate(blueDataRangeProvider(dayMon, daySun));
  }
}
