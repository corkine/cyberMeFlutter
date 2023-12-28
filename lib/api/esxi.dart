// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:cyberme_flutter/api/basic.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'esxi.freezed.dart';
part 'esxi.g.dart';

@freezed
class EsxiIp with _$EsxiIp {
  const factory EsxiIp({
    @Default("") String interface,
    @Default("") String mac_address,
    @Default("") String ip_address,
    @Default("") String netmask,
    @Default("") String ip_family,
    @Default("") String netstack,
    @Default("") String mtu,
    @Default("") String broadcast,
    @Default("") String tso_mss,
    @Default("") String enabled,
    @Default("") String type,
  }) = _EsxiIp;

  factory EsxiIp.fromJson(Map<String, dynamic> json) => _$EsxiIpFromJson(json);
}

@freezed
class EsxiVm with _$EsxiVm {
  const factory EsxiVm(
      {@Default("") String vmid,
      @Default("") String name,
      @Default("") String file,
      @Default("") String guest,
      @Default("") String os,
      @Default("") String version,
      @Default("") String power}) = _EsxiVm;

  factory EsxiVm.fromJson(Map<String, dynamic> json) => _$EsxiVmFromJson(json);
}

enum VmPower { on, off, suspended, unknown }

extension VmPowerExtension on EsxiVm {
  VmPower get powerEnum {
    switch (power) {
      case "on":
        return VmPower.on;
      case "off":
        return VmPower.off;
      case "suspended":
        return VmPower.suspended;
      default:
        return VmPower.unknown;
    }
  }
}

@freezed
class EsxiInfo with _$EsxiInfo {
  const factory EsxiInfo({
    @Default("") String version,
    @Default([]) List<EsxiIp> ips,
    @Default([]) List<EsxiVm> vms,
  }) = _EsxiInfo;

  factory EsxiInfo.fromJson(Map<String, dynamic> json) =>
      _$EsxiInfoFromJson(json);
}

@riverpod
class EsxiInfos extends _$EsxiInfos {
  @override
  Future<EsxiInfo> build() async {
    final (res, ok) = await requestFrom(
        "/cyber/service/esxi/info?cache=true", EsxiInfo.fromJson);
    if (ok.isNotEmpty) throw Exception(ok);
    return res!;
  }

  Future<void> sync() async {
    final (res, ok) = await requestFrom(
        "/cyber/service/esxi/info?cache=false", EsxiInfo.fromJson);
    if (ok.isNotEmpty) throw Exception(ok);
    if (res != null) {
      state = AsyncData(res);
    }
  }

  Future<String> changeState(EsxiVm vm, VmPower power) async {
    final (ok, res) = await postFrom(
        "/cyber/service/esxi/power", {"vm": vm.vmid, "power": power.name});
    if (ok) {
      final old = state.valueOrNull;
      if (old == null) return res;
      state = AsyncData(old.copyWith(
          vms: old.vms.map((e) {
        if (e.vmid == vm.vmid) {
          return e.copyWith(power: power.name);
        } else {
          return e;
        }
      }).toList(growable: false)));
    }
    return res;
  }
}
