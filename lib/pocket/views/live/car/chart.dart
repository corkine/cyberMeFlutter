import 'dart:collection';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';

import '../../../viewmodels/car.dart';

class AppColors {
  static const Color primary = contentColorCyan;
  static const Color menuBackground = Color(0xFF090912);
  static const Color itemsBackground = Color(0xFF1B2339);
  static const Color pageBackground = Color(0xFF282E45);
  static const Color mainTextColor1 = Colors.white;
  static const Color mainTextColor2 = Colors.white70;
  static const Color mainTextColor3 = Colors.white38;
  static const Color mainGridLineColor = Colors.white10;
  static const Color borderColor = Colors.white54;
  static const Color gridLinesColor = Color(0x11FFFFFF);

  static const Color contentColorBlack = Colors.black;
  static const Color contentColorWhite = Colors.white;
  static const Color contentColorBlue = Color(0xFF2196F3);
  static const Color contentColorYellow = Color(0xFFFFC300);
  static const Color contentColorOrange = Color(0xFFFF683B);
  static const Color contentColorGreen = Color(0xFF3BFF49);
  static const Color contentColorPurple = Color(0xFF6E1BFF);
  static const Color contentColorPink = Color(0xFFFF3AF2);
  static const Color contentColorRed = Color(0xFFE80054);
  static const Color contentColorCyan = Color(0xFF50E4FF);
}

class WeeklyData {
  final DateTime startOfWeek;
  final int weekNumber;
  final List<dynamic> data;
  final double avgTripMinutes;
  final double avgFuelCost;
  final double avgTravelDistance;

  WeeklyData(this.startOfWeek, this.data, this.avgTripMinutes, this.avgFuelCost,
      this.avgTravelDistance, this.weekNumber);
}

class TripChart extends StatefulWidget {
  final List<CarTripItem> items;
  const TripChart({super.key, required this.items});

  @override
  State<TripChart> createState() => _TripChartState();
}

class _TripChartState extends State<TripChart> {
  late List<WeeklyData> data;
  double maxY = 0;
  double maxX = 0;

  final df = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z");

  List<Color> gradientColors = [
    AppColors.contentColorCyan,
    AppColors.contentColorBlue,
  ];

  bool showAvg = false;

  List<WeeklyData> groupDataByWeek(List<CarTripItem> data,
      {int weeksToKeep = 12}) {
    if (data.isEmpty) return [];

    DateTime latestDate =
        df.parse(data.last.timestamp).add(const Duration(hours: 8));

    DateTime cutoffDate = latestDate.subtract(Duration(days: 7 * weeksToKeep));

    Map<DateTime, List<CarTripItem>> groupedData =
        SplayTreeMap<DateTime, List<CarTripItem>>();

    for (var item in data) {
      DateTime itemDate =
          df.parse(item.timestamp).add(const Duration(hours: 8));
      if (itemDate.isBefore(cutoffDate)) continue;
      DateTime startOfWeek =
          itemDate.subtract(Duration(days: itemDate.weekday - 1));
      startOfWeek =
          DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      groupedData.putIfAbsent(startOfWeek, () => []).add(item);
    }

    final now = DateTime.now();

    List<WeeklyData> result = groupedData.entries.map((entry) {
      double time = 0;
      double fuel = 0;
      double distance = 0;
      for (var item in entry.value) {
        time += item.traveltime;
        fuel += item.averageFuelConsumption;
        distance += item.mileage;
      }
      double avgTime = ((time / entry.value.length) * 10).round() / 10;
      double avgFuel = ((fuel / entry.value.length / 10) * 10).round() / 10;
      double avgDistance = ((distance / entry.value.length) * 10).round() / 10;

      //计算距离 cutoffDate 的周数
      int weekNumber = now.difference(entry.key).inDays ~/ 7 + 1;

      return WeeklyData(
          entry.key, entry.value, avgTime, avgFuel, avgDistance, weekNumber);
    }).toList();

    return result.take(weeksToKeep).toList();
  }

  @override
  void initState() {
    super.initState();
    data = groupDataByWeek(widget.items, weeksToKeep: 12);
    maxY = data.map((e) => e.avgTravelDistance).reduce(max) * 1.1;
    maxX = 12 + 2;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      AspectRatio(
          aspectRatio: 1.70,
          child: Padding(
              padding: const EdgeInsets.only(
                  right: 20, left: 10, top: 10, bottom: 5),
              child: LineChart(
                showAvg ? avgData() : mainData(),
              ))),
      // SizedBox(
      //     width: 60,
      //     height: 24,
      //     child: TextButton(
      //         onPressed: () {
      //           setState(() {
      //             showAvg = !showAvg;
      //           });
      //         },
      //         child: Text('avg',
      //             style: TextStyle(
      //                 fontSize: 12,
      //                 color: showAvg
      //                     ? Colors.white.withOpacity(0.5)
      //                     : Colors.white))))
    ]);
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 12);
    Widget text;
    text = Text(value > 0 ? '${value.toInt()}' : '', style: style);
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: text,
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 10);

    return Text(value.toStringAsFixed(0),
        style: style, textAlign: TextAlign.right);
  }

  LineChartData mainData() {
    return LineChartData(
        gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            drawHorizontalLine: false,
            horizontalInterval: 1,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return const FlLine(
                  color: AppColors.mainGridLineColor, strokeWidth: 1);
            },
            getDrawingVerticalLine: (value) {
              return const FlLine(
                  color: AppColors.mainGridLineColor, strokeWidth: 1);
            }),
        titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: bottomTitleWidgets)),
            leftTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: leftTitleWidgets,
                    reservedSize: 20))),
        borderData: FlBorderData(
            show: false, border: Border.all(color: const Color(0xff37434d))),
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
              spots: data
                  .map((d) =>
                      FlSpot(d.weekNumber.toDouble(), d.avgTravelDistance))
                  .toList(),
              isCurved: true,
              gradient: LinearGradient(colors: gradientColors),
              barWidth: 1,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                      colors: gradientColors
                          .map((color) => color.withOpacity(0.3))
                          .toList())))
        ]);
  }

  LineChartData avgData() {
    return LineChartData(
        lineTouchData: const LineTouchData(enabled: false),
        gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            verticalInterval: 1,
            horizontalInterval: 1,
            getDrawingVerticalLine: (value) {
              return const FlLine(
                color: Color(0xff37434d),
                strokeWidth: 1,
              );
            },
            getDrawingHorizontalLine: (value) {
              return const FlLine(
                color: Color(0xff37434d),
                strokeWidth: 1,
              );
            }),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: bottomTitleWidgets,
                  interval: 1)),
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: leftTitleWidgets,
                  reservedSize: 42,
                  interval: 1)),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d)),
        ),
        minX: 0,
        maxX: 11,
        minY: 0,
        maxY: 6,
        lineBarsData: [
          LineChartBarData(
              spots: const [
                FlSpot(0, 3.44),
                FlSpot(2.6, 3.44),
                FlSpot(4.9, 3.44),
                FlSpot(6.8, 3.44),
                FlSpot(8, 3.44),
                FlSpot(9.5, 3.44),
                FlSpot(11, 3.44),
              ],
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  ColorTween(begin: gradientColors[0], end: gradientColors[1])
                      .lerp(0.2)!,
                  ColorTween(begin: gradientColors[0], end: gradientColors[1])
                      .lerp(0.2)!,
                ],
              ),
              barWidth: 5,
              isStrokeCapRound: true,
              dotData: const FlDotData(
                show: false,
              ),
              belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(colors: [
                    ColorTween(begin: gradientColors[0], end: gradientColors[1])
                        .lerp(0.2)!
                        .withOpacity(0.1),
                    ColorTween(begin: gradientColors[0], end: gradientColors[1])
                        .lerp(0.2)!
                        .withOpacity(0.1)
                  ])))
        ]);
  }
}
