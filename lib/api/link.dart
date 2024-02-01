// ignore_for_file: invalid_annotation_target

import 'package:cyberme_flutter/api/basic.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'link.freezed.dart';
part 'link.g.dart';

// ignore: slash_for_doc_comments
/**
 *    "id": 462,
      "keyword": "hello",
      "redirect_url": "https://baidu.com",
      "note": "Add by 快链 in AJAX - VUE",
      "update_time": "2022-02-07T06:47:48.868",
      "info": {}
 */

@freezed
class LinkSearch with _$LinkSearch {
  factory LinkSearch(
      {@Default("") String keyword,
      @Default(-1) int id,
      @Default("") @JsonKey(name: "redirect_url") String redirectUrl,
      @Default("note") String note,
      @Default("") @JsonKey(name: "update_time") String updateTime,
      @Default(null) dynamic info}) = _LinkSearch;

  factory LinkSearch.fromJson(Map<String, dynamic> json) =>
      _$LinkSearchFromJson(json);
}

@riverpod
class Links extends _$Links {
  @override
  Future<List<LinkSearch>> build(String searchKey) async {
    if (searchKey.isEmpty) return [];
    final (res, ok) = await requestFromList(
        "/cyber/go/$searchKey/json?log=false",
        (a) => a.map((e) => LinkSearch.fromJson(e)).toList(growable: false));
    if (ok.isNotEmpty) {
      debugPrint(ok);
    }
    return res ?? [];
  }

  Future<String> add(String keyword, String url,
      {bool override = false}) async {
    final (_, res) = await postFrom("/cyber/go/add", {
      "keyword": keyword,
      "redirectURL": url,
      "note": "由 CyberMe Flutter 添加：${DateTime.now()}",
      "override": override
    });
    ref.invalidateSelf();
    return res;
  }

  Future<String> delete(int id) async {
    final (_, res) = await postFrom("/cyber/go/delete/$id", {});
    ref.invalidateSelf();
    return res;
  }
}
