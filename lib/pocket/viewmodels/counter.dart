import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'counter.g.dart';
part 'counter.freezed.dart';

@freezed
class Counter with _$Counter {
  factory Counter({
    @Default("in") String mark,
    @Default("") String note,
    @Default(0) int time,
    @Default("") String id,
  }) = _Counter;

  factory Counter.fromJson(Map<String, dynamic> json) =>
      _$CounterFromJson(json);
}

extension CounterX on Counter {
  bool get isOut => mark == "out";
  // ignore: non_constant_identifier_names
  static String OUT = "out";
  // ignore: non_constant_identifier_names
  static String IN = "in";
}

@riverpod
String counterInfo(CounterInfoRef ref) {
  final d = ref.watch(countersProvider).valueOrNull ?? [];
  final now = DateTime.now();
  final todayStart =
      DateTime(now.year, now.month, now.day, 0, 0, 0).millisecondsSinceEpoch;
  final today =
      DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;
  final todayData =
      d.where((e) => e.time >= todayStart && e.time <= today).toList();
  return "共${d.length}条记录，今天${todayData.length ~/ 2}趟";
}

@riverpod
class Counters extends _$Counters {
  @override
  FutureOr<List<Counter>> build() async {
    final s = await SharedPreferences.getInstance();
    final d = jsonDecode(s.getString("counter") ?? "[]") as List;
    final t =
        d.map((e) => Counter.fromJson(e as Map<String, dynamic>)).toList();
    return t..sort((b, a) => a.time - b.time);
  }

  add(Counter counter) async {
    state = AsyncData(
        [...state.valueOrNull ?? [], counter]..sort((b, a) => a.time - b.time));
    save();
  }

  remove(String id) async {
    state =
        AsyncData((state.valueOrNull?.where((e) => e.id != id).toList() ?? []));
    save();
  }

  modify(Counter counter) async {
    state = AsyncData((state.valueOrNull
            ?.map((e) => e.id == counter.id ? counter : e)
            .toList()
          ?..sort((b, a) => a.time - b.time)) ??
        []);
    save();
  }

  save() async {
    final s = await SharedPreferences.getInstance();
    final d = state.valueOrNull?.map((e) => e.toJson()).toList() ?? [];
    s.setString("counter", jsonEncode(d));
  }
}
