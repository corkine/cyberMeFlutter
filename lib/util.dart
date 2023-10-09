import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';

class Util {
  /// 返回常用的时间信息
  static String clock(
      {bool justDate = false,
      bool justSeconds = false,
      bool justBeforeSeconds = false}) {
    var now = DateTime.now().toLocal();
    if (justDate) {
      return sprintf("%04d-%02d-%02d", [now.year, now.month, now.day]);
    } else if (justSeconds) {
      return sprintf("%02d", [now.second]);
    } else if (justBeforeSeconds) {
      return sprintf("%02d-%02d-%02d %02d:%02d:",
          [now.year, now.month, now.day, now.hour, now.minute]);
    } else {
      return sprintf("%02d-%02d-%02d %02d:%02d",
          [now.year, now.month, now.day, now.hour, now.minute]);
    }
  }

  /// 采样时间为上午，则不显示采样信息，采样时间为下午才显示采样信息
  static String? pickTime() {
    var now = DateTime.now().toLocal();
    /// 暂时不显示 核酸已采样 字样
    if (false && now.hour >= 12) {
      return clock(justDate: true);
    } else {
      return null;
    }
  }

  static Widget waiting = const Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
        CircularProgressIndicator(),
        Padding(
          padding: EdgeInsets.all(18.0),
          child: Text('正在检索数据'),
        )
      ]));

  static const pt10 = Padding(padding: EdgeInsets.only(top: 10));
  static const pt20 = Padding(padding: EdgeInsets.only(top: 20));
  static const pt30 = Padding(padding: EdgeInsets.only(top: 30));
  static const pl10 = Padding(padding: EdgeInsets.only(left: 10));
  static const Padding pl20 = Padding(padding: EdgeInsets.only(left: 20));
  static const pl30 = Padding(padding: EdgeInsets.only(left: 30));
  static const Padding pa10 = Padding(padding: EdgeInsets.all(10));
  static const pa20 = Padding(padding: EdgeInsets.all(20));
  static const Padding pa30 = Padding(padding: EdgeInsets.all(30));
}
