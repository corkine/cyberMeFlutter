import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

import '../config.dart';

class Plant {
  List<int> data = [];
  static Future<Plant> loadFromApi(Config config) async {
    try {
      if (kDebugMode) {
        print("Loading from Plant... from user: ${config.user}");
      }
      final Response r =
          await get(Uri.parse(Config.plantUrl), headers: config.base64Header);
      final data = jsonDecode(r.body)["data"]["status"] as List;
      var plant = Plant();
      plant.data = data.map((e) => e as int).toList();
      return plant;
    } catch (e) {
      if (kDebugMode) {
        print("Error to load Plant from CyberMe $e");
      }
      return Plant();
    }
  }

  static Future<String> setWaterRecordToDB(Config config) async {
    try {
      if (kDebugMode) {
        print("Setting to Plant to CyberMe");
      }
      final Response r =
          await post(Uri.parse(Config.plantUrl), headers: config.base64Header);
      final result = jsonDecode(r.body)["message"];
      config.justNotify();
      return result;
    } catch (e) {
      if (kDebugMode) {
        print("Error to set Plant to CyberMe $e");
      }
      return "失败：$e";
    }
  }

  bool get todayWater {
    DateTime now = DateTime.now();
    if (data.length != 7) {
      return false;
    } else {
      return data[now.weekday.toInt() - 1] == 1;
    }
  }

  List<bool> get weekWater {
    if (data.length != 7) {
      return List.generate(7, (_) => false);
    } else {
      return data.map((e) => e == 1).toList();
    }
  }

  List<String> get weekWaterStr {
    DateTime now = DateTime.now();
    var day = now.weekday.toInt() - 1;
    if (data.length != 7) {
      return List.generate(7, (_) => "❌");
    } else {
      List<String> result = [];
      for (var i = 0; i < data.length; i++) {
        var dayWater = data[i] == 1;
        if (i < day) {
          result.add(dayWater ? "🍀" : "🍂");
        } else {
          result.add(dayWater ? "🍀" : "");
        }
      }
      return result;
    }
  }
}
