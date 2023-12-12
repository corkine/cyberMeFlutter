import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

import '../pocket/config.dart';

const endpoint = "https://cyber.mazhangjing.com";

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

Future<(T?, String)> requestFromList<T>(
    String path, T Function(List<dynamic>) func) async {
  try {
    final url = "$endpoint$path";
    debugPrint("request from $url");
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
