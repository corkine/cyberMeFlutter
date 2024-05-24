import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:cyberme_flutter/pocket/config.dart';
import 'package:cyberme_flutter/pocket/time.dart';
import 'package:http/http.dart';

class Diary {
  int id;
  String title;
  String content;
  String createAt;
  String updateAt;
  dynamic info;

  String get day => info["day"] ?? "0000-00-00";

  List<String> get labels {
    if (info == null || info["labels"] == null) return [];
    var labels = info["labels"] as List;
    return labels.map((e) => e as String).toList();
  }

  String get preview {
    var first = content.split("\n")[0];
    if (first.isEmpty) return "暂无内容";
    if (first.length > 90) return first.substring(0, 90) + "...";
    return first;
  }

  String? get previewPicture {
    var res = RegExp("!\\[.*?\\]\\((.*?)\\)").firstMatch(content);
    var find = res?.group(1);
    if (find != null) find = find + "?x-oss-process=style/fit";
    return find;
  }

  String get url => "https://cyber.mazhangjing.com/diary/by-id/$id";

//<editor-fold desc="Data Methods">

  Diary({
    required this.id,
    required this.title,
    required this.content,
    required this.createAt,
    required this.updateAt,
    required this.info,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Diary &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          content == other.content &&
          createAt == other.createAt &&
          updateAt == other.updateAt &&
          info == other.info);

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      content.hashCode ^
      createAt.hashCode ^
      updateAt.hashCode ^
      info.hashCode;

  @override
  String toString() {
    return 'Diaries{' +
        ' id: $id,' +
        ' title: $title,' +
        ' content: $content,' +
        ' createAt: $createAt,' +
        ' updateAt: $updateAt,' +
        ' info: $info,' +
        '}';
  }

  Diary copyWith({
    int? id,
    String? title,
    String? content,
    String? createAt,
    String? updateAt,
    dynamic info,
  }) {
    return Diary(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
      info: info ?? this.info,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'create_at': createAt,
      'update_at': updateAt,
      'info': info,
    };
  }

  factory Diary.fromMap(Map<String, dynamic> map) {
    return Diary(
      id: map['id'] as int,
      title: map['title'] as String,
      content: map['content'] as String,
      createAt: map['create_at'] as String,
      updateAt: map['update_at'] as String,
      info: map['info'] as dynamic,
    );
  }

//</editor-fold>
}

class DiaryManager {
  static Future<List<Diary>> loadFromApi(Config config) async {
    if (kDebugMode) {
      print("Loading from Diary... from user: ${config.user}");
    }
    final Response r = await get(Uri.parse(Config.diariesUrl),
        headers: config.cyberBase64Header);
    final data = jsonDecode(r.body)["data"] as List;
    return data.map((diaryJson) => Diary.fromMap(diaryJson)).toList();
  }

  static Diary? today(List<Diary> data) {
    String today = TimeUtil.today;
    var find = data.where((element) => element.day == today);
    return find.isNotEmpty ? find.first : null;
  }

  static String get newDiaryUrl => "https://cyber.mazhangjing.com/diary-new";
}
