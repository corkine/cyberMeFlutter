import 'dart:io';

import 'package:cyberme_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

showModal(BuildContext context, Widget widget) {
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.8, builder: (context, sc) => widget));
}

Future<T?> showAdaptiveBottomSheet<T>(
    {required BuildContext context,
    Widget? child,
    Widget Function(BuildContext)? builder,
    bool? cover,
    double? height = 550,
    double? divideHeight,
    double? minusHeight}) {
  return showModalBottomSheet<T>(
      isScrollControlled: cover ?? Platform.isIOS,
      context: context,
      builder: (context) => cover ?? Platform.isIOS
          ? SizedBox(
              height: divideHeight != null
                  ? (MediaQuery.maybeOf(context)!.size.height / divideHeight)
                  : minusHeight != null
                      ? (MediaQuery.maybeOf(context)!.size.height - minusHeight)
                      : height,
              child: child ?? builder!(context))
          : child ?? builder!(context));
}

showDebugBar(BuildContext context, dynamic e, {bool withPop = false}) {
  if (withPop) {
    Navigator.of(context).pop();
  }
  final sm = ScaffoldMessenger.of(context);
  sm.showMaterialBanner(MaterialBanner(
      content: GestureDetector(
          onTap: () => sm.clearMaterialBanners(),
          child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: Text(e.toString()))),
      actions: const [SizedBox()]));
}

showWaitingBar(BuildContext context,
    {String text = "正在刷新", Future Function()? func}) async {
  ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
      content: Row(children: [
        const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator.adaptive(strokeWidth: 2)),
        const SizedBox(width: 10),
        Text(text)
      ]),
      actions: const [SizedBox()]));
  if (func != null) {
    try {
      await func();
    } catch (_) {}
    ScaffoldMessenger.of(context).clearMaterialBanners();
  }
}

Future<bool> showSimpleMessage(BuildContext context,
    {String? title,
    required String content,
    bool withPopFirst = false,
    bool useSnackBar = false,
    int duration = 500}) async {
  if (withPopFirst) {
    Navigator.of(context).pop();
  }
  if (useSnackBar) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(content), duration: Duration(milliseconds: duration)));
    return true;
  } else {
    return await showDialog<bool>(
            context: context,
            builder: (context) => Theme(
                  data: appThemeData,
                  child: AlertDialog(
                    title: Text(title ?? "提示"),
                    content: SingleChildScrollView(child: Text(content)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text("取消")),
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text("确定"))
                    ],
                  ),
                )) ??
        false;
  }
}

DateTime getThisWeekMonday() {
  DateTime now = DateTime.now();
  int currentWeekday = now.weekday;

  // 如果今天是周一，直接返回今天的日期
  if (currentWeekday == DateTime.monday) {
    return DateTime(now.year, now.month, now.day);
  }

  // 计算到最近的周一需要减去的天数
  int daysToSubtract = currentWeekday - DateTime.monday;

  // 使用 subtract 方法来获取本周的周一
  DateTime monday = now.subtract(Duration(days: daysToSubtract));

  // 返回时间设置为 00:00:00
  return DateTime(monday.year, monday.month, monday.day);
}

Widget buildRichDate(DateTime? date,
    {required DateTime today,
    required DateTime weekDayOne,
    required DateTime lastWeekDayOne,
    double? fontSize}) {
  if (date == null) return const Text("未知日期");
  final df = DateFormat("yyyy-MM-dd");
  bool isToday = !today.isAfter(date);
  bool thisWeek = !weekDayOne.isAfter(date);
  bool lastWeek = !thisWeek && !lastWeekDayOne.isAfter(date);
  final color = isToday
      ? Colors.lightGreen
      : thisWeek
          ? Colors.lightGreen
          : lastWeek
              ? Colors.blueGrey
              : Colors.grey;
  final style = TextStyle(
      decoration: isToday ? TextDecoration.underline : null,
      decorationColor: color,
      color: color,
      fontSize: fontSize);
  if (thisWeek) {
    if (isToday) {
      return Text("${df.format(date)} 今天", style: style);
    } else if (date.add(const Duration(days: 1)).day == today.day) {
      return Text("${df.format(date)} 昨天", style: style);
    } else if (date.add(const Duration(days: 2)).day == today.day) {
      return Text("${df.format(date)} 前天", style: style);
    }
  }
  switch (date.weekday) {
    case 1:
      return Text("${df.format(date)} 周一", style: style);
    case 2:
      return Text("${df.format(date)} 周二", style: style);
    case 3:
      return Text("${df.format(date)} 周三", style: style);
    case 4:
      return Text("${df.format(date)} 周四", style: style);
    case 5:
      return Text("${df.format(date)} 周五", style: style);
    case 6:
      return Text("${df.format(date)} 周六", style: style);
    default:
      return Text("${df.format(date)} 周日", style: style);
  }
}
