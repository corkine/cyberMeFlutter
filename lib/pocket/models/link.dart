import 'dart:convert';

import 'package:http/http.dart' as http;

/// 短链接 Bean 数据类
class Link {
  final int id;
  final String keyword;
  final String redirectURL;
  final String note;
  final DateTime updateTime;
  final String? password;

  Link(
      {required this.id,
        required this.keyword,
        required this.redirectURL,
        required this.note,
        required this.updateTime})
      : password = keyword.startsWith('MS') && keyword.endsWith('MS')
      ? keyword.replaceAll('MS', '')
      : null;

  Link.fromJSON({required Map map})
      : id = map['id'],
        keyword = map['keyword'],
        redirectURL = (map['redirectURL'] != null &&
            (!map['redirectURL'].toString().startsWith('http://') &&
                !map['redirectURL'].toString().startsWith('https://')))
            ? 'http://' + map['redirectURL']
            : map['redirectURL'],
        note = map['note'],
        updateTime = DateTime.parse(map['updateTime']),
        password = map['note'] != null &&
            map['note'].startsWith('MS') &&
            map['note'].endsWith('MS')
            ? map['note'].replaceAll('MS', '')
            : null;

  @override
  String toString() => '$id - $keyword';
}

/// 短链接服务提供者
class LinkRepository {
  static Future<List<Link>> fetch() async {
    var data = http
        .get(Uri.parse(
        'https://go.mazhangjing.com/list?user=corkine&password=mzj960032'))
        .then((value) {
      var data = jsonDecode(const Utf8Codec().decode(value.bodyBytes));
      return (data as List<dynamic>)
          .map((item) => Link.fromJSON(map: item))
          .toList();
    });
    return data;
  }
}
