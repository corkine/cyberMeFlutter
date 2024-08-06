import 'package:cyberme_flutter/pocket/viewmodels/basic.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_kit_reporter/model/payload/quantity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mass.freezed.dart';
part 'mass.g.dart';

@freezed
class MassData with _$MassData {
  factory MassData({
    @Default(0) int time,
    @Default("") String title,
    @Default("") String description,
    @Default(0) double kgValue,
  }) = _BlueData;

  factory MassData.fromJson(Map<String, dynamic> json) =>
      _$MassDataFromJson(json);
}

@riverpod
class MassDb extends _$MassDb {
  static const tag = "health_mass";
  int sort(MassData a, MassData b) => b.time.compareTo(a.time);
  @override
  FutureOr<List<MassData>> build() async {
    final res = await _fetch();
    return res.values.toList()..sort(sort);
    // return [
    //   MassData(time: 1, kgValue: 98.3, title: "test", description: "desc"),
    //   MassData(time: 2, kgValue: 99.6, title: "test", description: "desc"),
    //   MassData(time: 3, kgValue: 95.6, title: "吃多了", description: "desc"),
    //   MassData(time: 4, kgValue: 98.3),
    //   MassData(time: 1722672578, kgValue: 95.6),
    //   MassData(time: 1722845302, kgValue: 92.4),
    //   MassData(
    //       time: 1722931478,
    //       kgValue: 99.4,
    //       title: "因为吃的比较多",
    //       description: "desc"),
    // ]..sort(sort);
  }

  Future<String> delete(int time) async {
    final newData = (state.value ?? []).where((d) => d.time != time).toList();
    state = AsyncData(newData);
    await _set(Map.fromEntries(newData.map((e) => MapEntry(e.time, e))));
    return "success";
  }

  Future<String> add(MassData data) async {
    List<MassData> newData = [...(state.value ?? []), data]..sort(sort);
    state = AsyncData(newData);
    await _set(Map.fromEntries(newData.map((e) => MapEntry(e.time, e))));
    return "success";
  }

  Future<String> edit(MassData data) async {
    final newData =
        (state.value ?? []).map((d) => d.time == data.time ? data : d);
    state = AsyncData(newData.toList());
    await _set(Map.fromEntries(newData.map((e) => MapEntry(e.time, e))));
    return "success";
  }

  Future<Set<MassData>> sync(List<Quantity> fromHealthKit) async {
    final c = fromHealthKit.map((e) => e.startTimestamp as int).toSet();
    final cm = Map.fromEntries(
        fromHealthKit.map((f) => MapEntry(f.startTimestamp as int, f)));
    final cloudMiss =
        c.difference(state.value?.map((e) => e.time).toSet() ?? {});
    final healthMiss =
        state.value?.map((e) => e.time).toSet().difference(c) ?? {};
    if (cloudMiss.isNotEmpty) {
      List<MassData> newData = [
        ...(state.value ?? []),
        ...cloudMiss.map((i) =>
            MassData(time: i, kgValue: cm[i]!.harmonized.value as double))
      ]..sort(sort);
      debugPrint("sync: $cloudMiss");
      await _set(Map.fromEntries(newData.map((e) => MapEntry(e.time, e))));
      state = AsyncData(newData);
    }
    return state.value?.where((e) => healthMiss.contains(e.time)).toSet() ?? {};
  }

  FutureOr<Map<int, MassData>> _fetch() async {
    final res = await settingFetch(
        tag,
        (d) => ({...d}..remove("update"))
            .map((a, b) => MapEntry(int.parse(a), MassData.fromJson(b))));
    return res ?? {};
  }

  Future<String> _set(Map<int, MassData> data) async {
    await settingUpload(
        tag, data.map((a, b) => MapEntry(a.toString(), b.toJson())));
    return "success";
  }
}
