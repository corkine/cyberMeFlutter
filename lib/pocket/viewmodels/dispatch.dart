import 'package:cyberme_flutter/pocket/viewmodels/basic.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'dispatch.freezed.dart';
part 'dispatch.g.dart';

@freezed
class DispatchItem with _$DispatchItem {
  factory DispatchItem(
      {@Default("") String id,
      @Default("") String url,
      @Default("") String name,
      @Default("") String description}) = _DispatchItem;

  factory DispatchItem.fromJson(Map<String, dynamic> json) =>
      _$DispatchItemFromJson(json);
}

@riverpod
class DispatchDb extends _$DispatchDb {
  static const tag = "dispatch";
  @override
  FutureOr<List<DispatchItem>> build() async {
    final res = await settingFetch(tag, (a) {
      final d = a["dispatch"] as List<dynamic>?;
      if (d != null) return d.map((e) => DispatchItem.fromJson(e)).toList();
      return <DispatchItem>[];
    });
    return res ?? [];
  }

  Future<String> addOrUpdate(DispatchItem item) async {
    var old = [...?state.value];
    if (item.id.isEmpty) {
      old.add(item.copyWith(id: const Uuid().v4().toString()));
    } else {
      old = old.map((e) => e.id == item.id ? item : e).toList();
    }
    await settingUpload(tag, {"dispatch": old.map((e) => e.toJson()).toList()});
    state = AsyncData(old);
    return "OK";
  }
}
