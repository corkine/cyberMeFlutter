import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pocket/config.dart';

part 'story.freezed.dart';
part 'story.g.dart';

/// 最后阅读故事退出的时间以及阅读的段落值
@freezed
class LastReadStory with _$LastReadStory {
  factory LastReadStory({
    @Default("") String name,
    @Default(0) int enter,
    @Default(0) int exit,
    @Default(0) double index,
  }) = _LastReadStory;

  factory LastReadStory.fromJson(Map<String, dynamic> json) =>
      _$LastReadStoryFromJson(json);
}

@freezed
class StoryConfig with _$StoryConfig {
  factory StoryConfig({
    @Default({}) Map<String, LastReadStory> lastRead,
    @Default({}) Set<String> favoriteStory,
  }) = _StoryConfig;

  factory StoryConfig.fromJson(Map<String, dynamic> json) =>
      _$StoryConfigFromJson(json);
}

/// 保存最后阅读故事和收藏的故事
@Riverpod(keepAlive: true)
class StoryConfigs extends _$StoryConfigs {
  static const persistKey = "storyConfig";
  @override
  FutureOr<StoryConfig> build() async {
    final s = await SharedPreferences.getInstance();
    return StoryConfig.fromJson(jsonDecode(s.getString(persistKey) ?? "{}"));
  }

  LastReadStory? getLastRead(String bookName) {
    return state.value?.lastRead[bookName];
  }

  static bool isFavoriate(Set<String>? set, String bookName, String storyName) {
    return set?.contains(bookName + "::$storyName") ?? false;
  }

  Future<String> setFavorite(
      String bookName, String favoriateName, bool isFavorite) async {
    final key = "$bookName::$favoriateName";
    final oldState = state.value ?? StoryConfig();
    final now = oldState.copyWith(
        favoriteStory: isFavorite
            ? {...oldState.favoriteStory, key}
            : ({...oldState.favoriteStory}..remove(key)));
    final s = await SharedPreferences.getInstance();
    await s.setString(persistKey, jsonEncode(now));
    state = AsyncData(now);
    return "已成功保存配置";
  }

  Future<String> setLastRead(String bookName, LastReadStory lastRead) async {
    final s = await SharedPreferences.getInstance();
    final now = (state.value ?? StoryConfig()).copyWith(
        lastRead: {...state.value?.lastRead ?? {}, bookName: lastRead});
    await s.setString(persistKey, jsonEncode(now));
    state = AsyncData(now);
    return "已成功保存配置";
  }
}

@freezed
class BookItem with _$BookItem {
  factory BookItem(
      {@Default("") String name,
      @Default(0) int count,
      @Default(false) bool isFavorite}) = _BookItem;

  factory BookItem.fromJson(Map<String, dynamic> json) =>
      _$BookItemFromJson(json);
}

@freezed
class BookItems with _$BookItems {
  factory BookItems(
      {@Default([]) List<BookItem> items,
      LastReadStory? lastRead}) = _BookItems;

  factory BookItems.fromJson(Map<String, dynamic> json) =>
      _$BookItemsFromJson(json);
}

/// 获取书籍各故事的字数、整合其是否收藏的信息
@riverpod
Future<BookItems> bookInfos(BookInfosRef ref, String bookName) async {
  final cfg = ref.watch(storyConfigsProvider).value ?? StoryConfig();
  final fav = cfg.favoriteStory;
  final r = await get(Uri.parse(Config.storyBookUrl(bookName)),
      headers: config.cyberBase64Header);
  final j = jsonDecode(r.body);
  final s = (j["status"] as int?) ?? -1;
  final m = j["message"] ?? "没有返回消息";
  final d = (j["data"] as List?) ?? [];
  final refer = (j["count"] as Map<String, dynamic>? ?? {})
      .map((key, value) => MapEntry(key, value as int? ?? 0));
  if (s <= 0) {
    debugPrint("error fetch bookInfo: $bookName, $m");
  }
  return BookItems(
      items: (d.map((e) {
        final storyName = e as String;
        final count = refer[storyName] ?? 0;
        final isFav = fav.contains("$bookName::$storyName");
        return BookItem(name: storyName, count: count, isFavorite: isFav);
      }).toList()
        ..sort((item1, item2) {
          if (item1.isFavorite != item2.isFavorite) {
            if (item1.isFavorite) {
              return -1;
            } else {
              return 1;
            }
          }
          return 0;
        })),
      lastRead: cfg.lastRead[bookName]);
}
