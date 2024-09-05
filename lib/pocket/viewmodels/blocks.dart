import 'package:cyberme_flutter/pocket/viewmodels/basic.dart';
import 'package:cyberme_flutter/pocket/views/info/disaptch.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'blocks.freezed.dart';
part 'blocks.g.dart';

@freezed
class BlockItem with _$BlockItem {
  factory BlockItem({
    @Default("") String id,
    @Default("") String title,
    @Default("") String content,
    @Default(false) bool isReference,
    @Default([]) List<String> tags,
    @Default(0) int lastUpdate,
    @Default(0) int createDate,
  }) = _BlockItem;

  factory BlockItem.fromJson(Map<String, dynamic> json) =>
      _$BlockItemFromJson(json);
}

@riverpod
class BlocksDb extends _$BlocksDb {
  static const tag = "blocks";
  @override
  FutureOr<Map<String, BlockItem>> build() async {
    final res = await settingFetch(tag, (m) {
      m.remove("update");
      return m.map((k, v) => MapEntry(k, BlockItem.fromJson(v)));
    });
    return res ?? {};
  }

  Future<String> addOrUpdate(BlockItem item) async {
    final newState = {...state.value!, item.id: item};
    await settingUpload(tag, newState.map((k, v) => MapEntry(k, v.toJson())));
    state = AsyncData(newState);
    return "OK";
  }

  Future<String> delete(String id) async {
    final newState = {...state.value!};
    newState.remove(id);
    await settingUpload(tag, newState.map((k, v) => MapEntry(k, v.toJson())));
    state = AsyncData(newState);
    return "OK";
  }
}

@riverpod
List<BlockItem> getBlocksList(GetBlocksListRef ref, Set<String> tags) {
  final d = ref.watch(blocksDbProvider).value ?? {};
  return (d.values
      .where((d) => tags.isEmpty || d.tags.any((t) => tags.contains(t)))
      .toList())
    ..sort((a, b) => a.createDate.compareTo(b.createDate));
}

@riverpod
Set<String> getBlockTags(GetBlockTagsRef ref) {
  final d = ref.watch(blocksDbProvider).value ?? {};
  return d.values.map((i) => i.tags).expand((i) => i).toSet();
}

@riverpod
class SecretBlocksDb extends _$SecretBlocksDb {
  static const tag = "secret_blocks";
  @override
  FutureOr<Map<String, BlockItem>> build() async {
    final res = await settingFetch(tag, (m) {
      m.remove("update");
      return m.map((k, v) {
        final item = BlockItem.fromJson(v);
        return MapEntry(
            k,
            item.copyWith(
                tags: item.tags
                    .map((t) => SimpleEncryptor.decrypt(t) ?? t)
                    .toList(),
                title: SimpleEncryptor.decrypt(item.title) ?? item.title,
                content:
                    SimpleEncryptor.decrypt(item.content) ?? item.content));
      });
    });
    return res ?? {};
  }

  Future<String> addOrUpdate(BlockItem item) async {
    final newState = {...state.value!, item.id: item};
    await settingUpload(
        tag,
        newState.map((k, v) => MapEntry(
            k,
            v
                .copyWith(
                    tags:
                        v.tags.map((t) => SimpleEncryptor.encrypt(t)).toList(),
                    title: SimpleEncryptor.encrypt(v.title),
                    content: SimpleEncryptor.encrypt(v.content))
                .toJson())));
    state = AsyncData(newState);
    return "OK";
  }

  Future<String> delete(String id) async {
    final newState = {...state.value!};
    newState.remove(id);
    await settingUpload(tag, newState.map((k, v) => MapEntry(k, v.toJson())));
    state = AsyncData(newState);
    return "OK";
  }
}

@riverpod
List<BlockItem> getSecretBlocksList(
    GetSecretBlocksListRef ref, Set<String> tags) {
  final d = ref.watch(secretBlocksDbProvider).value ?? {};
  return (d.values
      .where((d) => tags.isEmpty || d.tags.any((t) => tags.contains(t)))
      .toList())
    ..sort((a, b) => a.createDate.compareTo(b.createDate));
}

@riverpod
Set<String> getSecretBlockTags(GetSecretBlockTagsRef ref) {
  final d = ref.watch(secretBlocksDbProvider).value ?? {};
  return d.values.map((i) => i.tags).expand((i) => i).toSet();
}
