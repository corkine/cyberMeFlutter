import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprintf/sprintf.dart';

import 'day.dart';
import 'models/good.dart';

String encryptPassword(String password, int validSeconds, [int? nowMill]) {
  var willExpired =
      (nowMill ?? DateTime.now().millisecondsSinceEpoch) + validSeconds * 1000;
  var digest = sha1.convert(utf8.encode("$password::$willExpired"));
  var passInSha1Base64 = base64Encode(digest.bytes);
  var res = base64Encode(utf8.encode("$passInSha1Base64::$willExpired"));
  DayInfo.encryptInfo = sprintf(
      "The last encrypt validSec: %s, nowMill: %s, pass: %s, willExpired: %s,"
      "encrypt %s",
      [validSeconds, nowMill ?? -1, password.isNotEmpty, willExpired, res]);
  return res;
}

String encodeSha1Base64(String plain) {
  var digest = sha1.convert(utf8.encode(plain));
  return base64Encode(digest.bytes);
}

late Config config;

class Config {
  static const version = 'VERSION 1.2.0, Build#2023-03-13';

  /*
  1.0.4 修复了 Goods 标题显示详情问题，新键项目添加图片表单信息丢失问题，添加/修改返回后列表不更新问题
  1.0.5 修复了 QuickLink 非去重时的数据折叠问题
  1.0.6 修复了更新 Goods 时图片预览不更新的问题
  1.0.7 取消使用 static const 配置 Config，使用 Provider 替代，添加登录和注销，以及凭证记录。
  1.0.8 修改 Goods 逻辑，点击显示 HTML 预览，长按进行修改，修改了默认的排序逻辑，提供显示创建/修改时间的选项，
  并自动根据选择时间处理排序，自动将选中对象拷贝到剪贴板，用户配置自动记住。
  1.0.9 更新 Good 返回列表刷新后会自动返回进入时的位置(新键 Good 则不会)，此外现在可以对列表进行同重要性和状态内的排序了，数据
  会记录在本地，下次打开后会自动排序。此外修复了 Dismissible 条目删除后短暂停留项目重新回来的问题（Good 和 QuickLink）。
  1.1.0 修复了修改 Good 删除字段时服务端因为没有字段被识别为不修改的错误（现在设置为空字符串），优化了拖拽排序时的卡片间距
  过大割裂感问题。
  1.1.1 优化了进入可排序 Good 面板前和后自动记录当前位置的问题。
  1.1.2 重新调整了可排序面板和正常面板间距，现在记录的列表位置是精确的。添加了 iOS 和 Android 的长按快速 Action。
  1.1.3 添加了快速 Action 添加短链接，从剪贴板添加短链接的方法，自动将短链接复制到剪贴板
  1.1.4 添加了快速 Action 添加短链接的自动键盘弹出
  1.1.5 修改快速链接 - 最近 为 查找最近链接
  1.1.6 修改默认启动页为短连接
  1.1.7 2022-04-30 迁移到 Dart 空指针安全模式，优化了部分代码结构，整合了游戏、SNH48 和凭证系统。
  1.1.8 2022-5-1 添加了 Dashboard 页面。
  1.1.9 2022-5-18 添加了日记页面。
  1.2.0 2023-03-13 使用 M3 主题，整合到 iOS SwiftUI App 中。«
  */
  static const int pageIndex = 0;

  static const headerStyle = TextStyle(fontSize: 20);
  static const smallHeaderStyle = TextStyle(fontSize: 13);
  static const formHelperStyle = TextStyle(color: Colors.grey, fontSize: 10);

  String user = '';
  String password = '';
  String cyberPass = '';

  String get token => '?user=$user&password=$password';

  String get base64Token =>
      "Basic ${base64Encode(utf8.encode('$user:$password'))}";

  Map<String, String> get base64Header =>
      <String, String>{'authorization': base64Token};

  String get cyberBase64Token =>
      "Basic ${base64Encode(utf8.encode('$user:$cyberPass'))}";

  Map<String, String> get cyberBase64Header =>
      <String, String>{'authorization': cyberBase64Token};

  Map<String, String> get cyberBase64JsonContentHeader => <String, String>{
        'Authorization': cyberBase64Token,
        'Content-Type': 'application/json'
      };

  double position = 0.0;

  static const String dashboardUrl =
      "https://cyber.mazhangjing.com/cyber/dashboard/summary";
  static const String recentTicketUrl =
      "https://cyber.mazhangjing.com/cyber/ticket/recent";
  static const String visitsUrl =
      "https://cyber.mazhangjing.com/cyber/service/visits";
  static const String trackUrl =
      "https://cyber.mazhangjing.com/cyber/service/visits/monitor";

  static Uri goUrl(String keyword, String redirectURL, {String? note}) => Uri(
          scheme: 'https',
          host: 'cyber.mazhangjing.com',
          path: '/cyber/go/add',
          queryParameters: {
            "keyword": keyword,
            "redirectURL": redirectURL,
            "note": note ?? "CyberMe Flutter Client"
          });

  static const String goPostUrl = "https://cyber.mazhangjing.com/cyber/go/add";

  static const String storyListUrl =
      "https://cyber.mazhangjing.com/cyber/story/all-book-and-story-name";

  static storyBookUrl(String book) =>
      "https://cyber.mazhangjing.com/cyber/story/all-story-name/$book";

  static String storyReadUrl(String bookName, String storyName) => Uri.encodeFull(
      "https://cyber.mazhangjing.com/cyber/story/read-story/$bookName/$storyName");

  static String storySearchUrl =
      "https://cyber.mazhangjing.com/cyber/story/api-search";

  static Uri goNoteUrl(String keyword, String noteContent) => Uri(
          scheme: 'https',
          host: 'cyber.mazhangjing.com',
          path: '/cyber/go/add',
          queryParameters: {
            "keyword": keyword,
            "redirectURL": ":note",
            "note": noteContent
          });

  static String movieUrl(String type, String sort) =>
      "https://cyber.mazhangjing.com/cyber/movie/dashboard?type=$type&sort=$sort";

  static String todoUrl(int start, int end) =>
      "https://cyber.mazhangjing.com/cyber/todo/recent-page?from=$start&to=$end";

  static String deleteExpress(String no) =>
      "https://cyber.mazhangjing.com/cyber/express/delete?no=$no";

  static String expressAddUrl(
          String note, bool rewriteIfExist, bool addToWaitList, String no) =>
      Uri(
          scheme: 'https',
          host: 'cyber.mazhangjing.com',
          path: '/cyber/express/track',
          queryParameters: {
            "note": note,
            "rewriteIfExist": rewriteIfExist.toString(),
            "addToWaitList": addToWaitList.toString(),
            "no": no
          }).toString();

  static String logsUrl(String key) =>
      "https://cyber.mazhangjing.com/cyber/service/visits/$key/logs";
  static const String parseTicketUrl =
      "https://cyber.mazhangjing.com/cyber/client/parse-tickets";
  static const String addTicketsUrl =
      "https://cyber.mazhangjing.com/cyber/ticket/add-multi";
  static const String deleteTicketUrl =
      "https://cyber.mazhangjing.com/cyber/ticket/delete-date/";
  static const String dayWorkUrl =
      "https://cyber.mazhangjing.com/cyber/dashboard/day-work";
  static const String todoSyncUrl =
      "https://cyber.mazhangjing.com/cyber/todo/sync";
  static const String hcmCardCheckUrl =
      "https://cyber.mazhangjing.com/cyber/check/now?plainText=true&useCache=false";
  static const String morningCleanUrl =
      "https://cyber.mazhangjing.com/cyber/clean/update?merge=true&mt=true&mf=true";
  static const String nightCleanUrl =
      "https://cyber.mazhangjing.com/cyber/clean/update?merge=true&nt=true&nf=true";
  static const String blueUrl =
      "https://cyber.mazhangjing.com/cyber/blue/update?blue=true&day=";
  static const String lastNoteUrl =
      "https://cyber.mazhangjing.com/cyber/note/last";
  static const String uploadNoteUrl =
      "https://cyber.mazhangjing.com/cyber/note";
  static const String diariesUrl =
      "https://cyber.mazhangjing.com/cyber/diaries";
  static const String ossUrl = "https://cyber.mazhangjing.com/api/files/upload";
  static const String plantUrl =
      "https://cyber.mazhangjing.com/cyber/dashboard/plant-week";

  static const String redisUrl =
      "https://cyber.mazhangjing.com/cyber/service/eval";

  String addURL = 'https://go.mazhangjing.com/add';
  String basicURL = 'https://go.mazhangjing.com';

  String get goodsAddURL => 'https://status.mazhangjing.com/goods/add$token';

  String searchURL(String word) =>
      'https://go.mazhangjing.com/searchjson/$word$token';

  String dataURL(int limit) =>
      'https://go.mazhangjing.com/logs$token&day=$limit';

  String deleteURL(String keyword) =>
      'https://go.mazhangjing.com/deleteKey/$keyword$token';

  String deleteGoodsURL(String goodsId) =>
      'https://status.mazhangjing.com/goods/$goodsId/delete$token';

  String goodsUpdateURL(String goodsId) =>
      'https://status.mazhangjing.com/goods/$goodsId/update$token';

  String goodsURL() =>
      'https://status.mazhangjing.com/goods/data$token&hideRemove=$notShowRemoved&hideClothes=$notShowClothes'
      '&recentFirst:$goodsRecentFirst&shortByName:$goodsShortByName';

  String goodsView(Good good) =>
      'https://status.mazhangjing.com/goods/${good.id}/details$token';

  String goodsViewNoToken(Good good) =>
      'https://status.mazhangjing.com/goods/${good.id}/details';

  int _shortURLShowLimit = 10;
  static double toolBarHeight = 50.0;
  bool _filterDuplicate = true;

  int get shortURLShowLimit => _shortURLShowLimit;

  bool get filterDuplicate => _filterDuplicate;

  int goodsLastDay = 300;
  bool goodsShortByName = true;
  bool goodsRecentFirst = true;
  bool notShowClothes = true;
  bool notShowRemoved = true;
  bool notShowArchive = true;
  bool showUpdateButNotCreateTime = true;
  bool autoCopyToClipboard = true;
  bool useReorderableListView = false;

  Map<String, int> map = {};

  late SharedPreferences prefs;
  late ScrollController controller;

  Future<Config> init() async {
    prefs = await SharedPreferences.getInstance();
    user = prefs.getString('user') ?? '';
    password = prefs.getString('password') ?? '';
    cyberPass = encryptPassword(password, 60 * 60 * 24 * 5);
    _shortURLShowLimit = prefs.getInt('_shortURLShowLimit') ?? 10;
    _filterDuplicate = prefs.getBool('_filterDuplicate') ?? true;
    goodsShortByName = prefs.getBool('goodsShortByName') ?? true;
    goodsRecentFirst = prefs.getBool('goodsRecentFirst') ?? true;
    notShowClothes = prefs.getBool('notShowClothes') ?? true;
    notShowRemoved = prefs.getBool('notShowRemoved') ?? true;
    notShowArchive = prefs.getBool('notShowArchive') ?? true;
    showUpdateButNotCreateTime =
        prefs.getBool('showUpdateButNotCreateTime') ?? true;
    autoCopyToClipboard = prefs.getBool('autoCopyToClipboard') ?? true;
    useReorderableListView = prefs.getBool('useReorderableListView') ?? false;
    map = Map<String, int>.fromEntries(
        (prefs.getStringList('goodsOrderMap') ?? <String>[]).map((e) {
      final r = e.split('::');
      return MapEntry<String, int>(r[0], int.parse(r[1]));
    }));
    return this;
  }

  bool setGoodsShortByName(bool res) {
    prefs.setBool('goodsShortByName', res);
    goodsShortByName = res;
    return true;
  }

  setGoodsRecentFirst(bool res) {
    prefs.setBool('goodsRecentFirst', res);
    goodsRecentFirst = res;
    return true;
  }

  setNotShowClothes(bool res) {
    prefs.setBool('notShowClothes', res);
    notShowClothes = res;
    return true;
  }

  setNotShowRemoved(bool res) {
    prefs.setBool('notShowRemoved', res);
    notShowRemoved = res;
    return true;
  }

  setNotShowArchive(bool res) {
    prefs.setBool('notShowArchive', res);
    notShowArchive = res;
    return true;
  }

  setShowUpdateButNotCreateTime(bool set) {
    prefs.setBool('showUpdateButNotCreateTime', set);
    showUpdateButNotCreateTime = set;
    return true;
  }

  setAutoCopyToClipboard(bool set) {
    prefs.setBool('autoCopyToClipboard', set);
    autoCopyToClipboard = set;
    return true;
  }

  setShortUrlShowLimit(int limit) {
    prefs.setInt('_shortURLShowLimit', limit);
    _shortURLShowLimit = limit;
    return true;
  }

  setFilterDuplicate(bool set) {
    prefs.setBool('_filterDuplicate', set);
    _filterDuplicate = set;
    return true;
  }

  setUseReorderableListView(bool set) {
    prefs.setBool('useReorderableListView', set);
    prefs.setStringList('goodsOrderMap',
        map.entries.map((e) => e.key + '::' + e.value.toString()).toList());
    //prefs.setStringList('goodsOrderMap', []);
    useReorderableListView = set;
    return true;
  }

  setBool(String key, bool set) {
    if (kDebugMode) {
      print("set $key to $set");
    }
    prefs.setBool(key, set);
  }

  justNotify() {}

  @override
  String toString() {
    return 'Config{user: $user, password: ${password.isNotEmpty}, cyberPass: $cyberPass, basicURL: $basicURL, notShowRemoved: $notShowRemoved, prefs: $prefs}';
  }
}
