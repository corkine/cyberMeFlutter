import 'dart:convert';

import 'package:cyberme_flutter/api/basic.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'gpt.freezed.dart';
part 'gpt.g.dart';

@Freezed(makeCollectionsUnmodifiable: false)
class GPTSetting with _$GPTSetting {
  const factory GPTSetting({@Default({}) Map<String, String> quickQuestion}) =
      _GPTSetting;

  factory GPTSetting.fromJson(Map<String, dynamic> json) =>
      _$GPTSettingFromJson(json);
}

@riverpod
class GPTSettings extends _$GPTSettings {
  late SharedPreferences s;
  @override
  Future<GPTSetting> build() async {
    s = await SharedPreferences.getInstance();
    final ss = s.getString("gptSetting");
    if (ss == null) {
      return const GPTSetting();
    } else {
      return GPTSetting.fromJson(jsonDecode(ss));
    }
  }

  Future<(bool, String)> request(String question) async {
    final q = Uri.encodeQueryComponent(question);
    final url = "/cyber/gpt/simple-question?question=$q";
    final (res, msg) = await requestFromType<String, String>(url, (p0) => p0);
    if (msg.isNotEmpty) {
      return (false, msg);
    } else {
      return (true, res ?? "");
    }
  }

  Future<String> add(String title, String lastQuestion) async {
    final v = state.value;
    if (v == null) return "添加失败";
    final d =
        v.copyWith(quickQuestion: {...v.quickQuestion, title: lastQuestion});
    state = AsyncData(d);
    await s.setString("gptSetting", jsonEncode(d));
    return "添加成功";
  }

  Future<String> delete(String title) async {
    final v = state.value;
    if (v == null) return "删除失败";
    final d = v.copyWith(
        quickQuestion: Map.fromEntries(
            v.quickQuestion.entries.where((element) => element.key != title)));
    state = AsyncData(d);
    await s.setString("gptSetting", jsonEncode(d));
    return "删除成功";
  }
}
