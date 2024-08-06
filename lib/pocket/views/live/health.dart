import 'dart:io';
import 'package:flutter/foundation.dart' as f;
import 'package:flutter/material.dart';
import 'package:health_kit_reporter/health_kit_reporter.dart';
import 'package:health_kit_reporter/model/payload/category.dart';
import 'package:health_kit_reporter/model/payload/quantity.dart';
import 'package:health_kit_reporter/model/payload/sample.dart';
import 'package:health_kit_reporter/model/payload/source.dart';
import 'package:health_kit_reporter/model/payload/source_revision.dart';
import 'package:health_kit_reporter/model/predicate.dart';
import 'package:health_kit_reporter/model/type/category_type.dart';
import 'package:health_kit_reporter/model/type/quantity_type.dart';
import 'package:uuid/uuid.dart';

const _source = Source('CyberMe', 'com.mazhangjing.cyberme');
const _operatingSystem = OperatingSystem(1, 2, 3);
const _sourceRevision =
    SourceRevision(_source, null, null, "1.0", _operatingSystem);

DateTime ts2DateTime(num ts) {
  return DateTime.fromMillisecondsSinceEpoch(ts * 1000 as int);
}

Future<(bool, String)> requestAuthorization<T>(
    {required List<String> readTypes, required List<String> writeTypes}) async {
  if (f.kIsWeb || !Platform.isIOS) return (false, "Platform not supported");
  try {
    final readTypes = <String>[CategoryType.sexualActivity.identifier];
    final writeTypes = <String>[CategoryType.sexualActivity.identifier];
    final isRequested =
        await HealthKitReporter.requestAuthorization(readTypes, writeTypes);
    if (isRequested) {
      return (true, "");
    } else {
      return (false, "Authorization not requested");
    }
  } catch (e, st) {
    debugPrintStack(stackTrace: st);
  }
  return (false, "Error");
}

Future<(bool, String)> addSample(String type, Sample data) async {
  if (f.kIsWeb || !Platform.isIOS) return (false, "Platform not supported");
  try {
    final canWrite = await HealthKitReporter.isAuthorizedToWrite(type);
    if (canWrite) {
      debugPrint('try to save: ${data.map}');
      final saved = await HealthKitReporter.save(data);
      debugPrint('data saved: $saved');
      return (true, "Save done");
    } else {
      debugPrint('error canWrite steps: $canWrite');
      return (false, "Error, Can not Write");
    }
  } catch (e) {
    debugPrint(e.toString());
    return (false, e.toString());
  }
}

Future<String> deleteSample(String type, int seconds) async {
  if (f.kIsWeb || !Platform.isIOS) return "Platform not supported";
  await HealthKitReporter.deleteObjects(QuantityType.bodyMass.identifier,
      Predicate(ts2DateTime(seconds), ts2DateTime(seconds + 1)));
  return "Delete done";
}

Future<void> addSexualActivity(DateTime dateTime, bool? protected) async {
  await addSample(
      CategoryType.sexualActivity.identifier,
      Category(
          const Uuid().v4(),
          CategoryType.sexualActivity.identifier,
          dateTime.millisecondsSinceEpoch,
          dateTime.millisecondsSinceEpoch,
          null,
          _sourceRevision,
          CategoryHarmonized(
              0, "", "", {"HKSexualActivityProtectionUsed": protected})));
}

bool? sexualAcitvityProtected(Category? cm) {
  if (cm == null) return null;
  int? d;
  try {
    d = cm.harmonized.metadata?["double"]?["dictionary"]
        ?["HKSexualActivityProtectionUsed"] as int?;
  } catch (e) {
    debugPrint("error parse: $cm");
  }
  return d == null ? null : d == 1;
}

Future<(bool, String)> addBodyMassRecord(
    DateTime dateTime, double value) async {
  return await addSample(
      QuantityType.bodyMass.identifier,
      Quantity(
          const Uuid().v4(),
          QuantityType.bodyMass.identifier,
          dateTime.millisecondsSinceEpoch,
          dateTime.millisecondsSinceEpoch,
          null,
          _sourceRevision,
          //https://developer.apple.com/documentation/healthkit/hkunit/1615733-init/
          QuantityHarmonized(value, "kg", null)));
}
