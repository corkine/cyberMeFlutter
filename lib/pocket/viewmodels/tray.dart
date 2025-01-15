import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../util.dart';

part 'tray.freezed.dart';
part 'tray.g.dart';

@freezed
class TrayItem with _$TrayItem {
  factory TrayItem(
      {@Default("") String id,
      @Default("") String name,
      @Default("") String url,
      @Default(true) bool isSink}) = _TrayItem;

  factory TrayItem.fromJson(Map<String, dynamic> json) =>
      _$TrayItemFromJson(json);
}

@riverpod
class TraySettings extends _$TraySettings {
  @override
  FutureOr<List<TrayItem>> build() async {
    return await readTraySettings();
  }

  addItem(String name, String url, bool isSink) {
    List<TrayItem> items = state.valueOrNull ?? [];
    state = AsyncData([
      ...items,
      TrayItem(name: name, url: url, isSink: isSink, id: const Uuid().v4())
    ]);
  }

  editItem(TrayItem newItem) {
    List<TrayItem> items = state.valueOrNull ?? [];
    state = AsyncData(
        items.map((item) => item.id == newItem.id ? newItem : item).toList());
  }

  deleteItem(String id) {
    List<TrayItem> items = state.valueOrNull ?? [];
    state = AsyncData(items.where((item) => item.id != id).toList());
  }

  Future<String> saveTraySettings() async {
    final items = state.valueOrNull ?? [];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
        'tray_items', items.map((item) => jsonEncode(item.toJson())).toList());
    if (Platform.isWindows || Platform.isMacOS) {
      await initSystemTray();
    }
    return "保存成功";
  }

  static Future<List<TrayItem>> readTraySettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? itemsJson = prefs.getStringList('tray_items');
    debugPrint("readTraySettings: $itemsJson");
    if (itemsJson == null) return [];
    return itemsJson
        .map((itemJson) => TrayItem.fromJson(jsonDecode(itemJson)))
        .toList();
  }
}
