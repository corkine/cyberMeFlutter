// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:cyberme_flutter/pocket/viewmodels/basic.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dns.freezed.dart';
part 'dns.g.dart';

@freezed
class DnsSetting with _$DnsSetting {
  factory DnsSetting(
      {@Default("") String cloudflareEmail,
      @Default("") String cloudflareApiKey,
      @Default(0) int cloudflareExpiredAt}) = _DnsSetting;

  factory DnsSetting.fromJson(Map<String, dynamic> json) =>
      _$DnsSettingFromJson(json);
}

@riverpod
class DnsSettingDb extends _$DnsSettingDb {
  static const tag = "dns";
  @override
  FutureOr<DnsSetting> build() async {
    final res = await settingFetch(tag, (v) => DnsSetting.fromJson(v));
    if (res != null) return res;
    return DnsSetting();
  }

  Future<String> save(DnsSetting data) async {
    await settingUpload(tag, data.toJson());
    return "Saved";
  }

  Future<String> removeRecord(String zoneId, String recordId) async {
    final setting = state.value!;
    if (setting.cloudflareEmail == "" || setting.cloudflareApiKey == "") {
      return "Please set your Cloudflare API Key first";
    }
    final res = await delete(
        Uri.parse(
            "https://api.cloudflare.com/client/v4/zones/$zoneId/dns_records/$recordId"),
        headers: {
          "X-Auth-Email": setting.cloudflareEmail,
          "X-Auth-Key": setting.cloudflareApiKey
        });
    final jb = jsonDecode(res.body);
    final code =
        res.statusCode == 200 ? true : (jb["success"] as bool? ?? false);
    if (code) {
      ref.invalidate(getZoneDnsProvider.call(zoneId));
    }
    return code ? "Success" : jb["errors"].toString();
  }

  Future<String> addRecord(String zoneId, Record record) async {
    final setting = state.value!;
    if (setting.cloudflareEmail == "" || setting.cloudflareApiKey == "") {
      return "Please set your Cloudflare API Key first";
    }
    final v = {
      "type": record.type,
      "name": record.name,
      "content": record.content,
      "comment": record.comment,
      "proxied": record.proxied,
    };
    final res = await post(
        Uri.parse(
            "https://api.cloudflare.com/client/v4/zones/$zoneId/dns_records"),
        headers: {
          "X-Auth-Email": setting.cloudflareEmail,
          "X-Auth-Key": setting.cloudflareApiKey,
          "Content-Type": "application/json"
        },
        body: jsonEncode(v));
    final jb = jsonDecode(res.body);
    final code = jb["success"] as bool? ?? false;
    if (code) {
      ref.invalidate(getZoneDnsProvider.call(zoneId));
    }
    return code ? "Success" : jb["errors"].toString();
  }

  Future<String> updateRecord(String zoneId, Record record) async {
    final setting = state.value!;
    if (setting.cloudflareEmail == "" || setting.cloudflareApiKey == "") {
      return "Please set your Cloudflare API Key first";
    }
    final v = {
      "type": record.type,
      "name": record.name,
      "content": record.content,
      "comment": record.comment,
      "proxied": record.proxied,
    };
    final res = await patch(
        Uri.parse(
            "https://api.cloudflare.com/client/v4/zones/$zoneId/dns_records/${record.id}"),
        headers: {
          "X-Auth-Email": setting.cloudflareEmail,
          "X-Auth-Key": setting.cloudflareApiKey,
          "Content-Type": "application/json"
        },
        body: jsonEncode(v));
    final jb = jsonDecode(res.body);
    final code = jb["success"] as bool? ?? false;
    if (code) {
      ref.invalidate(getZoneDnsProvider.call(zoneId));
    }
    return code ? "Success" : jb["errors"].toString();
  }
}

//https://developers.cloudflare.com/api

@freezed
class Zone with _$Zone {
  factory Zone(
      {@Default("") String id,
      @Default("") String name,
      @Default("") String status,
      @Default("") String type,
      @Default("") String original_registrar,
      @Default("") String modified_on,
      @Default("") String created_on,
      @Default("") String activated_on}) = _Zone;

  factory Zone.fromJson(Map<String, dynamic> json) => _$ZoneFromJson(json);
}

@freezed
class Record with _$Record {
  factory Record({
    @Default("") String comment,
    @Default("") String name,
    @Default(false) bool proxied,
    @Default(0) int ttl,
    @Default("A") String type,
    @Default("") String content,
    @Default("") String created_on,
    @Default("") String modified_on,
    @Default("") String id,
    @Default(true) bool proxiable,
  }) = _Record;

  factory Record.fromJson(Map<String, dynamic> json) => _$RecordFromJson(json);
}

(String, T?) parse<T>(Response res, Function parse) {
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    final msgs = (data["message"] as List<dynamic>? ?? []).join("\n");
    final success = data["success"] as bool;
    if (success) {
      final result = data["result"] as List<dynamic>? ?? [];
      try {
        return ("", parse(result));
      } catch (e, st) {
        debugPrintStack(stackTrace: st);
        return (e.toString(), null);
      }
    } else {
      debugPrint(msgs);
      return (msgs, null);
    }
  } else {
    return ("Status Code: ${res.statusCode}", null);
  }
}

@riverpod
FutureOr<(String, List<Zone>?)> getZone(GetZoneRef ref) async {
  final setting = await ref.read(dnsSettingDbProvider.future);
  if (setting.cloudflareEmail == "" || setting.cloudflareApiKey == "") {
    return ("Please set your Cloudflare Email and API Key", <Zone>[]);
  }
  final res = await get(Uri.parse("https://api.cloudflare.com/client/v4/zones"),
      headers: {
        "X-Auth-Email": setting.cloudflareEmail,
        "X-Auth-Key": setting.cloudflareApiKey
      });
  return parse<List<Zone>>(
      res,
      (body) =>
          (body as List<dynamic>? ?? []).map((e) => Zone.fromJson(e)).toList());
}

@riverpod
FutureOr<(String, List<Record>?)> getZoneDns(
    GetZoneDnsRef ref, String zoneId) async {
  final setting = await ref.read(dnsSettingDbProvider.future);
  if (setting.cloudflareEmail == "" || setting.cloudflareApiKey == "") {
    return ("Please set your Cloudflare Email and API Key", <Record>[]);
  }
  final res = await get(
      Uri.parse(
          "https://api.cloudflare.com/client/v4/zones/$zoneId/dns_records"),
      headers: {
        "X-Auth-Email": setting.cloudflareEmail,
        "X-Auth-Key": setting.cloudflareApiKey
      });
  return parse<List<Record>>(
      res,
      (body) => (body as List<dynamic>? ?? [])
          .map((e) => Record.fromJson(e))
          .toList());
}

@riverpod
FutureOr<(String, List<Record>?)> getZoneDnsFilter(
    GetZoneDnsFilterRef ref, String zoneId, String search) async {
  final res = await ref.watch(getZoneDnsProvider.call(zoneId).future);
  if (search.isNotEmpty) {
    return (res.$1, res.$2?.where((e) => e.name.contains(search)).toList());
  } else {
    return res;
  }
}
