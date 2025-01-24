// ignore_for_file: invalid_annotation_target

import 'package:cyberme_flutter/pocket/viewmodels/basic.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'expired.freezed.dart';
part 'expired.g.dart';

@freezed
class ExpiredItems with _$ExpiredItems {
  factory ExpiredItems({
    @Default([]) List<String> token,
    @Default([]) List<String> server,
    @Default([]) List<String> cert,
    @Default([]) List<String> registry,
    @JsonKey(name: "daywork") @Default([]) List<String> dayWork,
  }) = _ExpiredItems;

  factory ExpiredItems.fromJson(Map<String, dynamic> json) =>
      _$ExpiredItemsFromJson(json);
}

extension ExpiredItemsX on ExpiredItems {
  bool get isEmpty =>
      token.isEmpty &&
      server.isEmpty &&
      cert.isEmpty &&
      registry.isEmpty &&
      dayWork.isEmpty;
}

@riverpod
FutureOr<ExpiredItems> getExpiredItems(Ref ref, {bool force = false}) async {
  try {
    final res = await requestFrom("/cyber/service/expired?force=$force&days=15",
        (item) => ExpiredItems.fromJson(item));
    return res.$1 ?? ExpiredItems();
  } catch (e, st) {
    debugPrintStack(stackTrace: st);
    return ExpiredItems();
  }
}

Future<String> markDayWorkFinished({bool reverse = false}) async {
  final res = await postFrom(
      "/cyber/dashboard/day-work", {"status": reverse ? null : "已完成日报"});
  return res.$2;
}
