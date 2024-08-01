import 'dart:convert';

import 'package:http/http.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../config.dart';
import 'basic.dart';

part 'notes.freezed.dart';

part 'notes.g.dart';

@freezed
class QuickNote with _$QuickNote {
  const factory QuickNote({
    @Default(-1) int Id,
    @Default("") String From,
    @Default("") String Content,
    @Default(-1) int LiveSeconds,
    @Default("") String LastUpdate,
  }) = _QuickNote;

  factory QuickNote.fromJson(Map<String, dynamic> json) =>
      _$QuickNoteFromJson(json);
}

@riverpod
class QuickNotes extends _$QuickNotes {
  @override
  Future<(QuickNote?, String)> build() async {
    return await requestFrom("/cyber/note/last", QuickNote.fromJson);
  }

  Future<String> setNote(String content) async {
    const url = "$endpoint/cyber/note";
    final r = await post(Uri.parse(url),
        headers: config.cyberBase64JsonContentHeader,
        body: jsonEncode({
          "content": content,
          "from": "CyberMe Flutter",
          "liveSeconds": 100
        }));
    final d = jsonDecode(r.body);
    return d["message"]?.toString() ?? "未知错误";
  }
}
