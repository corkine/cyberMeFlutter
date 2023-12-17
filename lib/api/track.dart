import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'track.g.dart';
part 'track.freezed.dart';

@freezed
class TrackSearchItem with _$TrackSearchItem {
  const factory TrackSearchItem(
      {required String title,
      required String search,
      required String id}) = _TrackSearchItem;
  factory TrackSearchItem.fromJson(Map<String, dynamic> json) =>
      _$TrackSearchItemFromJson(json);
}

@Freezed(makeCollectionsUnmodifiable: false)
class TrackSetting with _$TrackSetting {
  const factory TrackSetting(
      {@Default(true) bool sortByName,
      @Default([]) List<TrackSearchItem> searchItems}) = _TrackSetting;
  factory TrackSetting.fromJson(Map<String, dynamic> json) =>
      _$TrackSettingFromJson(json);
}

@riverpod
Future<TrackSetting> trackSetting(TrackSettingRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  final jsonData = prefs.getString('trackSetting');
  try {
    if (jsonData != null) {
      final data = TrackSetting.fromJson(jsonDecode(jsonData));
      return data;
    }
  } catch (e) {
    debugPrintStack(stackTrace: StackTrace.current, label: e.toString());
  }
  return const TrackSetting();
}

setTrack(bool sort, List<TrackSearchItem>? items) async {
  final prefs = await SharedPreferences.getInstance();
  final data = TrackSetting(sortByName: sort, searchItems: items ?? []);
  await prefs.setString('trackSetting', jsonEncode(data.toJson()));
}
