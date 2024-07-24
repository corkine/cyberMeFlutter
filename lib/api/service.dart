import 'package:cyberme_flutter/api/basic.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'service.freezed.dart';
part 'service.g.dart';

enum ServiceType {
  inside("内部服务", Icons.storage),
  cron("后台定时任务", Icons.schedule),
  http("HTTP 服务", Icons.public),
  socket("Socket 服务", Icons.api);

  final String desc;
  final IconData icon;
  const ServiceType(this.desc, this.icon);
}

@freezed
class Server with _$Server {
  factory Server(
      {@Default("") String id,
      @Default("") String name,
      @Default(0) int cpuCount,
      @Default(0) int memoryGB,
      @Default(0) int diskGB,
      @Default(0) int expired,
      @Default("") String manageUrl,
      @Default("") String sshUrl,
      @Default("") String note,
      @Default("") String band}) = _Server;

  factory Server.fromJson(Map<String, dynamic> json) => _$ServerFromJson(json);
}

@freezed
class ServerService with _$ServerService {
  factory ServerService(
      {@Default("") String id,
      @Default("") String name,
      @Default([]) List<String> endpoints,
      @Default("") String note,
      @Default("") String implDetails,
      @Default([]) List<String> tokenIds,
      @Default(ServiceType.http) ServiceType type,
      @Default("") String serverId}) = _ServerService;

  factory ServerService.fromJson(Map<String, dynamic> json) =>
      _$ServerServiceFromJson(json);
}

@freezed
class OAuthToken with _$OAuthToken {
  factory OAuthToken(
      {@Default("") String id,
      @Default("") String name,
      @Default("") String clientId,
      @Default("") String secret,
      @Default(0) int expired,
      @Default("") String note,
      @Default("") String manageUrl}) = _OAuthToken;

  factory OAuthToken.fromJson(Map<String, dynamic> json) =>
      _$OAuthTokenFromJson(json);
}

@freezed
class ServerMap with _$ServerMap {
  factory ServerMap({
    @Default({}) Map<String, Server> servers,
    @Default({}) Map<String, OAuthToken> tokens,
    @Default({}) Map<String, ServerService> services,
  }) = _ServerMap;

  factory ServerMap.fromJson(Map<String, dynamic> json) =>
      _$ServerMapFromJson(json);
}

@riverpod
class ServiceDb extends _$ServiceDb {
  static const apiKey = "server-manage";
  @override
  FutureOr<ServerMap> build() async {
    final res = await settingFetch(apiKey, ServerMap.fromJson);
    //todo fill with serverService
    return res!.copyWith();
  }

  void makeMemchangeOfToken(OAuthToken data) {
    state = AsyncData((state.value ?? ServerMap())
        .copyWith(tokens: {...state.value!.tokens, data.id: data}));
  }

  void makeMemchangeOfServer(Server data) {
    state = AsyncData((state.value ?? ServerMap())
        .copyWith(servers: {...state.value!.servers, data.id: data}));
  }

  void makeMemchangeOfService(ServerService data) {
    state = AsyncData((state.value ?? ServerMap())
        .copyWith(services: {...state.value!.services, data.id: data}));
  }

  void deleteServer(String serverId) {
    final ss = {...state.value!.servers};
    ss.remove(serverId);
    state = AsyncData((state.value ?? ServerMap()).copyWith(servers: ss));
  }

  void deleteToken(String tokenId) {
    final tks = {...state.value!.tokens};
    tks.remove(tokenId);
    state = AsyncData((state.value ?? ServerMap()).copyWith(tokens: tks));
  }

  void deleteService(String serviceId) {
    final ss = {...state.value!.services};
    ss.remove(serviceId);
    state = AsyncData((state.value ?? ServerMap()).copyWith(services: ss));
  }

  Future<void> rewrite() async {
    await settingUpload(apiKey, state.value!.toJson());
  }
}
