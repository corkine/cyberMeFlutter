// ignore_for_file: invalid_annotation_target

import 'dart:convert';

import 'package:cyberme_flutter/pocket/viewmodels/tv.dart';
import 'package:cyberme_flutter/pocket/models/movie.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import 'basic.dart';

part 'movie.g.dart';
part 'movie.freezed.dart';

@freezed
class MovieSetting with _$MovieSetting {
  const factory MovieSetting({
    @Default({}) Set<String> watchedTv,
    @Default({}) Set<String> watchedMovie,
    @Default({}) Set<String> wantItems,
    @Default({}) Set<String> ignoreItems,
    @Default(true) bool showTv,
    @Default(true) bool showHot,
    @Default(MovieFilter()) MovieFilter lastFilter,
  }) = _MovieSetting;

  factory MovieSetting.fromJson(Map<String, dynamic> json) =>
      _$MovieSettingFromJson(json);
}

@freezed
class MovieRating with _$MovieRating {
  const factory MovieRating(
          {@Default("") @JsonKey(name: "imdb-star") String imdbStar,
          @Default("") @JsonKey(name: "douban-star") String doubanStar,
          @Default("") @JsonKey(name: "imdb-count") String imdbCount,
          @Default("") @JsonKey(name: "douban-count") String doubanCount}) =
      _MovieRating;

  factory MovieRating.fromJson(Map<String, dynamic> json) =>
      _$MovieRatingFromJson(json);
}

@freezed
class MovieDetail with _$MovieDetail {
  const factory MovieDetail(
      {@Default("") String title,
      @Default("") @JsonKey(name: "title-en") titleEn,
      @Default("") String description,
      @Default("") String update,
      @Default("") String duration,
      @Default("") String level,
      @Default("") String year,
      @Default("") String url,
      @Default("") String country,
      @Default("") String img,
      @Default([]) List<String> types,
      @Default(MovieRating()) MovieRating rating}) = _MovieDetail;

  factory MovieDetail.fromJson(Map<String, dynamic> json) =>
      _$MovieDetailFromJson(json);
}

@riverpod
Future<MovieDetail?> fetchMovieDetail(
    FetchMovieDetailRef ref, String url, bool cache) async {
  final encodeUrl = Uri.encodeQueryComponent(url);
  final (ok, res) = await requestFrom(
      "/cyber/movie/detail?url=$encodeUrl&cache=$cache", MovieDetail.fromJson);
  if (res.isNotEmpty) {
    debugPrint(res);
    return null;
  } else {
    return ok;
  }
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
      if (v.wantItems.contains(url)) {
        v = v.copyWith(
            wantItems: v.wantItems.where((element) => element != url).toSet());
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

  makeWanted(String url, {bool reverse = false}) async {
    s ??= await SharedPreferences.getInstance();
    var v = state.value;
    if (v == null) return;
    if (!reverse) {
      v = v.copyWith(wantItems: {url, ...v.wantItems});
    } else {
      v = v.copyWith(
          wantItems: v.wantItems.where((element) => element != url).toSet());
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

@riverpod
Future<(List<Movie>, String)> getMovies(GetMoviesRef ref) async {
  final (showTv, showHot) = await ref.watch(
      movieSettingsProvider.selectAsync((data) => (data.showTv, data.showHot)));
  final r = await get(
      Uri.parse(
          Config.movieUrl(showTv ? "tv" : "movie", showHot ? "hot" : "new")),
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
class MovieFilter with _$MovieFilter {
  const factory MovieFilter(
      {@Default(0.0) double avgStar,
      @Default(0.0) double selectStar,
      @Default(true) bool showWatched,
      @Default(true) bool showTracked,
      @Default(true) bool showIgnored,
      @Default(false) bool hideWant,
      @Default(true) bool useSort,
      @Default({}) Set<String> allTags,
      @Default({}) Set<String> selectTags,
      @Default(0) int update}) = _MovieFilter;
  factory MovieFilter.fromJson(Map<String, dynamic> json) =>
      _$MovieFilterFromJson(json);
}

@riverpod
class MovieFilters extends _$MovieFilters {
  @override
  MovieFilter build() {
    final movies = ref.watch(getMoviesProvider).value?.$1;
    final lastFilter = ref.watch(
        movieSettingsProvider.select((value) => value.value?.lastFilter));
    if (movies == null) return stateOrNull ?? const MovieFilter();
    var avgStar = 0.0;
    var tags = <String>{};
    for (final m in movies) {
      avgStar += double.tryParse(m.star ?? "") ?? 0.0;
      if (!(m.update?.startsWith("第") ?? false) && m.update != null) {
        tags.add(m.update!);
      }
    }
    avgStar /= movies.length;

    if ((lastFilter?.update ?? 0) > (stateOrNull?.update ?? 0)) {
      return MovieFilter(
          avgStar: avgStar,
          allTags: tags,
          selectStar: lastFilter?.selectStar ?? 0.0,
          selectTags: tags.intersection(lastFilter?.selectTags ?? {}),
          showWatched: lastFilter?.showWatched ?? true,
          showTracked: lastFilter?.showTracked ?? true,
          showIgnored: lastFilter?.showIgnored ?? true,
          update: DateTime.now().millisecondsSinceEpoch);
    } else {
      return MovieFilter(
          avgStar: avgStar,
          allTags: tags,
          selectStar: stateOrNull?.selectStar ?? 0.0,
          selectTags: tags.intersection(stateOrNull?.selectTags ?? {}),
          showWatched: stateOrNull?.showWatched ?? true,
          showTracked: stateOrNull?.showTracked ?? true,
          showIgnored: stateOrNull?.showIgnored ?? true,
          update: DateTime.now().millisecondsSinceEpoch);
    }
  }

  setShowWatched(bool show) async {
    state = state.copyWith(
        showWatched: show, update: DateTime.now().millisecondsSinceEpoch);
  }

  setShowIgnored(bool show) async {
    state = state.copyWith(
        showIgnored: show, update: DateTime.now().millisecondsSinceEpoch);
  }

  setHideWant(bool want) async {
    state = state.copyWith(
        hideWant: want, update: DateTime.now().millisecondsSinceEpoch);
  }

  setUseSort(bool yes) async {
    state = state.copyWith(
        useSort: yes, update: DateTime.now().millisecondsSinceEpoch);
  }

  setShowTracked(bool show) async {
    state = state.copyWith(
        showTracked: show, update: DateTime.now().millisecondsSinceEpoch);
  }

  setStar(double star) {
    state = state.copyWith(
        selectStar: star, update: DateTime.now().millisecondsSinceEpoch);
  }

  cleanSelectTags() {
    state = state.copyWith(
        selectTags: {}, update: DateTime.now().millisecondsSinceEpoch);
  }

  toggleTag(String tag) {
    var tags = state.selectTags;
    if (tags.contains(tag)) {
      tags = tags.where((element) => element != tag).toSet();
    } else {
      tags = {tag, ...tags};
    }
    state = state.copyWith(
        selectTags: tags, update: DateTime.now().millisecondsSinceEpoch);
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
  final watched = {...setting.watchedMovie, ...setting.watchedTv};
  final ignored = setting.ignoreItems;
  final wanted = setting.wantItems;
  var res = movie.$1.where((element) {
    if (!filter.showWatched && watched.contains(element.url)) {
      return false;
    }
    if (!filter.showTracked && track.contains(element.url)) {
      return false;
    }
    if (!filter.showIgnored && ignored.contains(element.url)) {
      return false;
    }
    if (filter.hideWant && wanted.contains(element.url)) {
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
  if (filter.useSort) {
    res.sort((a, b) {
      final aw = wanted.contains(a.url);
      final bw = wanted.contains(b.url);
      if (aw && bw) {
        return b.star?.compareTo(a.star ?? "") ?? 0;
      } else if (aw) {
        return -10;
      } else if (bw) {
        return 10;
      } else {
        return b.star?.compareTo(a.star ?? "") ?? 0;
      }
    });
  }
  return res;
}
