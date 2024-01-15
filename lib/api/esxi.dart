// ignore_for_file: non_constant_identifier_names

import 'package:cyberme_flutter/api/basic.dart';
import 'package:flutter/foundation.dart';
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
  Future<(EsxiInfo?, String)> build() async {
    try {
      final (res, ok) = await requestFrom(
          "/cyber/service/esxi/info?cache=true", EsxiInfo.fromJson);
      if (ok.isNotEmpty) {
        return (null, ok);
      } else {
        return (res!, "");
      }
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
      return (null, e.toString());
    }
  }

  Future<void> sync() async {
    final (res, ok) = await requestFrom(
        "/cyber/service/esxi/info?cache=false", EsxiInfo.fromJson);
    if (ok.isNotEmpty) throw Exception(ok);
    if (res != null) {
      state = AsyncData((res, ""));
    }
  }

  Future<String> changeState(EsxiVm vm, VmPower power) async {
    final (ok, res) = await postFrom(
        "/cyber/service/esxi/power", {"vm": vm.vmid, "power": power.name});
    if (ok) {
      final old = state.valueOrNull;
      if (old == null) return res;
      state = AsyncData((
        old.$1!.copyWith(
            vms: old.$1!.vms.map((e) {
          if (e.vmid == vm.vmid) {
            return e.copyWith(power: power.name);
          } else {
            return e;
          }
        }).toList(growable: false)),
        ""
      ));
    }
    return res;
  }
}

@freezed
class ESXiService with _$ESXiService {
  factory ESXiService(
      {@Default("") String host,
      @Default(-1) int port,
      @Default("") String name,
      @Default("") String note}) = _ESXiService;

  factory ESXiService.fromJson(Map<String, dynamic> json) =>
      _$ESXiServiceFromJson(json);
}

@freezed
class ESXiSetting with _$ESXiSetting {
  const factory ESXiSetting({
    @Default({}) Map<String, Set<ESXiService>> services,
    @Default({}) Map<String, String> ips,
  }) = _ESXiSetting;

  factory ESXiSetting.fromJson(Map<String, dynamic> json) =>
      _$ESXiSettingFromJson(json);
}

@riverpod
class ESXiSettings extends _$ESXiSettings {
  @override
  FutureOr<ESXiSetting> build() async {
    final (res, ok) =
        await requestFrom("/cyber/service/esxi/setting", ESXiSetting.fromJson);
    if (ok.isNotEmpty) throw Exception(ok);
    return res!;
  }

  Future<String> upload(ESXiSetting setting) async {
    final (ok, res) =
        await postFrom("/cyber/service/esxi/setting", setting.toJson());
    if (ok) {
      state = AsyncData(setting);
    }
    return res;
  }

  Future<String> addService(
      String host, ESXiService service, bool removeOld) async {
    final old = state.valueOrNull;
    if (old == null) return "无法添加服务";
    state = AsyncData(old.copyWith(services: {
      ...old.services,
      host: {
        ...(old.services[host] ?? {}).where(
            (element) => removeOld ? element.port != service.port : true),
        service
      }
    }));
    await upload(state.value!);
    return removeOld ? "修改成功" : "添加成功";
  }

  Future<String> removeService(String host, ESXiService service) async {
    final old = state.valueOrNull;
    if (old == null) return "无法删除服务";
    state = AsyncData(old.copyWith(services: {
      ...old.services,
      host: {...(old.services[host] ?? {})}..remove(service)
    }));
    await upload(state.value!);
    return "删除成功";
  }

  Future<String> addIp(String host, String ip) async {
    final old = state.valueOrNull;
    if (old == null) return "无法添加IP";
    state = AsyncData(old.copyWith(ips: {...old.ips, host: ip}));
    await upload(state.value!);
    return "添加成功";
  }

  Future<String> removeIp(String host) async {
    final old = state.valueOrNull;
    if (old == null) return "无法删除IP";
    state = AsyncData(old.copyWith(ips: {...old.ips}..remove(host)));
    await upload(state.value!);
    return "删除成功";
  }

  Future<String> changeIp(String host, String ip) async {
    final old = state.valueOrNull;
    if (old == null) return "无法修改IP";
    state = AsyncData(old.copyWith(ips: {...old.ips, host: ip}));
    await upload(state.value!);
    return "修改成功";
  }
}
