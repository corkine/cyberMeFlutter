// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/track.dart';
import 'basic.dart';

part 'track.g.dart';
part 'track.freezed.dart';

@freezed
class TrackSearchItem with _$TrackSearchItem {
  const factory TrackSearchItem(
      {required String title,
      required String search,
      @Default(true) bool track,
      required String id}) = _TrackSearchItem;
  factory TrackSearchItem.fromJson(Map<String, dynamic> json) =>
      _$TrackSearchItemFromJson(json);
}

@Freezed(makeCollectionsUnmodifiable: false)
class TrackSetting with _$TrackSetting {
  const factory TrackSetting(
      {@Default(true) bool sortByName,
      @Default("") String lastSearch,
      @Default({}) Map<String, int> lastData,
      @Default([]) List<TrackSearchItem> searchItems}) = _TrackSetting;
  factory TrackSetting.fromJson(Map<String, dynamic> json) =>
      _$TrackSettingFromJson(json);
}

@riverpod
class TrackSettings extends _$TrackSettings {
  late SharedPreferences s;
  late bool dirty;
  @override
  Future<TrackSetting> build() async {
    s = await SharedPreferences.getInstance();
    dirty = false;
    await syncDownload();
    final jsonData = s.getString('trackSetting');
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

  syncDownload() async {
    debugPrint("sync with server $endpoint now");
    final (setting, msg) =
        await requestFrom("/cyber/service/setting", TrackSetting.fromJson);
    if (setting == null) {
      debugPrint("sync track setting failed: $msg");
      return;
    }
    await s.setString("trackSetting", jsonEncode(setting.toJson()));
  }

  syncUpload() async {
    if (!dirty) return;
    debugPrint("upload track sync now");
    final d = state.value;
    if (d == null) return;
    try {
      final (ok, msg) = await postFrom("/cyber/service/setting", d.toJson());
      if (!ok) {
        debugPrint("sync track setting failed: $msg");
        return;
      }
    } catch (e, tx) {
      debugPrintStack(stackTrace: tx, label: e.toString());
      return;
    }
  }

  setTrack(List<TrackSearchItem>? items) async {
    if (state.value == null) return;
    final data = state.value!.copyWith(searchItems: items ?? []);
    await s.setString('trackSetting', jsonEncode(data.toJson()));
    dirty = true;
    state = AsyncData(data);
  }

  setTrackSortReversed() async {
    if (state.value == null) return;
    final sort = state.value?.sortByName ?? true;
    final data = state.value!.copyWith(
        sortByName: !sort, searchItems: state.value?.searchItems ?? []);
    await s.setString('trackSetting', jsonEncode(data.toJson()));
    dirty = true;
    state = AsyncData(data);
  }

  addTrack(TrackSearchItem item) async {
    if (state.value == null) return;
    final data = state.value!
        .copyWith(searchItems: [...state.value?.searchItems ?? [], item]);
    await s.setString('trackSetting', jsonEncode(data.toJson()));
    dirty = true;
    state = AsyncData(data);
  }

  /// 将当前搜索项保存到配置，并且将配置上传到云端。此外，对于所有 enableTrack 的 SearchItem，
  /// 将当前数据进行保留。
  setLastSearch(String lastSearch,
      {List<(String, int)>? originData, bool withUpload = false}) async {
    final t = state.value;
    if (t == null) return;
    final newLastData = <String, int>{};
    if (originData != null && originData.isNotEmpty) {
      debugPrint("updateing search item data");
      for (var e in t.searchItems) {
        if (e.track) {
          originData
              .where((element) => element.$1.contains(e.search))
              .forEach((element) => newLastData[element.$1] = element.$2);
        }
      }
    }
    final data = t.copyWith(lastSearch: lastSearch, lastData: newLastData);
    await s.setString('trackSetting', jsonEncode(data.toJson()));
    dirty = true;
    state = AsyncData(data);
    if (withUpload) {
      await syncUpload();
    }
  }
}

/// 读取主屏远程追踪数据
@riverpod
Future<List<(String, int)>> fetchTrack(FetchTrackRef ref) async {
  final setting = ref.watch(trackSettingsProvider).value;
  if (setting == null) return [];
  final Response r =
      await get(Uri.parse(Config.visitsUrl), headers: config.cyberBase64Header);
  final d = jsonDecode(r.body);
  if ((d["status"] as int?) == 1) {
    final res = (d["data"] as List)
        .map((e) => e as List)
        .map((e) => (e.first.toString(), int.tryParse(e.last) ?? -1))
        .toList(growable: false);
    return res;
  } else {
    return [];
  }
}

/// 删除当前追踪
@riverpod
Future<String> deleteTrack(DeleteTrackRef ref, List<String> keys) async {
  final res = await Future.wait(keys.map((e) async =>
      await postFrom("/cyber/service/visits/delete-key", {"visit-key": e})));
  ref.invalidate(fetchTrackProvider);
  return res.map((e) => e.$2).join("\n");
}

/// 当前主屏搜索过滤，排序后的结果
@riverpod
List<(String, int)> trackData(TrackDataRef ref, String searchText) {
  final setting = ref.watch(trackSettingsProvider).value;
  final data = ref.watch(fetchTrackProvider).value;
  if (setting == null || data == null) return [];
  var res = data;
  if (setting.sortByName) {
    res.sort((a, b) {
      return a.$1.compareTo(b.$1);
    });
  } else {
    res.sort((a, b) {
      return b.$2.compareTo(a.$2);
    });
  }
  if (searchText.isNotEmpty) {
    res = res.where((e) {
      return e.$1.contains(searchText);
    }).toList(growable: false);
  }
  return res;
}

/// 相比较上一次搜索变更的搜索条目
@riverpod
Set<String> trackSearchChanged(TrackSearchChangedRef ref) {
  final setting = ref.watch(trackSettingsProvider).value;
  final data = ref.watch(fetchTrackProvider).value ?? [];
  if (setting == null) return {};
  final lastData = setting.lastData.entries.toList(growable: false);
  final res = <String>{};
  for (var e in setting.searchItems) {
    if (e.track) {
      final last = lastData.where((element) => element.key.contains(e.search));
      final current = data.where((element) => element.$1.contains(e.search));
      if (current.length > last.length ||
          current.any((element) {
            final lastItem = last.firstWhere(
                (element2) => element2.key == element.$1,
                orElse: () => const MapEntry("", -1));
            return lastItem.value != element.$2;
          })) {
        res.add(e.search);
      }
    }
  }
  return res;
}

/// 本地保存的标签是否打开数据
@riverpod
class TrackMarks extends _$TrackMarks {
  late SharedPreferences s;
  @override
  Future<Map<String, bool>> build() async {
    s = await SharedPreferences.getInstance();
    final res = s.getString("trackMarks") ?? "{}";
    return (jsonDecode(res) as Map<String, dynamic>? ?? {})
        .map((key, value) => MapEntry(key, value as bool? ?? false));
  }

  void mergeWith(Map<String, bool> panel) async {
    final data = {...state.value ?? {}, ...panel};
    await s.setString("trackMarks", jsonEncode(data));
    state = AsyncData(data);
  }

  void set(String key, bool disabled) async {
    final data = {...state.value ?? {}, key: disabled};
    await s.setString("trackMarks", jsonEncode(data));
    state = AsyncData(data);
  }

  void clean(bool all) async {
    if (all) {
      await s.setString("trackMarks", "{}");
      state = AsyncData(<String, bool>{});
    } else {
      final newData = {...state.value ?? {}};
      newData.removeWhere((key, value) => value == false);
      await s.setString("trackMarks", jsonEncode(newData));
      state = AsyncData(newData);
    }
  }

  Future<String> addOrRemoveLabel(String ip, String label, bool add) async {
    final (ok, res) = await postFrom(
        "/cyber/service/visits/mark-ip", {"add": add, "ip": ip, "tag": label});
    if (ok) {
      ref.invalidateSelf();
    }
    return res;
  }
}

/// 详情屏当前日志中所出现的标签以及其是否选中
@riverpod
Future<Map<String, bool>> trackUrlFilters(
    TrackUrlFiltersRef ref, List<Logs> logs) async {
  final marks = await ref.watch(trackMarksProvider.future);
  final tags = logs
      .map((e) => e.iptag as String? ?? "")
      .where((e) => e.isNotEmpty)
      .toSet();
  final marksCopy = {...marks};
  marksCopy.removeWhere((key, value) => !tags.contains(key));
  for (var disabledTag in tags) {
    if (marksCopy[disabledTag] == null) {
      marksCopy[disabledTag] = false;
    }
  }
  marksCopy[""] = false;
  return marksCopy;
}

/// 详情屏应用了标签过滤的列表结果
@riverpod
Future<List<Logs>> trackUrlFilteredLogs(
    TrackUrlFilteredLogsRef ref, List<Logs> logs) async {
  final filters = await ref.watch(trackUrlFiltersProvider.call(logs).future);
  return logs
      .where((element) => filters[element.iptag as String? ?? ""] == false)
      .toList(growable: false);
}
