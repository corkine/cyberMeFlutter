import 'package:intl/intl.dart';

/// modified_at : "2023-09-17T18:56:31.409994"
/// checklistitems : null
/// time : "2023-09-16"
/// finish_at : "2023-09-17T08:00:00"
/// title : "王燕青实验四开发完毕"
/// list : "📑 技术"
/// status : "completed"
/// due_at : "2023-09-16T00:00:00"
/// create_at : "2023-09-17T18:56:00.708762"
/// importance : "normal"
/// id: '',
/// list_id: ""

class Todo {
  Todo({
    String? modifiedAt,
    dynamic checklistitems,
    String? time,
    String? finishAt,
    String? title,
    String? list,
    String? status,
    String? dueAt,
    String? createAt,
    String? importance,
    String? id,
    String? listId,
  }) {
    _modifiedAt = modifiedAt;
    _checklistitems = checklistitems;
    _time = time;
    _finishAt = finishAt;
    _title = title;
    _list = list;
    _status = status;
    _dueAt = dueAt;
    _createAt = createAt;
    _importance = importance;
    _id = id;
    _listId = listId;
    date = _time != null ? DateFormat("yyyy-MM-dd").parse(_time!) : null;
  }

  @override
  String toString() {
    return 'Todo{_id: $_id, _listId: $_listId, _modifiedAt: $_modifiedAt, _checklistitems: $_checklistitems, _time: $_time, _finishAt: $_finishAt, _title: $_title, _list: $_list, _status: $_status, _dueAt: $_dueAt, _createAt: $_createAt, _importance: $_importance}';
  }

  Todo.fromJson(dynamic json) {
    _modifiedAt = json['modified_at'];
    _checklistitems = json['checklistitems'];
    _time = json['time'];
    _finishAt = json['finish_at'];
    _title = json['title'];
    _list = json['list'];
    _status = json['status'];
    _dueAt = json['due_at'];
    _createAt = json['create_at'];
    _importance = json['importance'];
    _id = json['id'] ?? "";
    _listId = json['list_id'] ?? "";
    date = _time != null ? DateFormat("yyyy-MM-dd").parse(_time!) : null;
  }

  String? _modifiedAt;
  dynamic _checklistitems;
  String? _time;
  String? _finishAt;
  String? _title;
  String? _list;
  String? _status;
  String? _dueAt;
  String? _createAt;
  String? _importance;
  DateTime? date;
  String? _id;
  String? _listId;

  Todo copyWith(
          {String? modifiedAt,
          dynamic checklistitems,
          String? time,
          String? finishAt,
          String? title,
          String? list,
          String? status,
          String? dueAt,
          String? createAt,
          String? importance,
          String? id,
          String? listId}) =>
      Todo(
          modifiedAt: modifiedAt ?? _modifiedAt,
          checklistitems: checklistitems ?? _checklistitems,
          time: time ?? _time,
          finishAt: finishAt ?? _finishAt,
          title: title ?? _title,
          list: list ?? _list,
          status: status ?? _status,
          dueAt: dueAt ?? _dueAt,
          createAt: createAt ?? _createAt,
          importance: importance ?? _importance,
          id: id ?? _id,
          listId: listId ?? _listId);

  String? get modifiedAt => _modifiedAt;

  dynamic get checklistitems => _checklistitems;

  String? get time => _time;

  String? get finishAt => _finishAt;

  String? get title => _title;

  String? get list => _list;

  String? get status => _status;

  bool get isCompleted => _status == "completed";

  String? get dueAt => _dueAt;

  String? get createAt => _createAt;

  String? get importance => _importance;

  String? get id => _id;

  String? get listId => _listId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['modified_at'] = _modifiedAt;
    map['checklistitems'] = _checklistitems;
    map['time'] = _time;
    map['finish_at'] = _finishAt;
    map['title'] = _title;
    map['list'] = _list;
    map['status'] = _status;
    map['due_at'] = _dueAt;
    map['create_at'] = _createAt;
    map['importance'] = _importance;
    map['id'] = _id;
    map['list_id'] = _listId;
    return map;
  }
}
