// ignore_for_file: invalid_annotation_target

import 'package:cyberme_flutter/pocket/viewmodels/basic.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'work.freezed.dart';
part 'work.g.dart';

@freezed
class WorkItem with _$WorkItem {
  factory WorkItem(
      {@JsonKey(name: "work-hour") @Default(0.0) double workHour,
      @JsonKey(name: "check-start") TimePlace? checkStart,
      @JsonKey(name: "check-end") TimePlace? checkEnd,
      @JsonKey(name: "work-day") @Default(false) bool workDay,
      @JsonKey(name: "policy") Policy? policy,
      @JsonKey(name: "date") @Default("") String date}) = _WorkItem;

  factory WorkItem.fromJson(Map<String, dynamic> json) =>
      _$WorkItemFromJson(json);
}

@freezed
class TimePlace with _$TimePlace {
  factory TimePlace({
    @Default("") String source,
    @Default("") String time,
  }) = _TimePlace;

  factory TimePlace.fromJson(Map<String, dynamic> json) =>
      _$TimePlaceFromJson(json);
}

@freezed
class Policy with _$Policy {
  factory Policy() = _Policy;

  factory Policy.fromJson(Map<String, dynamic> json) => _$PolicyFromJson(json);
}

@riverpod
FutureOr<Map<String, WorkItem>> getWorkItems(
    GetWorkItemsRef ref, bool allSummary) async {
  final res = await requestFrom(
      allSummary ? "/cyber/check/all_summary" : "/cyber/check/month_summary",
      (item) {
    return item.entries.map((kv) {
      final date = kv.key;
      final value = kv.value as Map<String, dynamic>;
      return WorkItem.fromJson(value).copyWith(date: date);
    }).toList();
  });
  if (res.$2.isNotEmpty) throw res.$2;
  final r = res.$1 ?? [];
  r.sort((a, b) => a.date.compareTo(b.date));
  return Map.fromIterable(r, key: (e) => e.date);
}
