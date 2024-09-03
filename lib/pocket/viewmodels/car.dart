// ignore_for_file: invalid_annotation_target

import 'package:cyberme_flutter/pocket/viewmodels/basic.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'car.freezed.dart';
part 'car.g.dart';

@freezed
class CarStatus with _$CarStatus {
  const factory CarStatus({
    @JsonKey(name: "oil-distance") @Default(0) double oilDistance,
    @Default(0) double inspection,
    @Default("closed") String windows,
    @JsonKey(name: "parking-brake") @Default("active") String parkingBrake,
    @Default("closed") String doors,
    @Default(0) double speed,
    @Default("checked") String tyre,
    @JsonKey(name: "fuel-level") @Default(0) double fuelLevel,
    @JsonKey(name: "engine-type") @Default("gasoline") String engineType,
    @JsonKey(name: "out-temp") @Default(0) double outTemp,
    @Default("") String last,
    @Default("locked") String lock,
    @Default(0) double range,
    @JsonKey(name: "oil-level") @Default(0) double oilLevel,
  }) = _CarStatus;

  factory CarStatus.fromJson(Map<String, dynamic> json) =>
      _$CarStatusFromJson(json);
}

@freezed
class CarLoc with _$CarLoc {
  const factory CarLoc(
      {@Default(0) int latitude,
      @Default(0) int longitude,
      @JsonKey(name: "head-direction") @Default(0) int headDirection,
      @Default("") String time,
      @Default("") String place}) = _CarLoc;

  factory CarLoc.fromJson(Map<String, dynamic> json) => _$CarLocFromJson(json);
}

@freezed
class CarTrip with _$CarTrip {
  const factory CarTrip({
    @JsonKey(name: "trip-hours") @Default(0) double tripHours,
    @Default(0) double fuel,
    @Default(0) double mileage,
    @JsonKey(name: "average-fuel") @Default(0) double averageFuel,
  }) = _CarTrip;

  factory CarTrip.fromJson(Map<String, dynamic> json) =>
      _$CarTripFromJson(json);
}

@freezed
class CarInfo with _$CarInfo {
  const factory CarInfo(
          {@Default("") String vin,
          @JsonKey(name: "report-time") @Default(0) int reportTime,
          @JsonKey(name: "report-time-str") @Default("") String reportTimeStr,
          @JsonKey(name: "dump-time") @Default(0) int dumpTime,
          @JsonKey(name: "dump-time-str") @Default("") String dumpTimeStr,
          @Default(CarLoc()) CarLoc loc,
          @Default(CarStatus()) CarStatus status,
          @JsonKey(name: "trip-status") @Default(CarTrip()) CarTrip trip}) =
      _CarInfo;

  factory CarInfo.fromJson(Map<String, dynamic> json) =>
      _$CarInfoFromJson(json);
}

@riverpod
class CarDb extends _$CarDb {
  @override
  FutureOr<CarInfo> build() async {
    final res = await requestFrom(
        "/cyber/service/car-status/default", CarInfo.fromJson);
    return res.$1 ?? const CarInfo();
  }

  Future<String> forceUpdate() async {
    final res = await requestFrom(
        "/cyber/service/car-status/default?cache=false", CarInfo.fromJson);
    state = AsyncData(res.$1 ?? const CarInfo());
    return "更新成功";
  }
}
