// ignore_for_file: invalid_annotation_target

import 'dart:convert';

import 'package:cyberme_flutter/pocket/viewmodels/basic.dart';
import 'package:cyberme_flutter/pocket/viewmodels/movie.dart';
import 'package:http/http.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../config.dart';

part 'tv.freezed.dart';
part 'tv.g.dart';

@freezed
class Series with _$Series {
  const factory Series({
    required int id,
    required String name,
    required String url,
    required SeriesInfo info,
    @JsonKey(name: "create_at") required DateTime createAt,
    @JsonKey(name: "update_at") required DateTime updateAt,
  }) = _Series;

  factory Series.fromJson(Map<String, dynamic> json) => _$SeriesFromJson(json);
}

@Freezed(makeCollectionsUnmodifiable: false)
class SeriesInfo with _$SeriesInfo {
  const factory SeriesInfo(
      {@Default([]) List<String> series,
      @Default([]) List<String> watched}) = _SeriesInfo;

  factory SeriesInfo.fromJson(Map<String, dynamic> json) =>
      _$SeriesInfoFromJson(json);
}

@riverpod
class SeriesDB extends _$SeriesDB {
  @override
  Future<List<Series>> build() async {
    final data = await requestFromList(
        "/cyber/movie/", (p0) => p0.map((e) => Series.fromJson(e)));
    final raw = data.$1?.toList() ?? [];
    raw.sort((a, b) => b.id.compareTo(a.id));
    return raw;
  }

  Future<String> delete(int id) async {
    final resp = await post(Uri.parse(endpoint + "/cyber/movie/$id/delete"),
        headers: config.cyberBase64JsonContentHeader);
    final msg = jsonDecode(resp.body)["message"] ?? "无信息";
    //不自动更新，而由确认对话框手动更新
    //state = AsyncData([...?state.value?.where((element) => element.id != id)]);
    return msg;
  }

  Future<String> deleteByUrl(String url) async {
    final id = (state.value ?? [])
        .where((element) => element.url == url)
        .map((e) => e.id)
        .firstOrNull;
    if (id == null) return "没有找到对应剧集";
    final resp = await post(Uri.parse(endpoint + "/cyber/movie/$id/delete"),
        headers: config.cyberBase64JsonContentHeader);
    final msg = jsonDecode(resp.body)["message"] ?? "无信息";
    return msg;
  }

  Future<String> updateWatched(String name, String watched) async {
    final resp = await post(
        Uri.parse(
            endpoint + "/cyber/movie/url-update?name=$name&watched=$watched"),
        headers: config.cyberBase64JsonContentHeader,
        body: jsonEncode({"name": name, "watched": watched}));
    final msg = jsonDecode(resp.body)["message"] ?? "无信息";
    return msg;
  }

  Future<String> add(String name, String url) async {
    var endp = endpoint +
        "/cyber/movie/?name=$name&url=${Uri.encodeQueryComponent(url)}";
    final resp = await post(Uri.parse(endp),
        headers: config.cyberBase64JsonContentHeader,
        body: jsonEncode({"name": name, "url": url}));
    final msg = jsonDecode(resp.body)["message"] ?? "无信息";
    //如果此剧集为想看，则删除想看标签
    await ref
        .read(movieSettingsProvider.notifier)
        .makeWanted(url, reverse: true);
    return msg;
  }

  Future<String?> findName(String url) async {
    final resp = await get(Uri.parse(url));
    final body = resp.body;
    RegExp exp = RegExp(r'<span class="ch-title">(.+?)</span>');
    final match = exp.firstMatch(body);
    if (match == null) return null;
    final name = match.group(1);
    return name;
  }

  Future<String> updateAllWatched(String name, List<String> series) async {
    final ss = [...series];
    ss.sort((b, a) => a.compareTo(b));
    final data = ss.map((e) async {
      final resp = await post(
          Uri.parse(endpoint + "/cyber/movie/url-update?name=$name&watched=$e"),
          headers: config.cyberBase64JsonContentHeader,
          body: jsonEncode({"name": name, "watched": e}));
      final msg = jsonDecode(resp.body)["message"] ?? "无信息";
      return msg;
    });
    final allRes = await Future.wait(data);
    return allRes.join("\n");
  }
}
