import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'blue.freezed.dart';
part 'blue.g.dart';

SharedPreferences? sp;

@freezed
class BlueData with _$BlueData {
  const factory BlueData({
    DateTime? date,
    @Default(0) int watchSeconds,
  }) = _BlueData;

  factory BlueData.fromJson(Map<String, dynamic> json) =>
      _$BlueDataFromJson(json);
}

@riverpod
Future<Set<String>> blueDataRange(
    BlueDataRangeRef ref, DateTime start, DateTime end) async {
  sp ??= await SharedPreferences.getInstance();
  var res = <String>{};
  for (var i = start; i.isBefore(end); i = i.add(const Duration(days: 1))) {
    String ymd = DateFormat.yMd().format(i);
    var r = sp!.getString("blueData:$ymd");
    if (r == null) {
      continue;
    } else {
      res.add(ymd);
    }
  }
  return res;
}

String keyOfDate(DateTime date) => "blueData:${DateFormat.yMd().format(date)}";

@riverpod
Future<BlueData?> blueData(BlueDataRef ref, DateTime day) async {
  sp ??= await SharedPreferences.getInstance();
  try {
    var res = sp!.getString(keyOfDate(day));
    if (res == null) return null;
    return BlueData.fromJson(jsonDecode(res));
  } catch (e) {
    return null;
  }
}

setBlueData(DateTime dayData, int watchMinutes) async {
  sp ??= await SharedPreferences.getInstance();
  sp!.setString(
      keyOfDate(dayData),
      jsonEncode(
          BlueData(date: dayData, watchSeconds: watchMinutes * 60).toJson()));
}

removeBlueData(DateTime date) async {
  sp ??= await SharedPreferences.getInstance();
  sp!.remove(keyOfDate(date));
}
