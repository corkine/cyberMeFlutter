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
    if (now.hour >= 12) {
      return clock(justDate: true);
    } else {
      return null;
    }
  }
}