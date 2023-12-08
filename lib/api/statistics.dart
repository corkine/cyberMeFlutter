import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../pocket/config.dart';

part 'statistics.g.dart';

part 'statistics.freezed.dart';

const _endpoint = "https://cyber.mazhangjing.com";

Future<(T?, String)> requestFrom<T>(
    String path, T Function(Map<String, dynamic>) func) async {
  try {
    final url = "$_endpoint$path";
    //debugPrint("request from $url");
    final r = await get(Uri.parse(url), headers: config.cyberBase64Header);
    final d = jsonDecode(r.body);
    final code = (d["status"] as int?) ?? -1;
    if (code <= 0) return (null, d["message"]?.toString() ?? "未知错误");
    final originData = d["data"];
    //debugPrint("request from $url, data: $originData");
    return (func(originData), "");
  } catch (e, st) {
    debugPrintStack(stackTrace: st);
    return (null, e.toString());
  }
}

@freezed
class Statistics with _$Statistics {
  const factory Statistics({
    @Default("0") String dashboard,
    @Default("0") String client,
    @Default("0") String go,
    @Default("0") String story,
    @Default("0") String task,
    @Default("0") String psych,
  }) = _Stastics;

  factory Statistics.fromJson(Map<String, dynamic> json) =>
      _$StatisticsFromJson(json);
}

@riverpod
Future<(Statistics?, String)> getStatistics(GetStatisticsRef res) async {
  final data = await requestFrom("/api/usage", Statistics.fromJson);
  return data;
}

@freezed
class ServiceStatus with _$ServiceStatus {
  const factory ServiceStatus(
      {String? suggestVersion,
      @Default(false) bool endOfSupport,
      String? serviceName,
      String? endOfSupportMessage,
      String? version,
      String? path,
      @Default([]) List<String> logs}) = _ServiceStatus;

  factory ServiceStatus.fromJson(Map<String, dynamic> json) =>
      _$ServiceStatusFromJson(json);
}

@riverpod
Future<(List<ServiceStatus>, String)> getServiceStatus(
    GetServiceStatusRef res) async {
  final data = await requestFrom(
      "/cyber/service/all",
      (m) => m
          .map((key, value) =>
              MapEntry(key, ServiceStatus.fromJson(value).copyWith(path: key)))
          .values
          .toList());
  return (data.$1 ?? [], data.$2);
}

Future<String> setServiceStatus(String svcPath, bool support) async {
  try {
    const url = "$_endpoint/cyber/service/change";
    debugPrint("request from $url A$svcPath B$support");
    final r = await post(Uri.parse(url),
        headers: config.cyberBase64JsonContentHeader,
        body: jsonEncode({"key": svcPath, "support": support}));
    final d = jsonDecode(r.body);
    debugPrint("request from $url, data: $d");
    return d["message"]?.toString() ?? "未知错误";
  } catch (e, st) {
    debugPrintStack(stackTrace: st);
    return e.toString();
  }
}