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
    @Default("") String note,
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

@freezed
class PsychNotes with _$PsychNotes {
  factory PsychNotes({@Default({}) Map<String, String> notes}) = _PsychNotes;

  factory PsychNotes.fromJson(Map<String, dynamic> json) =>
      _$PsychNotesFromJson(json);
}

@riverpod
class PsychNoteDb extends _$PsychNoteDb {
  final tag = "psych-notes";
  @override
  FutureOr<PsychNotes> build() async {
    final a = await settingFetch(tag, (item) => PsychNotes.fromJson(item));
    return a ?? PsychNotes();
  }

  Future<String> addNote(int id, String note) async {
    final res = {...((state.value ?? PsychNotes()).notes), id.toString(): note};
    await settingUpload(tag, PsychNotes(notes: res).toJson());
    state = AsyncData(state.value!.copyWith(notes: res));
    return "OK";
  }

  Future<String> delNote(int id) async {
    final res = {...(state.value?.notes ?? {})};
    res.remove(id.toString());
    await settingUpload(tag, PsychNotes(notes: res).toJson());
    state = AsyncData(state.value!.copyWith(notes: res));
    return "OK";
  }
}

@riverpod
List<PsychItem> fetchPsychItems(FetchPsychItemsRef ref) {
  final notes = ref.watch(psychNoteDbProvider).value?.notes ?? {};
  final items = ref.watch(psychDbProvider).value?.items ?? [];
  return items
      .map((item) => item.copyWith(note: notes[item.id.toString()] ?? ""))
      .toList();
}

@riverpod
class PsychDb extends _$PsychDb {
  final step = 200;
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

  Future<PsychItem> fetchOne(int id) async {
    final res =
        await requestFrom("/cyber/service/psych-cases/$id", PsychItem.fromJson);
    if (res.$1 != null) {
      state = AsyncData(state.value!.copyWith(
          items: state.value!.items
              .map((item) => item.id == id ? res.$1! : item)
              .toList()));
    }
    return res.$1 ?? PsychItem();
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
