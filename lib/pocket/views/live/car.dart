import 'dart:io';

import 'package:cyberme_flutter/main.dart';
import 'package:cyberme_flutter/pocket/viewmodels/car.dart';
import 'package:cyberme_flutter/pocket/views/util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../interface/channel.dart';

class CarView extends ConsumerStatefulWidget {
  const CarView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CarViewState();
}

class _CarViewState extends ConsumerState<CarView> {
  @override
  Widget build(BuildContext context) {
    final car = ref.watch(carDbProvider).value ?? const CarInfo();
    final width = MediaQuery.maybeSizeOf(context)!.width;
    return Theme(
        data: appThemeData,
        child: Scaffold(
            backgroundColor: Colors.black,
            body: RefreshIndicator(
                onRefresh: () async {
                  final res =
                      await ref.read(carDbProvider.notifier).forceUpdate();
                  NativePlatform.refreshWidget();
                  showSimpleMessage(context, content: res, useSnackBar: true);
                },
                child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.max, children: [
                  SizedBox(height: 250, child: buildLogo()),
                  Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      child: buildCards(car, width))
                ])))));
  }

  Column buildCards(CarInfo car, double width) {
    return Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Transform.translate(
                offset: const Offset(-5, -10),
                child: Text(car.status.range.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 45, height: 1))),
            const Text("km", style: TextStyle(fontSize: 20)),
            const Spacer(),
            Text(car.status.fuelLevel.toStringAsFixed(0)),
            const Text("% "),
            const Text("燃油")
          ])
              .animate(
                  delay: Platform.isWindows ? 100.milliseconds : 0.milliseconds)
              .flip(),
          Container(width: double.infinity, height: 3, color: Colors.white12),
          Transform.translate(
              offset: const Offset(0, -3),
              child: Animate(effects: [
                CustomEffect(
                    duration: 500.milliseconds,
                    builder: (context, value, child) {
                      return Container(
                          width: width * car.status.fuelLevel / 100 * value,
                          height: 3,
                          color: Colors.white70);
                    })
              ])),
          const SizedBox(height: 3),
          Text(
              car.reportTimeStr.isEmpty
                  ? ""
                  : car.reportTimeStr.substring(0, 16) + " 更新",
              style: const TextStyle(color: Colors.white30, fontSize: 13)),
          const SizedBox(height: 15),
          buildRow("状态", car.status.parkingBrake == "active" ? "已驻车" : "未驻车",
              "门锁", car.status.lock == "locked" ? "锁定" : "未锁"),
          const SizedBox(height: 10),
          buildRow("车门", car.status.doors == "closed" ? "已关闭" : "开启", "车窗",
              car.status.windows == "closed" ? "已关闭" : "开启"),
          const SizedBox(height: 10),
          buildRow("胎压", car.status.tyre == "checked" ? "正常" : "警告", "机油",
              car.status.oilLevel.toStringAsFixed(0) + "%"),
          const SizedBox(height: 10),
          buildRow("外温", car.status.outTemp.toStringAsFixed(1) + "°C", "车速",
              car.status.speed.toStringAsFixed(0) + " km/h"),
          const SizedBox(height: 10),
          Stack(children: [
            InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => launchUrlString(
                    "https://m.amap.com/picker/?center=${car.loc.longitude / 1000000.0},${car.loc.latitude / 1000000.0}&key=446020a2a489b6aa4c918d33910e0f73&jscode=6c70ad0803bcd70f0b7caa54b0c51278"),
                child: buildCard("当前位置", car.loc.place)),
            Positioned(
                right: 10,
                top: 10,
                bottom: 10,
                child: Transform.rotate(
                    angle: 0,
                    child: const Icon(Icons.place,
                        color: Color.fromARGB(75, 255, 45, 25), size: 50)))
          ]),
          const SizedBox(height: 10),
          buildRow("生涯油耗", car.tripStatus.fuel.toStringAsFixed(0) + "L", "生涯里程",
              car.tripStatus.mileage.toStringAsFixed(0) + " km"),
          const SizedBox(height: 10),
          buildRow(
              "平均油耗",
              car.tripStatus.averageFuel.toStringAsFixed(1) + "L/100km",
              "下次保养",
              car.status.inspection.toStringAsFixed(0) + " km"),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            CupertinoButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => TripListView(car.trip))),
                child: const Text("行程信息")),
            CupertinoButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => TripListView(car.tripCyclic))),
                child: const Text("按加油统计"))
          ]),
          const SizedBox(height: 100),
        ].animate().fadeIn(duration: 600.milliseconds));
  }

  Widget buildRow(
      String title1, String subtitle1, String title2, String subtitle2) {
    return Row(mainAxisSize: MainAxisSize.max, children: [
      Expanded(child: buildCard(title1, subtitle1)),
      const SizedBox(width: 10),
      Expanded(
          child: title2.isEmpty ? Container() : buildCard(title2, subtitle2))
    ]);
  }

  Widget buildCard(String title, String subtitle) {
    var subtitleColor = Colors.white38;
    if (subtitle.contains("未锁") ||
        subtitle.contains("开启") ||
        subtitle.contains("警告")) {
      subtitleColor = const Color.fromARGB(196, 255, 83, 71);
    }
    final content = Padding(
        padding: const EdgeInsets.only(left: 10, right: 8, top: 8, bottom: 8),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 20)),
              Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 5),
                  height: 2,
                  width: 60,
                  color: Colors.white.withOpacity(0.05)),
              Text(subtitle,
                  style: TextStyle(fontSize: 12, color: subtitleColor))
            ]));
    const radius = 10.0;
    if (subtitle.endsWith("%")) {
      final endValue =
          (double.tryParse(subtitle.replaceAll("%", "")) ?? 0.0) * 0.01 * 80;
      return Container(
          alignment: Alignment.topLeft,
          decoration: const BoxDecoration(
              color: Color(0xFF131924),
              borderRadius: BorderRadius.all(Radius.circular(radius))),
          height: 80,
          child: Stack(alignment: Alignment.bottomLeft, children: [
            Animate(effects: [
              CustomEffect(
                  builder: (context, value, child) {
                    return Container(
                        decoration: const BoxDecoration(
                            color: Color.fromARGB(255, 47, 62, 89),
                            borderRadius: BorderRadius.only(
                                topRight: Radius.circular(radius * 2),
                                bottomLeft: Radius.circular(radius),
                                bottomRight: Radius.circular(radius))),
                        height: endValue * value);
                  },
                  duration: 300.milliseconds,
                  delay: 0.1.seconds,
                  curve: Curves.easeIn),
            ]),
            content
          ]));
    }
    return Container(
        alignment: Alignment.topLeft,
        decoration: const BoxDecoration(
            color: Color(0xFF131924),
            borderRadius: BorderRadius.all(Radius.circular(10))),
        height: 80,
        child: content);
  }

  Stack buildLogo() {
    final vw = Positioned(
        left: -40,
        top: -40,
        child: Opacity(opacity: 0.1, child: Image.asset("images/vwa.png")));
    final car = Positioned(
        left: -40,
        top: -30,
        right: -160,
        child: Opacity(opacity: 0.8, child: Image.asset("images/car.png")));
    return Stack(fit: StackFit.passthrough, children: [
      vw
          .animate(
              delay: Platform.isWindows ? 500.milliseconds : 100.milliseconds)
          .fadeIn(),
      Platform.isWindows
          ? car
          : car
              .animate()
              .moveY(
                  begin: -5,
                  end: 0,
                  duration: 200.milliseconds,
                  curve: Curves.easeIn)
              .moveX(
                  begin: 10,
                  end: 0,
                  duration: 200.milliseconds,
                  curve: Curves.easeIn),
      Positioned(
          left: 10, top: Platform.isIOS ? 30 : 10, child: const BackButton())
    ]);
  }
}

class TripListView extends ConsumerStatefulWidget {
  final List<CarTripItem> items;
  const TripListView(this.items, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TripListViewState();
}

class _TripListViewState extends ConsumerState<TripListView> {
  late DateTime weekDayOne;
  late DateTime lastWeekDayOne;
  late DateTime today;
  late List<CarTripItem> items;

  @override
  void initState() {
    super.initState();
    items = widget.items.reversed.toList();
    final now = DateTime.now();
    today = DateTime(now.year, now.month, now.day);
    weekDayOne = getThisWeekMonday();
    lastWeekDayOne = weekDayOne.subtract(const Duration(days: 7));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
        data: appThemeData,
        child: Scaffold(
            appBar: AppBar(title: const Text("行程信息")),
            body: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final trip = items[index];
                  return ListTile(
                      dense: true,
                      title: Row(
                        children: [
                          Text(trip.mileage.toStringAsFixed(0) + " km"),
                          Container(
                              height: 10,
                              color: Colors.white54,
                              margin: const EdgeInsets.only(left: 5, right: 5),
                              width: 2),
                          Text(trip.traveltime.toStringAsFixed(0) + " min"),
                          Container(
                              height: 10,
                              color: Colors.white54,
                              margin: const EdgeInsets.only(left: 5, right: 5),
                              width: 2),
                          Text(trip.averageSpeed.toStringAsFixed(0) + "km/h"),
                        ],
                      ),
                      subtitle: buildRichDate(
                          DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z")
                              .parse(trip.timestamp)
                              .add(const Duration(hours: 8)),
                          dateFormat: "yyyy-MM-dd HH:mm",
                          today: today,
                          weekDayOne: weekDayOne,
                          lastWeekDayOne: lastWeekDayOne),
                      trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            buildFuleWidget(trip.averageFuelConsumption),
                            const Text("L/100km",
                                style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 8,
                                    fontFamily: "PingFangSC-Regular"))
                          ]));
                })));
  }

  buildFuleWidget(double value) {
    return Text((value / 10).toStringAsFixed(1),
        style: TextStyle(
            color: value > 120
                ? Colors.red
                : value > 90
                    ? Colors.orange
                    : Colors.green,
            fontSize: 14));
  }
}
