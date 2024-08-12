import 'package:cyberme_flutter/pocket/util.dart';
import 'package:cyberme_flutter/pocket/viewmodels/basic.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_kit_reporter/model/payload/quantity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mass.freezed.dart';
part 'mass.g.dart';

@freezed
class MassGroup with _$MassGroup {
  const factory MassGroup({
    @Default(0) int id, //startDay Time MillSeconds
    @Default("") String desc, //plan
    @Default(false) bool satisfied,
    @Default([]) List<MassData> data,
    @Default(0) double goalKg, //note
    @Default("") String note,
    @Default("") String reward,
    @Default(false) bool rewardChecked,
  }) = _MassGroup;

  factory MassGroup.fromJson(Map<String, dynamic> json) =>
      _$MassGroupFromJson(json);
}

@freezed
class MassData with _$MassData {
  const factory MassData(
      {@Default(0.0) double time, //seconds
      @Default("") String title,
      @Default("") String note,
      @Default(0) double kgValue,
      @Default(0) int group,
      MassData? prev,
      MassData? next}) = _MassData;

  factory MassData.fromJson(Map<String, dynamic> json) =>
      _$MassDataFromJson(json);
}

@riverpod
class MassPlanDb extends _$MassPlanDb {
  static const tag = "health_mass_plan";
  @override
  FutureOr<Map<int, MassGroup>> build() async {
    final res = await settingFetch(
        tag,
        (d) => ({...d}..remove("update")).map((k, v) {
              var week = MassGroup.fromJson(v);
              return MapEntry(int.parse(k), week);
            }));
    return res ?? {};
  }

  Future<String> addOrEdit(MassGroup data) async {
    final n = {...?state.value};
    n[data.id] = data;
    await saveState(n);
    state = AsyncData(n);
    return "success";
  }

  Future<String> delete(int id) async {
    final n = {...?state.value};
    n.remove(id);
    await saveState(n);
    state = AsyncData(n);
    return "success";
  }

  Future saveState(Map<int, MassGroup>? data) async {
    await settingUpload(
        tag, (data ?? {}).map((k, v) => MapEntry(k.toString(), v.toJson())));
  }
}

@riverpod
class MassDb extends _$MassDb {
  static const tag = "health_mass";
  static int sort(MassData a, MassData b) => b.time > a.time ? 1 : -1;
  static int sortReverse(MassData a, MassData b) => a.time > b.time ? 1 : -1;

  List<MassData> sortAndCompute(List<MassData> data) {
    data.sort(sort);
    for (var i = 0; i < data.length - 1; i++) {
      final a = data[i];
      final b = data[i + 1];
      data[i] = a.copyWith(next: b);
      data[i + 1] = b.copyWith(prev: a);
    }
    return data;
  }

  @override
  FutureOr<List<MassData>> build() async {
    final res = await _fetch();
    return sortAndCompute(res.values.toList());
  }

  Future<String> delete(double time) async {
    final newData = (state.value ?? []).where((d) => d.time != time).toList();
    state = AsyncData(sortAndCompute(newData));
    await _set(Map.fromEntries(newData.map((e) => MapEntry(e.time, e))));
    return "success";
  }

  Future<String> add(MassData data) async {
    List<MassData> newData = [
      ...(state.value ?? []),
      data.copyWith(group: groupOfTime(data.time))
    ];
    state = AsyncData(sortAndCompute(newData));
    await _set(Map.fromEntries(newData.map((e) => MapEntry(e.time, e))));
    return "success";
  }

  Future<String> edit(MassData data) async {
    final newData =
        (state.value ?? []).map((d) => d.time == data.time ? data : d);
    state = AsyncData(sortAndCompute(newData.toList()));
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
      ];
      debugPrint("sync: $cloudMiss");
      await _set(Map.fromEntries(newData.map((e) => MapEntry(e.time, e))));
      state = AsyncData(sortAndCompute(newData));
    }
    return state.value?.where((e) => healthMiss.contains(e.time)).toSet() ?? {};
  }

  FutureOr<Map<double, MassData>> _fetch() async {
    final res = await settingFetch(
        tag,
        (d) => ({...d}..remove("update")).map((a, b) {
              final bb = MassData.fromJson(b);
              return MapEntry(
                  double.parse(a), bb.copyWith(group: groupOfTime(bb.time)));
            }));
    return res ?? {};
  }

  Future<String> _set(Map<double, MassData> data) async {
    await settingUpload(
        tag, data.map((a, b) => MapEntry(a.toString(), b.toJson())));
    return "success";
  }
}

@riverpod
Map<int, MassGroup> massWeekView(MassWeekViewRef ref) {
  final r = {...?ref.watch(massPlanDbProvider).value};
  final l = ref.watch(massDbProvider).value ?? [];
  for (final i in l) {
    final findGroup = r[i.group];
    if (findGroup != null) {
      final start = DateTime.fromMillisecondsSinceEpoch(findGroup.id);
      final end = getEndOfRange(start);
      final startInt = start.millisecondsSinceEpoch ~/ 1000;
      final endInt = end.millisecondsSinceEpoch ~/ 1000;
      final inIt =
          l.where((t) => t.time >= startInt && t.time <= endInt).toList();
      inIt.sort((a, b) => (b.time - a.time).toInt());
      final ok = (inIt.lastOrNull?.kgValue ?? 1000) < findGroup.goalKg;
      r[i.group] = findGroup.copyWith(satisfied: ok, data: inIt);
    } else {
      r[i.group] = MassGroup(id: i.group, data: [i]);
    }
  }
  return r;
}

int groupOfTime(double timeSeconds) {
  final start =
      DateTime.fromMillisecondsSinceEpoch((timeSeconds * 1000).toInt());
  final startPure = DateTime(start.year, start.month, start.day);
  final weekId = getFirstDayOfRange(startPure).millisecondsSinceEpoch;
  return weekId;
}

DateTime getEndOfRange(DateTime start) {
  return start.add(const Duration(days: 7));
}

DateTime getFirstDayOfRange(DateTime start) {
  return start.subtract(Duration(days: start.weekday - 1));
}

Widget buildGroupView(DateTime date) {
  final week = weekOfYear(date);
  return Text("${date.year}年第$week周");
}

bool groupNoInfo(MassGroup? groupInfo) {
  return groupInfo == null || groupInfo.goalKg == 0;
}
