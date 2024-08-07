import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

import '../config.dart';

const endpoint = kDebugMode
    ? "https://cyber.mazhangjing.com"
    : "https://cyber.mazhangjing.com";

Future<String> requestSimple(String path) async {
  try {
    final url = "$endpoint$path";
    final r = await get(Uri.parse(url), headers: config.cyberBase64Header);
    final d = jsonDecode(r.body);
    final code = (d["status"] as int?) ?? -1;
    return d["message"]?.toString() ?? "未知错误($code)";
  } catch (e, st) {
    debugPrintStack(stackTrace: st);
    return e.toString();
  }
}

Future<(T?, String)> requestFrom<T>(
    String path, T Function(Map<String, dynamic>) func) async {
  try {
    final url = "$endpoint$path";
    //debugPrint("request from $url");
    final r = await get(Uri.parse(url), headers: config.cyberBase64Header);
    final d = jsonDecode(r.body);
    final code = (d["status"] as int?) ?? -1;
    //debugPrint("request from $url, data: $d");
    if (code <= 0) return (null, d["message"]?.toString() ?? "未知错误");
    final originData = d["data"];
    return (func(originData), "");
  } catch (e, st) {
    debugPrintStack(stackTrace: st);
    return (null, e.toString());
  }
}

Future<(T?, String)> requestFromType<T, Y>(
    String path, T Function(Y) func) async {
  try {
    final url = "$endpoint$path";
    //debugPrint("request from $url");
    final r = await get(Uri.parse(url), headers: config.cyberBase64Header);
    final d = jsonDecode(r.body);
    final code = (d["status"] as int?) ?? -1;
    //debugPrint("request from $url, data: $d");
    if (code <= 0) return (null, d["message"]?.toString() ?? "未知错误");
    final originData = d["data"] as Y;
    return (func(originData), "");
  } catch (e, st) {
    debugPrintStack(stackTrace: st);
    return (null, e.toString());
  }
}

Future<(bool, String)> postFrom<T>(
    String path, Map<String, dynamic> data) async {
  try {
    final url = "$endpoint$path";
    final r = await post(Uri.parse(url),
        headers: config.cyberBase64JsonContentHeader, body: jsonEncode(data));
    final d = jsonDecode(r.body);
    final code = (d["status"] as int?) ?? -1;
    //debugPrint("request from $url, data: $d");
    final msg = d["message"]?.toString() ?? "未知错误";
    if (code <= 0) return (false, msg);
    //final originData = d["data"];
    return (true, msg);
  } catch (e, st) {
    debugPrintStack(stackTrace: st);
    return (false, e.toString());
  }
}

Future<(bool, String, dynamic)> postFromData<T>(
    String path, Map<String, dynamic> data) async {
  try {
    final url = "$endpoint$path";
    final r = await post(Uri.parse(url),
        headers: config.cyberBase64JsonContentHeader, body: jsonEncode(data));
    final d = jsonDecode(r.body);
    final code = (d["status"] as int?) ?? -1;
    //debugPrint("request from $url, data: $d");
    final msg = d["message"]?.toString() ?? "未知错误";
    if (code <= 0) return (false, msg, null);
    //final originData = d["data"];
    return (true, msg, d["data"]);
  } catch (e, st) {
    debugPrintStack(stackTrace: st);
    return (false, e.toString(), null);
  }
}

Future<(bool, String)> patchFrom<T>(
    String path, Map<String, dynamic> data) async {
  try {
    final url = "$endpoint$path";
    final r = await patch(Uri.parse(url),
        headers: config.cyberBase64JsonContentHeader, body: jsonEncode(data));
    final d = jsonDecode(r.body);
    final code = (d["status"] as int?) ?? -1;
    //debugPrint("request from $url, data: $d");
    final msg = d["message"]?.toString() ?? "未知错误";
    if (code <= 0) return (false, msg);
    //final originData = d["data"];
    return (true, msg);
  } catch (e, st) {
    debugPrintStack(stackTrace: st);
    return (false, e.toString());
  }
}

Future<(bool, String)> deleteFrom<T>(
    String path, Map<String, dynamic> data) async {
  try {
    final url = "$endpoint$path";
    final r = await delete(Uri.parse(url),
        headers: config.cyberBase64JsonContentHeader, body: jsonEncode(data));
    final d = jsonDecode(r.body);
    final code = (d["status"] as int?) ?? -1;
    //debugPrint("request from $url, data: $d");
    final msg = d["message"]?.toString() ?? "未知错误";
    if (code <= 0) return (false, msg);
    //final originData = d["data"];
    return (true, msg);
  } catch (e, st) {
    debugPrintStack(stackTrace: st);
    return (false, e.toString());
  }
}

Future<(T?, String)> requestFromList<T>(
    String path, T Function(List<dynamic>) func) async {
  try {
    final url = "$endpoint$path";
    //debugPrint("request from $url");
    final r = await get(Uri.parse(url), headers: config.cyberBase64Header);
    final d = jsonDecode(r.body);
    final code = (d["status"] as int?) ?? -1;
    //debugPrint("request from $url, data: $d");
    if (code <= 0) return (null, d["message"]?.toString() ?? "未知错误");
    final originData = d["data"];
    //debugPrint("data is $originData");
    return (func(originData), "");
  } catch (e, st) {
    debugPrintStack(stackTrace: st);
    return (null, e.toString());
  }
}

Future<T?> settingFetch<T>(
    String tag, T Function(Map<String, dynamic>) func) async {
  debugPrint("sync $tag with server $endpoint now");
  final (setting, msg) =
      await requestFrom("/cyber/service/common-setting/$tag", func);
  if (setting == null) {
    debugPrint("sync $tag setting failed: $msg");
    return null;
  }
  return setting;
}

settingUpload<T>(String tag, Map<String, dynamic>? state) async {
  debugPrint("upload $tag sync now");
  if (state == null) return;
  try {
    final (ok, msg) =
        await postFrom("/cyber/service/common-setting/$tag", state);
    if (!ok) {
      debugPrint("sync track setting failed: $msg");
      return;
    }
  } catch (e, tx) {
    debugPrintStack(stackTrace: tx, label: e.toString());
    return;
  }
}
