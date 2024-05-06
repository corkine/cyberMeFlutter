import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  }) = _StoryConfig;

  factory StoryConfig.fromJson(Map<String, dynamic> json) =>
      _$StoryConfigFromJson(json);
}

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

  Future<String> setLastRead(String bookName, LastReadStory lastRead) async {
    final s = await SharedPreferences.getInstance();
    final now = (state.value ?? StoryConfig()).copyWith(
        lastRead: {...state.value?.lastRead ?? {}, bookName: lastRead});
    await s.setString(persistKey, jsonEncode(now));
    state = AsyncData(now);
    return "已成功保存配置";
  }
}
