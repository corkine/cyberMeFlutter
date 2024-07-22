import 'package:cyberme_flutter/api/basic.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cert.freezed.dart';
part 'cert.g.dart';

@freezed
class CertDeploy with _$CertDeploy {
  factory CertDeploy({
    @Default("") String name,
    @Default("") String address,
    @Default("") String note,
  }) = _CertDeploy;

  factory CertDeploy.fromJson(Map<String, dynamic> json) =>
      _$CertDeployFromJson(json);
}

@freezed
class CertConfig with _$CertConfig {
  factory CertConfig({
    @Default("") String name,
    @Default("") String domain,
    @Default(0) int expired,
    @Default("") String note,
    @Default("") String publicKey,
    @Default("") String privateKey,
    @Default([]) List<CertDeploy> deploys,
    @Default(0) int updateAt,
  }) = _CertConfig;

  factory CertConfig.fromJson(Map<String, dynamic> json) =>
      _$CertConfigFromJson(json);
}

@Freezed(makeCollectionsUnmodifiable: false)
class CertConfigs with _$CertConfigs {
  factory CertConfigs({@Default({}) Map<String, CertConfig> certs}) =
      _CertConfigs;

  factory CertConfigs.fromJson(Map<String, dynamic> json) =>
      _$CertConfigsFromJson(json);
}

@riverpod
class Certs extends _$Certs {
  static const tag = "cert";
  @override
  FutureOr<CertConfigs> build() async {
    final res = await settingFetch(tag, CertConfigs.fromJson);
    return res ?? CertConfigs();
  }

  Future<void> set(CertConfig config) async {
    final newState = state.value!
        .copyWith(certs: {...state.value!.certs, config.name: config});
    await settingUpload(tag, newState.toJson());
    state = AsyncData(newState);
  }
}
