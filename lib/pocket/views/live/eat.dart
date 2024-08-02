import 'package:flutter/material.dart';

import '../../models/eatItem.dart';

class EatView extends StatefulWidget {
  const EatView({super.key});

  @override
  State<EatView> createState() => _EatViewState();
}

class _EatViewState extends State<EatView> {
  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(children: [
      Positioned(
          right: -110,
          top: -30,
          child: TapRegion(
            onTapInside: (_) => Navigator.of(context).pop(),
            child: Text("${totalToday.toStringAsFixed(0)}Kcal",
                style: const TextStyle(
                    fontFamily: "Arial",
                    fontSize: 110,
                    color: Colors.black12,
                    fontWeight: FontWeight.bold)),
          )),
      Positioned(
        top: 40,
        bottom: 30,
        left: 0,
        right: 0,
        child: SingleChildScrollView(
          child: Column(
            children: items
                .map((e) => ListTile(
                      title: Text(e.name ?? ""),
                      trailing:
                          Text((e.calories ?? -1).toStringAsFixed(1) + " kcal"),
                    ))
                .toList(growable: false),
          ),
        ),
      ),
      Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
              child: ButtonBar(alignment: MainAxisAlignment.center, children: [
            TextButton(onPressed: () {}, child: const Text("添加")),
            TextButton(onPressed: () {}, child: const Text("本周统计"))
          ])))
    ]));
  }

  double totalToday = 0.0;
  List<EatItem> morning = [];
  List<EatItem> noon = [];
  List<EatItem> night = [];

  Future fetchItems() async {
    totalToday = 0.0;
    for (final i in items) {
      totalToday += (i.calories ?? 0.0);
      if (i.dateTime!.hour < 12) {
        morning.add(i);
      } else if (i.dateTime!.hour < 19) {
        noon.add(i);
      } else {
        night.add(i);
      }
    }
    setState(() {});
  }

  List<EatItem> items = [
    EatItem(
        id: "1",
        date: "2023-04-03 12:23:13",
        calories: 112.3,
        name: "鸡蛋",
        note: "没有笔记",
        image: "https://static2.mazhangjing.com/img1",
        tag: []),
    EatItem(
        id: "12",
        date: "2023-04-03 12:23:13",
        calories: 112.3,
        name: "鸡蛋2",
        note: "没有笔记",
        image: "https://static2.mazhangjing.com/img1",
        tag: []),
    EatItem(
        id: "13",
        date: "2023-04-03 12:23:13",
        calories: 112.3,
        name: "鸡蛋3",
        note: "没有笔记",
        image: "https://static2.mazhangjing.com/img1",
        tag: []),
    EatItem(
        id: "14",
        date: "2023-04-03 12:23:13",
        calories: 112.3,
        name: "鸡蛋4",
        note: "没有笔记",
        image: "https://static2.mazhangjing.com/img1",
        tag: []),
    EatItem(
        id: "15",
        date: "2023-04-03 12:23:13",
        calories: 112.3,
        name: "鸡蛋5",
        note: "没有笔记",
        image: "https://static2.mazhangjing.com/img1",
        tag: []),
    EatItem(
        id: "16",
        date: "2023-04-03 12:23:13",
        calories: 112.3,
        name: "鸡蛋6",
        note: "没有笔记",
        image: "https://static2.mazhangjing.com/img1",
        tag: []),
    EatItem(
        id: "17",
        date: "2023-04-03 12:23:13",
        calories: 112.3,
        name: "鸡蛋7",
        note: "没有笔记",
        image: "https://static2.mazhangjing.com/img1",
        tag: []),
    EatItem(
        id: "18",
        date: "2023-04-03 12:23:13",
        calories: 112.3,
        name: "鸡蛋8",
        note: "没有笔记",
        image: "https://static2.mazhangjing.com/img1",
        tag: []),
    EatItem(
        id: "19",
        date: "2023-04-03 12:23:13",
        calories: 112.3,
        name: "鸡蛋9",
        note: "没有笔记",
        image: "https://static2.mazhangjing.com/img1",
        tag: []),
  ];
}
