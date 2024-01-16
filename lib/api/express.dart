// ignore_for_file: invalid_annotation_target

import 'package:cyberme_flutter/api/basic.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'express.freezed.dart';
part 'express.g.dart';

@freezed
class ExpressExtra with _$ExpressExtra {
  factory ExpressExtra({@Default("") String time, @Default("") String status}) =
      _ExpressExtra;

  factory ExpressExtra.fromJson(Map<String, dynamic> json) =>
      _$ExpressExtraFromJson(json);
}

extension ExpressExtraTime on ExpressExtra {
  get timeReadable {
    final t = time;
    if (t.isEmpty) return "";
    final d = DateTime.parse(t);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final beforeYesterday = DateTime(now.year, now.month, now.day - 2);
    final hm = DateFormat("HH:mm");
    final yhm = DateFormat("yyyy-MM-dd HH:mm");
    if (d.isAfter(today)) {
      return "今天 ${hm.format(d)}";
    } else if (d.isAfter(yesterday)) {
      return "昨天 ${hm.format(d)}";
    } else if (d.isAfter(beforeYesterday)) {
      return "前天 ${hm.format(d)}";
    } else {
      return yhm.format(d);
    }
  }
}

@freezed
class ExpressItem with _$ExpressItem {
  factory ExpressItem({
    @Default("") String id,
    @Default("") String name,
    @Default(-1) int status,
    @JsonKey(name: "last_update") @Default("") String lastUpdate,
    @Default("") String info,
    @Default([]) List<ExpressExtra> extra,
  }) = _ExpressItem;

  factory ExpressItem.fromJson(Map<String, dynamic> json) =>
      _$ExpressItemFromJson(json);
}

@riverpod
class Expresses extends _$Expresses {
  @override
  FutureOr<List<ExpressItem>> build() async {
    final (res, ok) = await requestFromList("/cyber/express/recent",
        (d) => d.map((e) => ExpressItem.fromJson(e)).toList(growable: false));
    if (ok.isNotEmpty) {
      debugPrint(ok);
    }
    return res ?? [];
  }
}
