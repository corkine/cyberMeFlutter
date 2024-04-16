// ignore_for_file: invalid_annotation_target

import 'dart:convert';

import 'package:cyberme_flutter/api/basic.dart';
import 'package:cyberme_flutter/pocket/app/ticket.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

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

  // 添加一个发行版，返回消息和地址
  Future<(String, String)> addDistroUrl(String noteUrl, DateTime time) async {
    final info = await DistroInfo.parse(noteUrl);
    if (info == null) return ("解析 Release 失败", "");
    final appName = info.name + " " + info.version;
    final downloadUrl = info.url;
    if (downloadUrl.isEmpty) return ("未获取到下载地址，请检查后重试", "");
    final keyword = "dist-" + const Uuid().v4().substring(0, 4);
    final date = DateFormat("yyyy-MM-dd HH:mm").format(time);
    final data = Uri.encodeComponent(
        jsonEncode({"name": appName, "url": downloadUrl, "date": date}));
    final targetUrl =
        "https://mazhangjing.com/distro/?go=${base64Encode(utf8.encode(data))}";
    //debugPrint(targetUrl);
    final res = await add(keyword, targetUrl);
    return (res, "https://go.mazhangjing.com/$keyword");
  }
}

class DistroInfo {
  final String name;
  final String url;
  final String version;

  DistroInfo({required this.name, required this.url, required this.version});
  static Future<DistroInfo?> parse(String noteUrl) async {
    try {
      final data = jsonDecode((await get(Uri.parse(noteUrl))).body);
      final mayDownloadUrl = data["download"]["current"].toString();
      final version = data["currentVersion"];
      final name = mayDownloadUrl
          .split("/")
          .last
          .replaceAll(".zip", "")
          .replaceAll("_", " ");
      return DistroInfo(name: name, url: mayDownloadUrl, version: version);
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
      return null;
    }
  }
}
