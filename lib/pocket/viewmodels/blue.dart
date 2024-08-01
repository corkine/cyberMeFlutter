// ignore_for_file: invalid_annotation_target
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'basic.dart';

part 'blue.freezed.dart';
part 'blue.g.dart';

SharedPreferences? sp;

@freezed
class BlueData with _$BlueData {
  const factory BlueData({
    required String title,
    String? note,
    required int timestamp,
    required int point,
    int? seconds,
  }) = _BlueData;

  factory BlueData.fromJson(Map<String, dynamic> json) =>
      _$BlueDataFromJson(json);
}

@freezed
class BlueRecent with _$BlueRecent {
  const factory BlueRecent(
      {required String id,
      required String date,
      BlueData? info,
      required int point,
      @JsonKey(name: "create_at") required String createAt,
      @JsonKey(name: "update_at") required String updateAt}) = _BlueRecent;

  factory BlueRecent.fromJson(Map<String, dynamic> json) =>
      _$BlueRecentFromJson(json);
}

@riverpod
class Blues extends _$Blues {
  @override
  Future<Map<String, List<BlueRecent>>> build() async {
    final (data, msg) = await requestFromList("/cyber/blue/recent",
        (l) => l.map((e) => BlueRecent.fromJson(e)).toList());
    if (data == null) {
      debugPrint("get blue data failed: $msg");
      return {};
    }
    debugPrint(data.toString());
    var res = <String, List<BlueRecent>>{};
    for (var i in data) {
      if (res[i.date] == null) {
        res[i.date] = [i];
      } else {
        res[i.date]!.add(i);
      }
    }
    return res;
  }

  addBlue(BlueData data) async {
    final ts = data.timestamp;
    final ymd =
        DateFormat.yMd().format(DateTime.fromMillisecondsSinceEpoch(ts));
    final (success, msg) =
        await postFrom("/cyber/blue/add", {...data.toJson(), "date": ymd});
    if (!success) {
      debugPrint("add blue data failed: $msg");
    } else {
      ref.invalidateSelf();
    }
  }

  deleteBlue(String id) async {
    final (success, msg) = await postFrom("/cyber/blue/delete", {"id": id});
    if (!success) {
      debugPrint("delete blue data failed: $msg");
    } else {
      ref.invalidateSelf();
    }
  }
}
