// ignore_for_file: invalid_annotation_target

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

/// 整个 App 保存的配置：每部故事书的最后阅读，所有待读的故事，所有已读的故事
@freezed
class StoryConfig with _$StoryConfig {
  factory StoryConfig({
    @Default({}) Map<String, LastReadStory> lastRead,
    @Default({}) Set<String> willReadStory,
    @Default({}) Set<String> readedStory,
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

  static bool isWillRead(Set<String>? set, String bookName, String storyName) {
    return set?.contains(readKey(bookName, storyName)) ?? false;
  }

  static bool isReaded(Set<String>? set, String bookName, String storyName) {
    return isWillRead(set, bookName, storyName);
  }

  static String readKey(String bookName, String storyName) {
    return bookName + "::$storyName";
  }

  Future<String> setWillRead(
      String bookName, String storyName, bool will) async {
    final key = readKey(bookName, storyName);
    final oldState = state.value ?? StoryConfig();
    final oldWillRead = oldState.willReadStory;
    final oldReaded = oldState.readedStory;
    final now = oldState.copyWith(
        readedStory: will ? ({...oldReaded}..remove(key)) : oldReaded,
        willReadStory:
            will ? {...oldWillRead, key} : ({...oldWillRead}..remove(key)));
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

  Future<String> removeLastRead(String bookName) async {
    final s = await SharedPreferences.getInstance();
    final now = (state.value ?? StoryConfig())
        .copyWith(lastRead: {...state.value?.lastRead ?? {}}..remove(bookName));
    await s.setString(persistKey, jsonEncode(now));
    state = AsyncData(now);
    return "已成功保存配置";
  }

  Future<String> setReaded(String bookName, String storyName,
      {required bool read}) async {
    final s = await SharedPreferences.getInstance();
    final key = readKey(bookName, storyName);
    final oldReaded = state.value?.readedStory ?? {};
    final willRead = state.value?.willReadStory ?? {};
    final now = (state.value ?? StoryConfig()).copyWith(
        readedStory: read ? {...oldReaded, key} : ({...oldReaded}..remove(key)),
        willReadStory: read ? ({...willRead}..remove(key)) : willRead);
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
      @Default(false) bool willRead,
      @Default(false) bool isReaded}) = _BookItem;

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
  final willReads = cfg.willReadStory;
  final isReadeds = cfg.readedStory;
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
        final key = StoryConfigs.readKey(bookName, storyName);
        final willRead = willReads.contains(key);
        final isReaded = isReadeds.contains(key);
        return BookItem(
            name: storyName,
            count: count,
            willRead: willRead,
            isReaded: isReaded);
      }).toList()
        ..sort((item1, item2) {
          var a = 0;
          var b = 0;
          if (item1.willRead) a += 10;
          if (item2.willRead) b += 10;
          if (item1.isReaded) a -= 100;
          if (item2.isReaded) b -= 100;
          return b - a;
        })),
      lastRead: cfg.lastRead[bookName]);
}

@freezed
class StorySearchItem with _$StorySearchItem {
  factory StorySearchItem(
      {@Default("") String book,
      @Default("") String story,
      @JsonKey(name: "book_en") @Default("") String bookEn,
      @Default([]) List<String> content,
      @Default(0.0) double score}) = _StorySearchItem;

  factory StorySearchItem.fromJson(Map<String, dynamic> json) =>
      _$StorySearchItemFromJson(json);
}

@freezed
class StorySearchResult with _$StorySearchResult {
  factory StorySearchResult(
      {@Default([]) List<StorySearchItem> result,
      @Default(0) int cost,
      @Default(0) int count}) = _StorySearchResult;

  factory StorySearchResult.fromJson(Map<String, dynamic> json) =>
      _$StorySearchResultFromJson(json);
}

@riverpod
Future<StorySearchResult> searchStory(SearchStoryRef ref, String query) async {
  try {
    final r = await post(Uri.parse(Config.storySearchUrl),
        headers: config.cyberBase64JsonContentHeader,
        body: jsonEncode(
            {"search": query, "cache": true, "batch": 20, "size": 20}));
    final j = jsonDecode(r.body);
    // final s = (j["status"] as int?) ?? -1;
    // final m = j["message"] ?? "没有返回消息";
    final d = j["data"] as Map<String, dynamic>? ?? {};
    final res = StorySearchResult.fromJson(d);
    return res;
  } catch (e, st) {
    debugPrintStack(stackTrace: st);
    return StorySearchResult(result: [], cost: 0, count: 0);
  }
}
