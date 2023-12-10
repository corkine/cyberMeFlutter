import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../api/blue.dart';

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
            title: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('BLUE BLUE...', style: TextStyle(fontSize: 16)),
                  Text(DateFormat("yyyy年MM月").format(now),
                      style: const TextStyle(fontSize: 12))
                ]),
            actions: [
              IconButton(
                  onPressed: () => handleAddBlue(data),
                  icon: const Icon(Icons.add))
            ]),
        body: Center(
            child: Column(children: [
          TableCalendar(
              locale: 'zh_CN',
              firstDay: dayMon,
              lastDay: daySun,
              focusedDay: now,
              calendarFormat: CalendarFormat.week,
              headerVisible: false,
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
          const SizedBox(height: 5),
          data == null
              ? Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text("${now.day} 号暂无记录"),
                )
              : buildCard(data)
        ])));
  }

  Widget buildCard(BlueData data) {
    final date = data.date!;
    final hour = data.watchSeconds ~/ 3600;
    final minute = (data.watchSeconds % 3600) ~/ 60;
    return Stack(children: [
      Image.asset("images/blue.png", fit: BoxFit.cover),
      Positioned(
          left: 20,
          top: 10,
          child: Text(DateFormat("HH:mm").format(date),
              style: const TextStyle(fontSize: 30))),
      Positioned(
          bottom: 5,
          left: 5,
          right: 5,
          child: Container(
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(5)),
              child: ListTile(
                  title: const Text("抖音播放数据"),
                  subtitle: Text("播放时长：$hour小时$minute分钟")))),
      Positioned(
          right: 5,
          bottom: 8,
          child: TextButton(
              onPressed: () {
                removeBlueData(now);
                makeInvalid();
              },
              child: const Text("删除")))
    ]);
  }

  void handleAddBlue(BlueData? blueData) async {
    final data = await showTimePicker(
        context: context,
        initialTime: blueData == null
            ? TimeOfDay.now()
            : TimeOfDay.fromDateTime(blueData.date!));
    if (data == null) return;
    var minutes = TextEditingController(
        text: blueData == null ? "" : "${blueData.watchSeconds ~/ 60}");
    await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text("请输入播放时长"),
                content: TextField(
                  controller: minutes,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      hintText: "请输入播放时长(分钟)", border: UnderlineInputBorder()),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("取消")),
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("确定"))
                ]));
    if (data != null) {
      await setBlueData(
          now.add(Duration(hours: data.hour, minutes: data.minute)),
          int.parse(minutes.text));
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
