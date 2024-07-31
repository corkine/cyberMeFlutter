import 'package:cyberme_flutter/api/basic.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'health_blue.freezed.dart';
part 'health_blue.g.dart';

@freezed
class BlueData with _$BlueData {
  factory BlueData({
    @Default(0) int time,
    @Default("") String note,
    bool? protected,
  }) = _BlueData;

  factory BlueData.fromJson(Map<String, dynamic> json) =>
      _$BlueDataFromJson(json);
}

@riverpod
class BluesDb extends _$BluesDb {
  static const tag = "health_blue";
  int sort(BlueData a, BlueData b) => b.time.compareTo(a.time);
  @override
  FutureOr<List<BlueData>> build() async {
    final res = await _fetch();
    return res.values.toList()..sort(sort);
  }

  Future<String> delete(int time) async {
    final newData = (state.value ?? []).where((d) => d.time != time).toList();
    state = AsyncData(newData);
    await _set(Map.fromEntries(newData.map((e) => MapEntry(e.time, e))));
    return "success";
  }

  Future<String> add(BlueData data) async {
    List<BlueData> newData = [...(state.value ?? []), data]..sort(sort);
    state = AsyncData(newData);
    await _set(Map.fromEntries(newData.map((e) => MapEntry(e.time, e))));
    return "success";
  }

  Future<String> edit(BlueData data) async {
    final newData =
        (state.value ?? []).map((d) => d.time == data.time ? data : d);
    state = AsyncData(newData.toList());
    await _set(Map.fromEntries(newData.map((e) => MapEntry(e.time, e))));
    return "success";
  }

  Future<Set<BlueData>> sync(Set<int> fromHealthKit) async {
    final c = fromHealthKit.toSet();
    final cloudMiss =
        c.difference(state.value?.map((e) => e.time).toSet() ?? {});
    final healthMiss =
        state.value?.map((e) => e.time).toSet().difference(c) ?? {};
    if (cloudMiss.isNotEmpty) {
      List<BlueData> newData = [
        ...(state.value ?? []),
        ...cloudMiss.map((i) => BlueData(time: i))
      ]..sort(sort);
      debugPrint("sync: $cloudMiss");
      await _set(Map.fromEntries(newData.map((e) => MapEntry(e.time, e))));
      state = AsyncData(newData);
    }
    return state.value?.where((e) => healthMiss.contains(e.time)).toSet() ?? {};
  }

  FutureOr<Map<int, BlueData>> _fetch() async {
    final res = await settingFetch(
        tag,
        (d) => ({...d}..remove("update"))
            .map((a, b) => MapEntry(int.parse(a), BlueData.fromJson(b))));
    return res ?? {};
  }

  Future<String> _set(Map<int, BlueData> data) async {
    await settingUpload(
        tag, data.map((a, b) => MapEntry(a.toString(), b.toJson())));
    return "success";
  }
}
