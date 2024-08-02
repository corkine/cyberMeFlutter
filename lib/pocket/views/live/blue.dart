import 'package:cyberme_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../viewmodels/blue.dart';

class ScoreView extends ConsumerStatefulWidget {
  const ScoreView({super.key});

  @override
  ConsumerState<ScoreView> createState() => _BlueViewState();
}

class _BlueViewState extends ConsumerState<ScoreView> {
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
    final rangeData = ref.watch(bluesProvider).value ?? {};
    final todayData = rangeData[DateFormat.yMd().format(now)];
    return Theme(
      data: appThemeData,
      child: Scaffold(
          appBar: AppBar(
              title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BLUE BLUE...', style: TextStyle(fontSize: 16)),
                    Text(DateFormat("yyyy年MM月").format(now),
                        style: const TextStyle(fontSize: 12))
                  ]),
              actions: [
                IconButton(
                    onPressed: handleAddBlue, icon: const Icon(Icons.add))
              ]),
          body: Center(
              child: Column(children: [
            TableCalendar(
                daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle:
                        TextStyle(color: appThemeData.colorScheme.onSurface)),
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
                calendarBuilders:
                    CalendarBuilders(markerBuilder: (context, date, events) {
                  return rangeData[DateFormat.yMd().format(date)] != null
                      ? Icon(Icons.stacked_line_chart_sharp,
                          size: 50, color: Colors.redAccent.withOpacity(0.2))
                      : null;
                })),
            const SizedBox(height: 5),
            todayData == null && false
                // ignore: dead_code
                ? Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text("${now.day} 号暂无记录"),
                  )
                : Expanded(child: buildCard(fakeData))
          ]))),
    );
  }

  Widget buildCard(List<BlueData> data) {
    return ListView.builder(
        itemCount: data.length,
        itemBuilder: (ctx, i) {
          final item = data[i];
          return GestureDetector(
              onTap: () => showDialog(
                  context: context,
                  builder: (context) => Theme(
                      data: appThemeData,
                      child: SimpleDialog(title: Text(item.title), children: [
                        SimpleDialogOption(
                            onPressed: () {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(item.toString())));
                            },
                            child: const Text("查看详情")),
                        SimpleDialogOption(
                            onPressed: () {
                              Navigator.of(context).pop();
                              handleDeleteItem(item.timestamp);
                            },
                            child: const Text("删除"))
                      ]))),
              child: BlueCard(data: item));
        });
  }

  void handleAddBlue() async {
    final name = TextEditingController();
    final desc = TextEditingController();
    final point = TextEditingController();
    final preNames = [("", 0), ("BLUE", -3), ("不吃零食", 4), ("多吃蔬菜水果", 3)];
    final ok = await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(builder: ((context, setState) {
              return Theme(
                  data: appThemeData,
                  child: AlertDialog(
                      title: const Text("添加记录"),
                      content:
                          Column(mainAxisSize: MainAxisSize.min, children: [
                        TextField(
                            controller: name,
                            autofocus: true,
                            decoration: const InputDecoration(
                                labelText: "名称*",
                                border: UnderlineInputBorder())),
                        TextField(
                            controller: point,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: "分数*",
                                border: UnderlineInputBorder())),
                        TextField(
                            controller: desc,
                            decoration: const InputDecoration(
                                labelText: "描述",
                                border: UnderlineInputBorder())),
                        const SizedBox(height: 20),
                        DropdownButton(
                            value: preNames.first,
                            focusColor: Colors.transparent,
                            isDense: true,
                            isExpanded: true,
                            items: preNames
                                .map((e) => DropdownMenuItem(
                                    child: Text(e.$1.isEmpty ? "使用预选项" : e.$1),
                                    value: e))
                                .toList(growable: false),
                            onChanged: (v) {
                              name.text = v!.$1;
                              point.text = v.$2.toString();
                            })
                      ]),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("取消")),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("确定"))
                      ]));
            })));
    if (ok != null) {
      fakeData.add(BlueData(
          title: name.text,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          note: desc.text.isEmpty ? null : desc.text,
          point: int.parse(point.text)));
      setState(() {});
    }
  }

  void handleDeleteItem(int timestamp) {
    fakeData.removeWhere((element) => element.timestamp == timestamp);
    setState(() {});
  }

  final fakeData = [
    const BlueData(
        title: "BLUE",
        timestamp: 1703210818929,
        point: 3,
        note: "REASON REASON"),
    const BlueData(
        title: "BLUE",
        timestamp: 1703210818939,
        point: -5,
        note: "REASON REASON"),
    const BlueData(
        title: "BLUE",
        timestamp: 1703210818959,
        point: 3,
        note: "REASON REASON"),
    const BlueData(
        title: "BLUE",
        timestamp: 1703210818969,
        point: -5,
        note: "REASON REASON"),
  ];
}

class BlueCard extends StatelessWidget {
  final BlueData data;
  const BlueCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateTime.fromMillisecondsSinceEpoch(data.timestamp);
    final formatedTime = DateFormat("HH:mm").format(time);
    const vertial = 3.0;
    const leftM = 10.0;
    const leftP = 20.0;
    final bgColor = data.point < 0
        ? const Color.fromARGB(255, 204, 55, 55)
        : const Color.fromARGB(255, 0, 157, 120);
    return DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: Column(children: [
          Stack(children: [
            Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: leftM, vertical: vertial),
                padding: const EdgeInsets.only(
                    left: leftP, right: leftP, top: 5, bottom: 10),
                decoration: BoxDecoration(
                    color: bgColor, borderRadius: BorderRadius.circular(15)),
                child: Row(children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20)),
                        Text(data.note ?? "",
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            style: const TextStyle(
                                fontWeight: FontWeight.normal, fontSize: 12))
                      ]),
                  const Spacer(),
                  Transform.scale(
                      scale: 1.5,
                      child: Transform.translate(
                          offset: const Offset(10, -10),
                          child: Text(
                              data.point > 0
                                  ? "+${data.point}"
                                  : "-${data.point * -1}",
                              style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: "consolas",
                                  foreground: Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = 0.5
                                    ..color = Colors.white.withOpacity(0.7)))))
                ])),
            Positioned(
                bottom: vertial,
                right: leftM + leftP,
                child: Container(
                    color: Colors.black26,
                    child: Text(formatedTime,
                        style: const TextStyle(fontSize: 12)),
                    padding: const EdgeInsets.only(left: 6, right: 6)))
          ])
        ]));
  }
}
