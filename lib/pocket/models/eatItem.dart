import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

/// id : "1f4f8b88-e97b-4d12-ad30-7893f3aeca0a"
/// date : "2023-10-13 14:21:03"
/// calories : 223
/// note : ""
/// image : ""
/// tag : ["蔬菜"]

class EatItem {
  EatItem({
    String? id,
    String? date,
    num? calories,
    String? name,
    String? note,
    String? image,
    List<String>? tag,
  }) {
    _id = id;
    _date = date;
    _calories = calories;
    _name = name;
    _note = note;
    _image = image;
    _tag = tag;
    if (_date != null) {
      try {
        dateTime = DateFormat("yyyy-MM-dd HH:mm:ss").parse(_date!);
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  EatItem.fromJson(dynamic json) {
    _id = json['id'];
    _date = json['date'];
    _calories = json['calories'];
    _name = json['name'];
    _note = json['note'];
    _image = json['image'];
    _tag = json['tag'] != null ? json['tag'].cast<String>() : [];
    if (_date != null) {
      try {
        dateTime = DateFormat("yyyy-MM-dd HH:mm:ss").parse(_date!);
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  String? _id;
  String? _date;
  DateTime? dateTime;
  num? _calories;
  String? _name;
  String? _note;
  String? _image;
  List<String>? _tag;

  EatItem copyWith({
    String? id,
    String? date,
    num? calories,
    String? note,
    String? image,
    List<String>? tag,
  }) =>
      EatItem(
        id: id ?? _id,
        date: date ?? _date,
        calories: calories ?? _calories,
        note: note ?? _note,
        image: image ?? _image,
        tag: tag ?? _tag,
      );

  String? get id => _id;

  String? get date => _date;

  num? get calories => _calories;

  String? get name => _name;

  String? get note => _note;

  String? get image => _image;

  List<String>? get tag => _tag;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['date'] = _date;
    map['calories'] = _calories;
    map['name'] = _name;
    map['note'] = _note;
    map['image'] = _image;
    map['tag'] = _tag;
    return map;
  }
}
