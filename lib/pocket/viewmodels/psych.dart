// ignore_for_file: invalid_annotation_target

import 'package:cyberme_flutter/pocket/viewmodels/basic.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'psych.freezed.dart';
part 'psych.g.dart';

@freezed
class PsychItem with _$PsychItem {
  factory PsychItem({
    @Default(0) int id,
    @Default("") String kind,
    @Default({}) Map<String, dynamic> info,
    @JsonKey(name: "create_at") @Default("") String createAt,
    @Default("") String url,
  }) = _PsychItem;

  factory PsychItem.fromJson(Map<String, dynamic> json) =>
      _$PsychItemFromJson(json);
}

@freezed
class PsychItems with _$PsychItems {
  factory PsychItems({
    @Default([]) List<PsychItem> items,
    @Default(0) int take,
    @Default(0) int drop,
  }) = _PsychItems;
}

@riverpod
class PsychDb extends _$PsychDb {
  final step = 30;
  @override
  FutureOr<PsychItems> build() async {
    return PsychItems(items: await fetch(step, 0), take: step, drop: 0);
  }

  Future<List<PsychItem>> fetch(int take, int drop) async {
    return (await requestFromList(
                "/cyber/service/psych-cases?take=$take&drop=$drop",
                (l) => l.map((e) => PsychItem.fromJson(e)).toList()))
            .$1 ??
        [];
  }

  Future<String> next() async {
    final dropNow = state.value!.drop + step;
    final newState = PsychItems(
        items: [...state.value!.items, ...await fetch(step, dropNow)],
        take: step,
        drop: dropNow);
    state = AsyncData(newState);
    return "OK";
  }
}
