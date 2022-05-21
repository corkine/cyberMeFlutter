import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Info {
  String name;
  String id;
  String lastTestTime;
  String testInfo;
  String lastVaccineDate;
  int vaccineTimes;
  String checkPlace;

  bool get isTestInfo48 => testInfo.contains("48");
  bool get isTestInfo72 => testInfo.contains("72");
  bool get isEmptyTimeInTestInfo => !(isTestInfo48 || isTestInfo72);

  Info(
      {required this.name,
      required this.id,
      required this.lastTestTime,
      required this.testInfo,
      required this.lastVaccineDate,
      required this.vaccineTimes,
      required this.checkPlace});

  static bool needShow = false;

  static String middleStarName(Info info) {
    int len = info.name.length;
    if (len == 0 || len == 1) return info.name;
    if (len == 2) return "*" + info.name.substring(1,2);
    String first = info.name.substring(0,1);
    String last = info.name.substring(len - 1, len);
    String star = "";
    for (int i = 0; i < len - 2; i++) {
      star += "*";
    }
    return first + star + last;
  }

  @override
  String toString() {
    return 'Info{name: $name, id: $id, lastTestTime: $lastTestTime, testInfo: $testInfo, lastVaccineDate: $lastVaccineDate, vaccineTimes: $vaccineTimes, checkPlace: $checkPlace}';
  }

  static savingData(Info info) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("name", info.name);
    prefs.setString("id", info.id);
    prefs.setString("lastTestTime", info.lastTestTime);
    prefs.setString("testInfo", info.testInfo);
    prefs.setString("lastVaccineDate", info.lastVaccineDate);
    prefs.setInt("vaccineTimes", info.vaccineTimes);
    prefs.setString("checkPlace", info.checkPlace);
  }

  static Future<Info> readData() {
    var f = SharedPreferences.getInstance().then(
      (prefs) => Info(
          name: prefs.getString("name") ?? "张三",
          id: prefs.getString("id") ?? "122333444555553321",
          lastTestTime: prefs.getString("lastTestTime") ?? "2022-04-23 00:39",
          testInfo: prefs.getString("testInfo") ?? "48小时阴性",
          lastVaccineDate: prefs.getString("lastVaccineDate") ?? "2022-04-01",
          vaccineTimes: prefs.getInt("vaccineTimes") ?? 3,
          checkPlace: prefs.getString("checkPlace") ?? "天安门1号"),
    );
    return f;
  }

  static Color blue = const Color.fromRGBO(88, 145, 235, 1);

  static TextStyle normalStyle = const TextStyle(
      fontSize: 17,
      color: Colors.white,
      fontWeight: FontWeight.w400,
      fontFamily: ".SF UI Text");
  static TextStyle titleStyle = const TextStyle(
      fontSize: 17,
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontFamily: ".SF UI Text");
  static TextStyle nameStyle = const TextStyle(
      fontSize: 19,
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontFamily: ".SF UI Text");
  static BoxDecoration box = BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      color: Colors.white,
      boxShadow: const [
        BoxShadow(
            color: Color.fromARGB(10, 20, 30, 40),
            blurRadius: 10,
            spreadRadius: 0.3)
      ]);
  static Color grey = const Color.fromRGBO(147, 146, 149, 1);
}
