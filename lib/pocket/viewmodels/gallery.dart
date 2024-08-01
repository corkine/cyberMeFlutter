import 'dart:convert';

import 'package:cyberme_flutter/pocket/viewmodels/basic.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config.dart';

part 'gallery.freezed.dart';
part 'gallery.g.dart';

@freezed
class GalleryData with _$GalleryData {
  factory GalleryData(
      {@Default(0.7) double blurOpacity,
      @Default(0.3) double blurOpacityInBgMode,
      @Default(25) double borderRadius,
      @Default(5) int imageRepeatEachMinutes,
      @Default(5) int configRefreshMinutes,
      @Default([]) List<String> images, //已选择的图片
      @Default([]) List<String> imagesAll //所有的图片
      }) = _GalleryData;

  factory GalleryData.fromJson(Map<String, dynamic> json) =>
      _$GalleryDataFromJson(json);
}

@riverpod
class Gallerys extends _$Gallerys {
  static const apiKey = "gallery";
  @override
  FutureOr<GalleryData> build() async {
    //final res = await settingFetch(apiKey, GalleryData.fromJson);
    try {
      final req = await get(
          Uri.parse("https://mazhangjing.com/service/screenMe/gallery.json"));
      final res = GalleryData.fromJson(jsonDecode(req.body));
      return res;
    } catch (e, st) {
      debugPrintStack(label: "gallery", stackTrace: st);
      return GalleryData();
    }
  }

  void makeMemchange(GalleryData newData) {
    state = AsyncData(newData);
  }

  Future<String> rewrite(GalleryData data) async {
    //await settingUpload(apiKey, data.toJson());
    const url = "$endpoint/cyber/service/gallery";
    debugPrint("request from $url update oss $data");
    final r = await post(Uri.parse(url),
        headers: config.cyberBase64JsonContentHeader,
        body: jsonEncode(data.toJson()));
    final d = jsonDecode(r.body);
    debugPrint("request from $url, response: $d");
    final res = d["message"]?.toString() ?? "未知错误";
    ref.invalidateSelf();
    return res;
  }
}
