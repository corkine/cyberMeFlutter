import '../config.dart';

class Good {
  String id;
  String name;
  String? description;
  String currentState;
  String? currentStateEn;
  String? importance;
  String? place;
  String? message;
  String? picture;
  DateTime addTime;
  DateTime updateTime;

  Good(
      this.id,
      this.name,
      this.description,
      this.currentState,
      this.currentStateEn,
      this.importance,
      this.place,
      this.message,
      this.picture,
      this.addTime,
      this.updateTime);

  Good.fromJSON(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'],
        description = map['description'],
        currentStateEn = map['currentState'],
        currentState = _handleState(map),
        importance = map['importance'],
        place = map['place'],
        picture = _handlePicture(map),
        message = map['message'],
        addTime = DateTime.parse(map['addTime']),
        updateTime = DateTime.parse(map['updateTime']);

  static Good justForNew = Good("", "", "", "", "", "", "", "", "",
      DateTime.parse("2000-01-01"), DateTime.parse("2000-01-01"));

  static _handlePicture(Map<String, dynamic> map) {
    final res = map['picture'].toString().replaceFirst('http://', 'https://');
    if (res.isEmpty || res.trim() == 'null') {
      return null;
    } else {
      return res;
    }
  }

  static _handleState(Map<String, dynamic> map) {
    final res = map['currentState'].toString();
    if (res.isEmpty || res.trim() == 'null') return null;
    switch (res.toUpperCase()) {
      case 'ACTIVE':
        return '活跃';
      case 'ARCHIVE':
        return '收纳';
      case 'ORDINARY':
        return '普通';
      case 'BORROW':
        return '外借';
      default:
        return res;
    }
  }

  static compare(Config c, Good a, Good b) {
    final imp = a.importance!.compareTo(b.importance!);
    if (imp != 0) return imp; //最重要在前
    final cus = _status(a.currentStateEn!) - _status(b.currentStateEn!);
    if (cus != 0) {
      return cus;
    } else {
      return 1 * ((c.map[a.id] ?? 0).compareTo(c.map[b.id] ?? 0));
    }
  }

  static _status(String cs) {
    final css = cs.toUpperCase();
    switch (css) {
      case 'ACTIVE':
        return 1;
      case 'ORDINARY':
        return 2;
      case 'NOTACTIVE':
        return 3;
      case 'ARCHIVE':
        return 4;
      case 'REMOVE':
        return 5;
      case 'BORROW':
        return 6;
      case 'LOST':
        return 7;
      default:
        return 8;
    }
  }
}
