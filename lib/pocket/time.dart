import 'package:sprintf/sprintf.dart';

class TimeUtil {
  ///获取今天的日期字符串
  static String get today {
    final now = DateTime.now();
    return sprintf("%4d-%02d-%02d", [now.year, now.month, now.day]);
  }

  ///获取今天的日期字符串
  static String get nowLog {
    final now = DateTime.now();
    return sprintf("%4d-%02d-%02d %02d:%02d:%02d",
        [now.year, now.month, now.day, now.hour, now.minute, now.second]);
  }

  static String get time {
    final now = DateTime.now();
    return sprintf("%2d:%2d", [now.hour, now.minute]);
  }

  ///获取今天的日期信息，短格式
  static String todayShort() {
    final now = DateTime.now();
    String weekday;
    switch (now.weekday) {
      case 1:
        weekday = "周一";
        break;
      case 2:
        weekday = "周二";
        break;
      case 3:
        weekday = "周三";
        break;
      case 4:
        weekday = "周四";
        break;
      case 5:
        weekday = "周五";
        break;
      case 6:
        weekday = "周六";
        break;
      default:
        weekday = "周日";
        break;
    }
    return sprintf("%d 号 %s", [now.day, weekday]);
  }
}
