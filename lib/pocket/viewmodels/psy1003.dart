import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'psy1003.freezed.dart';
part 'psy1003.g.dart';

@freezed
class PsySimpleData with _$PsySimpleData {
  factory PsySimpleData({
    @Default("") String name,
    @Default("") String mark,
    @Default("") String age,
    @Default("") String major,
    @Default("") String gender,
    @Default("") String version,
    DateTime? time,
  }) = _PsySimpleData;

  factory PsySimpleData.fromJson(Map<String, dynamic> json) =>
      _$PsySimpleDataFromJson(json);
}

@riverpod
FutureOr<List<PsySimpleData>> getPsySimple(GetPsySimpleRef ref) async {
  final r = await get(Uri.parse(
      "https://cyber.mazhangjing.com/psych/dashboard/psych-data-download/1003?day=10&summary=true"));
  final jj = jsonDecode(r.body) as Map<String, dynamic>;
  final j = jj["data"] as List<dynamic>;
  return j.map((e) {
    final b = e["被试收集"] as Map<String, dynamic>;
    final m = e["标记数据"] as Map<String, dynamic>;
    final t = e["开始时间"] as int;
    final time = DateTime.fromMillisecondsSinceEpoch(t);
    return PsySimpleData(
        age: b["age"].toString(),
        name: b["name"],
        mark: "${m["exp-id"]} ${m["exp-cond"]}",
        major: b["major"].toString(),
        version: e["实验版本"] ?? "未知",
        time: time,
        gender: b["gender"].toString());
  }).toList();
}
