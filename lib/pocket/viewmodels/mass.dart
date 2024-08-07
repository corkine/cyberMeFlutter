import 'package:cyberme_flutter/pocket/viewmodels/basic.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_kit_reporter/model/payload/quantity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mass.freezed.dart';
part 'mass.g.dart';

@freezed
class MassData with _$MassData {
  factory MassData({
    @Default(0.0) double time,
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
  static int sort(MassData a, MassData b) => b.time > a.time ? 1 : -1;
  static int sortReverse(MassData a, MassData b) => a.time > b.time ? 1 : -1;
  @override
  FutureOr<List<MassData>> build() async {
    final res = await _fetch();
    final res2 = res.values.toList()..sort(sort);
    return res2;
  }

  Future<String> delete(double time) async {
    final newData = (state.value ?? []).where((d) => d.time != time).toList();
    state = AsyncData(newData..sort(sort));
    await _set(Map.fromEntries(newData.map((e) => MapEntry(e.time, e))));
    return "success";
  }

  Future<String> add(MassData data) async {
    List<MassData> newData = [...(state.value ?? []), data]..sort(sort);
    state = AsyncData(newData..sort(sort));
    await _set(Map.fromEntries(newData.map((e) => MapEntry(e.time, e))));
    return "success";
  }

  Future<String> edit(MassData data) async {
    final newData =
        (state.value ?? []).map((d) => d.time == data.time ? data : d);
    state = AsyncData(newData.toList()..sort(sort));
    await _set(Map.fromEntries(newData.map((e) => MapEntry(e.time, e))));
    return "success";
  }

  Future<Set<MassData>> sync(List<Quantity> fromHealthKit) async {
    final c = fromHealthKit.map((e) => e.startTimestamp).toSet();
    final cm = Map.fromEntries(
        fromHealthKit.map((f) => MapEntry(f.startTimestamp, f)));
    final cloudMiss =
        c.difference(state.value?.map((e) => e.time).toSet() ?? {});
    final healthMiss =
        state.value?.map((e) => e.time).toSet().difference(c) ?? {};
    if (cloudMiss.isNotEmpty) {
      List<MassData> newData = [
        ...(state.value ?? []),
        ...cloudMiss.map((i) => MassData(
            time: i.toDouble(), kgValue: cm[i]!.harmonized.value.toDouble()))
      ]..sort(sort);
      debugPrint("sync: $cloudMiss");
      await _set(Map.fromEntries(newData.map((e) => MapEntry(e.time, e))));
      state = AsyncData(newData);
    }
    return state.value?.where((e) => healthMiss.contains(e.time)).toSet() ?? {};
  }

  FutureOr<Map<double, MassData>> _fetch() async {
    final res = await settingFetch(
        tag,
        (d) => ({...d}..remove("update"))
            .map((a, b) => MapEntry(double.parse(a), MassData.fromJson(b))));
    return res ?? {};
  }

  Future<String> _set(Map<double, MassData> data) async {
    await settingUpload(
        tag, data.map((a, b) => MapEntry(a.toString(), b.toJson())));
    return "success";
  }
}
