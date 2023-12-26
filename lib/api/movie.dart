import 'dart:convert';

import 'package:cyberme_flutter/api/tv.dart';
import 'package:cyberme_flutter/pocket/models/movie.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pocket/config.dart';
import 'basic.dart';

part 'movie.g.dart';
part 'movie.freezed.dart';

@riverpod
Future<(List<Movie>, String)> getMovies(GetMoviesRef ref) async {
  final setting = await ref.watch(movieSettingsProvider.future);
  final r = await get(
      Uri.parse(Config.movieUrl(
          setting.showTv ? "tv" : "movie", setting.showHot ? "hot" : "new")),
      headers: config.cyberBase64Header);
  final d = jsonDecode(r.body);
  final m = d["message"] ?? "没有消息";
  if (((d["status"] as int?) ?? -1) <= 0) {
    return (<Movie>[], m.toString());
  }
  final data = d["data"] as List?;
  final md = data
          ?.map((e) => e as Map?)
          .map((e) => Movie.fromJson(e))
          .toList(growable: false) ??
      [];
  return (md, "");
}

@freezed
class MovieSetting with _$MovieSetting {
  const factory MovieSetting({
    @Default({}) Set<String> watchedTv,
    @Default({}) Set<String> watchedMovie,
    @Default({}) Set<String> ignoreItems,
    @Default(true) bool showTv,
    @Default(true) bool showHot,
    @Default(MovieFilter()) MovieFilter lastFilter,
  }) = _MovieSetting;

  factory MovieSetting.fromJson(Map<String, dynamic> json) =>
      _$MovieSettingFromJson(json);
}

@riverpod
class MovieSettings extends _$MovieSettings {
  SharedPreferences? s;

  @override
  Future<MovieSetting> build() async {
    await syncDownload();
    s ??= await SharedPreferences.getInstance();
    final d = s!.getString("movieSetting");
    if (d == null) return const MovieSetting();
    try {
      return MovieSetting.fromJson(jsonDecode(d));
    } catch (e, tx) {
      debugPrintStack(stackTrace: tx, label: e.toString());
      return const MovieSetting();
    }
  }

  syncDownload() async {
    final (setting, msg) =
        await requestFrom("/cyber/movie/setting", MovieSetting.fromJson);
    if (setting == null) {
      debugPrint("sync movie setting failed: $msg");
      return;
    }
    s ??= await SharedPreferences.getInstance();
    await s!.setString("movieSetting", jsonEncode(setting.toJson()));
  }

  syncUpload({MovieFilter? filter}) async {
    final d = state.value;
    if (d == null) return;
    final u = d.copyWith(lastFilter: filter ?? d.lastFilter);
    print("upload with $filter");
    try {
      final (ok, msg) = await postFrom("/cyber/movie/setting", u.toJson());
      if (!ok) {
        debugPrint("sync movie setting failed: $msg");
        return;
      }
    } catch (e, tx) {
      debugPrintStack(stackTrace: tx, label: e.toString());
      return;
    }
  }

  makeWatched(bool isTv, String url, {bool reverse = false}) async {
    s ??= await SharedPreferences.getInstance();
    var v = state.value;
    if (v == null) return;
    if (!reverse) {
      if (isTv) {
        v = v.copyWith(watchedTv: {url, ...v.watchedTv});
      } else {
        v = v.copyWith(watchedMovie: {url, ...v.watchedMovie});
      }
    } else {
      if (isTv) {
        v = v.copyWith(
            watchedTv: v.watchedTv.where((element) => element != url).toSet());
      } else {
        v = v.copyWith(
            watchedMovie:
                v.watchedMovie.where((element) => element != url).toSet());
      }
    }
    await s!.setString("movieSetting", jsonEncode(v.toJson()));
    state = AsyncData(v);
  }

  makeIgnored(String url, {bool reverse = false}) async {
    s ??= await SharedPreferences.getInstance();
    var v = state.value;
    if (v == null) return;
    if (!reverse) {
      v = v.copyWith(ignoreItems: {url, ...v.ignoreItems});
    } else {
      v = v.copyWith(
          ignoreItems:
              v.ignoreItems.where((element) => element != url).toSet());
    }
    await s!.setString("movieSetting", jsonEncode(v.toJson()));
    state = AsyncData(v);
  }

  toggleShowTv() async {
    var v = state.value;
    if (v == null) return;
    v = v.copyWith(showTv: !v.showTv);
    state = AsyncData(v);
  }

  toggleShowHot() async {
    var v = state.value;
    if (v == null) return;
    v = v.copyWith(showHot: !v.showHot);
    state = AsyncData(v);
  }
}

@freezed
class MovieFilter with _$MovieFilter {
  const factory MovieFilter(
      {@Default(0.0) double avgStar,
      @Default(0.0) double selectStar,
      @Default(true) bool showWatched,
      @Default(true) bool showTracked,
      @Default(true) bool showIgnored,
      @Default({}) Set<String> allTags,
      @Default({}) Set<String> selectTags}) = _MovieFilter;
  factory MovieFilter.fromJson(Map<String, dynamic> json) =>
      _$MovieFilterFromJson(json);
}

@riverpod
class MovieFilters extends _$MovieFilters {
  @override
  MovieFilter build() {
    final movies = ref.watch(getMoviesProvider).value?.$1;
    final setting = ref.watch(movieSettingsProvider).value;
    if (movies == null) return const MovieFilter();
    var avgStar = 0.0;
    var tags = <String>{};
    final isMovie = setting?.showTv == false;
    for (final m in movies) {
      avgStar += double.tryParse(m.star ?? "") ?? 0.0;
      if (isMovie && m.update != null) {
        tags.add(m.update!);
      }
    }
    avgStar /= movies.length;
    var selectStar = 0.0;
    var selectTags = <String>{};

    selectStar = setting?.lastFilter.selectStar ?? 0.0;
    selectTags = tags.intersection(setting?.lastFilter.selectTags ?? {});

    return MovieFilter(
        avgStar: avgStar,
        allTags: tags,
        selectStar: selectStar,
        selectTags: selectTags,
        showWatched: setting?.lastFilter.showWatched ?? true,
        showTracked: setting?.lastFilter.showTracked ?? true,
        showIgnored: setting?.lastFilter.showIgnored ?? true);
  }

  setShowWatched(bool show) async {
    state = state.copyWith(showWatched: show);
  }

  setShowIgnored(bool show) async {
    state = state.copyWith(showIgnored: show);
  }

  setShowTracked(bool show) async {
    state = state.copyWith(showTracked: show);
  }

  setStar(double star) {
    state = state.copyWith(selectStar: star);
  }

  cleanSelectTags() {
    state = state.copyWith(selectTags: {});
  }

  toggleTag(String tag) {
    var tags = state.selectTags;
    if (tags.contains(tag)) {
      tags = tags.where((element) => element != tag).toSet();
    } else {
      tags = {tag, ...tags};
    }
    state = state.copyWith(selectTags: tags);
  }
}

@riverpod
List<Movie> movieFiltered(MovieFilteredRef ref) {
  final movie = ref.watch(getMoviesProvider).value;
  final setting = ref.watch(movieSettingsProvider).value;
  final filter = ref.watch(movieFiltersProvider);
  final track =
      ref.watch(seriesDBProvider).value?.map((e) => e.url).toSet() ?? {};
  if (movie == null || setting == null) return [];
  final watched = setting.showTv ? setting.watchedTv : setting.watchedMovie;
  final ignored = setting.ignoreItems;
  return movie.$1.where((element) {
    if (!filter.showWatched && watched.contains(element.url)) {
      return false;
    }
    if (!filter.showTracked && track.contains(element.url)) {
      return false;
    }
    if (!filter.showIgnored && ignored.contains(element.url)) {
      return false;
    }
    if (filter.selectStar != 0.0 &&
        element.star != null &&
        element.star!.isNotEmpty &&
        element.star! != "N/A") {
      final star = double.tryParse(element.star!);
      if (star == null) return false;
      if (star < filter.selectStar) return false;
    }
    if (filter.selectTags.isNotEmpty &&
        element.update != null &&
        element.update!.isNotEmpty) {
      if (!filter.selectTags.contains(element.update)) return false;
    }
    return true;
  }).toList(growable: false);
}
