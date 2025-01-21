// ignore_for_file: invalid_annotation_target

import 'package:cyberme_flutter/pocket/viewmodels/basic.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'serverless.freezed.dart';
part 'serverless.g.dart';

@freezed
class ServiceItem with _$ServiceItem {
  factory ServiceItem({
    @Default("") String name,
    @Default("") String content,
    @Default("") String description,
    @JsonKey(name: "created_at") @Default("") String createdAt,
    @JsonKey(name: "updated_at") @Default("") String updatedAt,
    dynamic info,
  }) = _ServiceItem;

  factory ServiceItem.fromJson(Map<String, dynamic> json) =>
      _$ServiceItemFromJson(json);
}

@riverpod
class ServerlessDb extends _$ServerlessDb {
  @override
  FutureOr<List<ServiceItem>> build() async {
    final res = await requestFromList("/cyber/service/funcs",
        (items) => items.map((e) => ServiceItem.fromJson(e)).toList());
    return res.$1 ?? [];
  }

  Future<ServiceItem?> getByName(String name) async {
    final res = await requestFrom(
        "/cyber/service/func/$name?json=true", (e) => ServiceItem.fromJson(e));
    return res.$1;
  }

  Future<String> addOrUpdate(ServiceItem item) async {
    final res =
        await postFrom("/cyber/service/func/${item.name}", item.toJson());
    return res.$2;
  }

  Future<String> delete(String name) async {
    final res = await deleteFrom("/cyber/service/func/$name", {});
    return res.$2;
  }
}
