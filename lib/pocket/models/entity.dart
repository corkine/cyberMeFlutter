class EntityLog {
  String iPInfo;
  String keyword;
  String url;
  int entityId;
  String visitorIP;
  DateTime actionTime;
  EntityLog.fromJSON(Map<String, dynamic> map)
      : iPInfo = _fetchInfo(map),
        keyword = map['keyword'],
        url = map['url'],
        entityId = int.tryParse(map['entityLog']['entityId'].toString())!,
        visitorIP = map['entityLog']['visitorIP'],
        actionTime = DateTime.parse(map['entityLog']['actionTime']);
  static String _fetchInfo(Map<String, dynamic> map) {
    var data = map['ipInfo']
        .toString()
        .replaceAll('|', ' ')
        .replaceFirst('0', '')
        .replaceFirst('中国', '')
        .trimLeft();
    var list = data.split(' ');
    if (list.length >= 2 && list[1].contains(list[0])) {
      list.removeAt(0);
      return list.join(' ');
    } else {
      return data;
    }
  }
}

class Entity {
  String keyword;
  String redirectURL;
  String note;
  DateTime updateTime;
  int id;
  String? password;
  Entity.fromJSON(Map<String, dynamic> map)
      : keyword = map['keyword'],
        redirectURL = map['redirectURL'],
        note = map['note'],
        updateTime = DateTime.parse(map['updateTime']),
        id = int.parse(map['id'].toString()),
        password = _parsePassword(map);
  static _parsePassword(Map<String, dynamic> map) {
    final ans = map['note'].toString();
    if (ans.startsWith('MS') && ans.endsWith('MS')) {
      return ans.substring(2, ans.length - 2);
    } else {
      return null;
    }
  }
}