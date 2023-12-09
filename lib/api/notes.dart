import 'dart:convert';

import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pocket/config.dart';
import 'basic.dart';

part 'notes.freezed.dart';

part 'notes.g.dart';

@freezed
class QuickNote with _$QuickNote {
  const factory QuickNote({
    @Default(-1) int Id,
    @Default("") String From,
    @Default("") String Content,
    @Default(-1) int LiveSeconds,
    @Default("") String LastUpdate,
  }) = _QuickNote;

  factory QuickNote.fromJson(Map<String, dynamic> json) =>
      _$QuickNoteFromJson(json);
}

@riverpod
class QuickNotes extends _$QuickNotes {
  @override
  Future<(QuickNote?, String)> build() async {
    return await requestFrom("/cyber/note/last", QuickNote.fromJson);
  }

  Future<String> setNote(String content) async {
    const url = "$endpoint/cyber/note";
    final r = await post(Uri.parse(url),
        headers: config.cyberBase64JsonContentHeader,
        body: jsonEncode({
          "content": content,
          "from": "CyberMe Flutter",
          "liveSeconds": 100
        }));
    final d = jsonDecode(r.body);
    return d["message"]?.toString() ?? "未知错误";
  }
}

SharedPreferences? sp;

@riverpod
Future<Set<String>> blueDataRange(
    BlueDataRangeRef ref, DateTime start, DateTime end) async {
  sp ??= await SharedPreferences.getInstance();
  var res = <String>{};
  for (var i = start; i.isBefore(end); i = i.add(const Duration(days: 1))) {
    String ymd = DateFormat.yMd().format(i);
    var r = sp!.getInt("blueData:$ymd");
    if (r == null) {
      continue;
    } else {
      res.add(ymd);
    }
  }
  return res;
}

@riverpod
Future<DateTime?> blueData(BlueDataRef ref, DateTime day) async {
  sp ??= await SharedPreferences.getInstance();
  var res = sp!.getInt("blueData:${DateFormat.yMd().format(day)}");
  if (res == null) return null;
  return DateTime.fromMicrosecondsSinceEpoch(res, isUtc: true);
}

setBlueData(DateTime dayData) async {
  sp ??= await SharedPreferences.getInstance();
  sp!.setInt("blueData:${DateFormat.yMd().format(dayData)}",
      dayData.microsecondsSinceEpoch);
}

removeBlueData(DateTime date) async {
  sp ??= await SharedPreferences.getInstance();
  sp!.remove("blueData:${DateFormat.yMd().format(date)}");
}
