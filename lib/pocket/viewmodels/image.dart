// ignore_for_file: invalid_annotation_target

import 'package:cyberme_flutter/pocket/viewmodels/basic.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'image.freezed.dart';
part 'image.g.dart';

@freezed
class Registry with _$Registry {
  factory Registry({
    @Default("") String note,
    @Default("") String url,
    @JsonKey(name: "manage-url") @Default("") String manageUrl,
    @Default("") String user,
    @Default("") String id,
  }) = _Registry;

  factory Registry.fromJson(Map<String, dynamic> json) =>
      _$RegistryFromJson(json);
}

@freezed
class Container1 with _$Container1 {
  factory Container1(
      {@Default("") String id,
      @Default("") String note,
      @Default("") String namespace,
      @Default({}) Map<String, Tag> tags}) = _Container1;

  factory Container1.fromJson(Map<String, dynamic> json) =>
      _$Container1FromJson(json);
}

@freezed
class Tag with _$Tag {
  factory Tag({
    @Default("") String id,
    @Default([]) List<String> registry,
    @Default("") String note,
  }) = _Tag;

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);
}

@freezed
class Images with _$Images {
  factory Images({
    @Default({}) Map<String, Registry> registry,
    @Default({}) Map<String, Map<String, Container1>> images,
  }) = _Images;

  factory Images.fromJson(Map<String, dynamic> json) => _$ImagesFromJson(json);
}

@riverpod
class ImageDb extends _$ImageDb {
  static const tag = "registry";
  @override
  FutureOr<Images> build() async {
    final res = await settingFetch(tag, (d) {
      final r = Images.fromJson(d);
      return r;
    });
    return res ?? Images();
  }

  Future<String> editRegistry(Registry registry) async {
    return "更新仓库成功";
  }

  Future<String> deleteRegistry(String registryId) async {
    final images = state.value;
    if (images == null) return "未找到数据";
    final newRegistry = {...images.registry};
    newRegistry.remove(registryId);
    state = AsyncData(images.copyWith(registry: newRegistry));
    return "删除仓库成功";
  }

  Future<String> editContainer(Container1 container) async {
    return "更新镜像成功";
  }

  Future<String> deleteContainer(Container1 container) async {
    final images = state.value;
    final nsId = container.namespace;
    if (images == null) return "未找到数据";
    if (nsId.isEmpty) return "命名空间不能为空";
    final oldNsImages = images.images[nsId] ?? {};
    oldNsImages.remove(container.id);
    final newNsImages = {...images.images, nsId: oldNsImages};
    state = AsyncData(images.copyWith(images: newNsImages));
    return "删除镜像成功";
  }
}

@riverpod
Future<List<Registry>> getRegistry(GetRegistryRef ref) async {
  final res =
      await ref.watch(imageDbProvider.selectAsync((data) => data.registry));
  List<Registry> list = [];
  for (var item in res.entries) {
    list.add(item.value.copyWith(id: item.key));
  }
  return list;
}

@riverpod
Future<List<Container1>> getContainer(GetContainerRef ref) async {
  final res =
      await ref.watch(imageDbProvider.selectAsync((data) => data.images));
  List<Container1> list = [];
  for (var item in res.entries) {
    for (var item2 in item.value.entries) {
      list.add(item2.value.copyWith(id: item2.key, namespace: item.key));
    }
  }
  return list;
}
