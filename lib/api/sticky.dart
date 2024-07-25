import 'package:cyberme_flutter/api/basic.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sticky.freezed.dart';
part 'sticky.g.dart';

@freezed
class StickyNoteItem with _$StickyNoteItem {
  factory StickyNoteItem({
    @Default("") String id,
    @Default("") String title,
    @Default("") String body,
    @Default("") String create,
    @Default("") String update,
    @Default("") String url,
  }) = _StickyNoteItem;

  factory StickyNoteItem.fromJson(Map<String, dynamic> json) =>
      _$StickyNoteItemFromJson(json);
}

@riverpod
class StickyNotes extends _$StickyNotes {
  @override
  FutureOr<List<StickyNoteItem>> build() async {
    final res = await requestFromList("/cyber/todo/note",
        (i) => i.map((e) => StickyNoteItem.fromJson(e)).toList());
    return res.$1 ?? [];
  }

  Future<String> forceUpdate() async {
    final res = await requestFromList("/cyber/todo/note?force=true",
        (i) => i.map((e) => StickyNoteItem.fromJson(e)).toList());
    state = AsyncData(res.$1 ?? []);
    return "已同步最新数据";
  }
}
