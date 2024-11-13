import 'package:cyberme_flutter/pocket/viewmodels/basic.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'wireguard.freezed.dart';
part 'wireguard.g.dart';

@freezed
class Net with _$Net {
  factory Net({
    @Default("") String id,
    @Default("") String lastUpdate,
    @Default("") String name,
    @Default(NetServer()) NetServer server,
    @Default([]) List<NetClient> clients,
  }) = _Net;

  factory Net.fromJson(Map<String, dynamic> json) => _$NetFromJson(json);
}

@freezed
class NetClient with _$NetClient {
  const factory NetClient({
    @Default("") String address,
    @Default("") String allowedIPs,
    @Default("") String name,
    @Default("") String privateKey,
    @Default("") String publicKey,
  }) = _NetClient;

  factory NetClient.fromJson(Map<String, dynamic> json) =>
      _$NetClientFromJson(json);
}

@freezed
class NetServer with _$NetServer {
  const factory NetServer({
    @Default("") String ip,
    @Default("") String name,
    @Default("") String port,
    @Default("") String privateKey,
    @Default("") String publicKey,
  }) = _NetServer;

  factory NetServer.fromJson(Map<String, dynamic> json) =>
      _$NetServerFromJson(json);
}

@riverpod
class NetDb extends _$NetDb {
  Future<List<Net>> _fetchNetDb() async {
    final res = await requestFrom(
        "/cyber/net/list",
        (v) => v.entries.map((k) {
              final d = Net.fromJson(k.value);
              final c = [...d.clients];
              c.sort((a, b) => a.address.compareTo(b.address));
              return d.copyWith(id: k.key, clients: c);
            }).toList());
    return res.$1 ?? [];
  }

  @override
  FutureOr<List<Net>> build() async {
    return _fetchNetDb();
  }

  Future<String> change(Net net) async {
    final data = net.toJson();
    data["info"] = {};
    final res = await postFrom("/cyber/net/change", data);
    ref.invalidateSelf();
    return res.$2;
  }

  Future<String> delete(String netId) async {
    final res = await postFrom("/cyber/net/delete/$netId", {});
    ref.invalidateSelf();
    return res.$2;
  }

  Future<String> localChange(Net net) async {
    state = AsyncData((state.value ?? []).map((e) {
      if (e.id == net.id) {
        return net;
      } else {
        return e;
      }
    }).toList());
    return "OK";
  }
}
