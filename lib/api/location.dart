import 'package:cyberme_flutter/api/basic.dart';
import 'package:cyberme_flutter/api/convert.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:latlong2/latlong.dart';
part 'location.freezed.dart';
part 'location.g.dart';

@freezed
class LocationInfo with _$LocationInfo {
  factory LocationInfo(
      {@Default(0) int rank,
      @Default(0.0) double longitude,
      @Default(0.0) double latitude,
      @Default(0.0) double altitude,
      @Default(LatLng(0, 0)) LatLng gcLatLng,
      @Default(0) int id,
      @Default("") String note1,
      @Default("") String note2,
      @Default("") String by,
      @Default("") String updateTime}) = _LocationInfo;

  factory LocationInfo.fromJson(Map<String, dynamic> json) =>
      _$LocationInfoFromJson(json);
}

@riverpod
FutureOr<Map<String, List<LocationInfo>>> getTrackSummary(
    GetTrackSummaryRef ref) async {
  final (res, ok) = await requestFrom(
      "/cyber/location/summary?count=30",
      (m) => m.map((key, value) => MapEntry(
          key,
          (value as List? ?? []).map((e) {
            final l = LocationInfo.fromJson(e);
            return l.copyWith(
                gcLatLng: LatLngConvert(LatLng(l.latitude, l.longitude),
                    LatLngType.WGS84, LatLngType.GCJ02));
          }).toList(growable: false))));
  if (ok.isNotEmpty) {
    debugPrint(ok);
  }
  return res ?? {};
}
