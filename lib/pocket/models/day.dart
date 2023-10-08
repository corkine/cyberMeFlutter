import 'package:cyberme_flutter/pocket/day.dart';
import 'package:flutter/foundation.dart';
import 'package:cyberme_flutter/pocket/models/diary.dart' as real_diary;
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:sprintf/sprintf.dart';
import 'dart:convert';

import '../config.dart';
import '../time.dart';
import 'plant.dart';

///快递数据
class Express {
  String id;
  String name;
  int status;
  String lastUpdate;
  String info;

  List<(String, String)> extra;

//<editor-fold desc="Data Methods">

  Express(
      {required this.id,
      required this.name,
      required this.status,
      required this.lastUpdate,
      required this.info,
      required this.extra});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Express &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              name == other.name &&
              status == other.status &&
              lastUpdate == other.lastUpdate &&
              info == other.info) &&
          extra == other.extra;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      status.hashCode ^
      lastUpdate.hashCode ^
      info.hashCode ^
      extra.hashCode;

  @override
  String toString() {
    return 'Express{' +
        ' id: $id,' +
        ' name: $name,' +
        ' status: $status,' +
        ' last_update: $lastUpdate,' +
        ' info: $info,' +
        ' extra: $extra,' +
        '}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': this.id,
      'name': this.name,
      'status': this.status,
      'last_update': this.lastUpdate,
      'info': this.info,
    };
  }

  factory Express.fromMap(Map<String, dynamic> map) {
    return Express(
        id: map['id'] as String,
        name: map['name'] as String,
        status: map['status'] as int,
        lastUpdate: map['last_update'] as String,
        info: map['info'] as String,
        extra: map['extra'] is String
            ? []
            : ((map['extra'] as List?) ?? [])
                .map((e) => e as Map?)
                .map((e) => (
                      (e?["time"] as String?) ?? "无日期",
                      (e?["status"] as String?) ?? "无状态"
                    ))
                .toList(growable: false));
  }

//</editor-fold>
}

///工作数据
class Work {
  bool NeedWork;
  bool OffWork;
  bool NeedMorningCheck;
  double WorkHour;
  dynamic SignIn;
  dynamic Policy;

  bool get existPolicy => Policy["exist"];

  int get policyPending => Policy["pending"];

  int get policyFailed => Policy["failed"];

  int get policySuccess => Policy["success"];

  int get policyCount => Policy["policy-count"];

  List<String> signData() {
    List<String> result = [];
    for (var e in (SignIn as List)) {
      //2022-05-05T08:27:21
      var time = e["time"];
      if (time != null) {
        result.add("# " +
            (RegExp(r".*?T(\d\d:\d\d):\d\d").firstMatch(time)?.group(1) ??
                "00:00"));
      }
    }
    return result;
  }

//<editor-fold desc="Data Methods">

  Work({
    required this.NeedWork,
    required this.OffWork,
    required this.NeedMorningCheck,
    required this.WorkHour,
    required this.SignIn,
    required this.Policy,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Work &&
          runtimeType == other.runtimeType &&
          NeedWork == other.NeedWork &&
          OffWork == other.OffWork &&
          NeedMorningCheck == other.NeedMorningCheck &&
          WorkHour == other.WorkHour &&
          SignIn == other.SignIn &&
          Policy == other.Policy);

  @override
  int get hashCode =>
      NeedWork.hashCode ^
      OffWork.hashCode ^
      NeedMorningCheck.hashCode ^
      WorkHour.hashCode ^
      SignIn.hashCode ^
      Policy.hashCode;

  @override
  String toString() {
    return 'Work{' +
        ' NeedWork: $NeedWork,' +
        ' OffWork: $OffWork,' +
        ' NeedMorningCheck: $NeedMorningCheck,' +
        ' WorkHour: $WorkHour,' +
        ' SignIn: $SignIn,' +
        ' Policy: $Policy,' +
        '}';
  }

  Work copyWith({
    bool? NeedWork,
    bool? OffWork,
    bool? NeedMorningCheck,
    double? WorkHour,
    dynamic? SignIn,
    dynamic? Policy,
  }) {
    return Work(
      NeedWork: NeedWork ?? this.NeedWork,
      OffWork: OffWork ?? this.OffWork,
      NeedMorningCheck: NeedMorningCheck ?? this.NeedMorningCheck,
      WorkHour: WorkHour ?? this.WorkHour,
      SignIn: SignIn ?? this.SignIn,
      Policy: Policy ?? this.Policy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'NeedWork': this.NeedWork,
      'OffWork': this.OffWork,
      'NeedMorningCheck': this.NeedMorningCheck,
      'WorkHour': this.WorkHour,
      'SignIn': this.SignIn,
      'Policy': this.Policy,
    };
  }

  factory Work.fromMap(Map<String, dynamic> map) {
    return Work(
      NeedWork: map['NeedWork'] as bool,
      OffWork: map['OffWork'] as bool,
      NeedMorningCheck: map['NeedMorningCheck'] as bool,
      WorkHour: map['WorkHour'] as double,
      SignIn: map['SignIn'] as dynamic,
      Policy: map['Policy'] as dynamic,
    );
  }

//</editor-fold>
}

///健身数据
class Fitness {
  double active;
  double rest;
  double goal_active;
  double goal_cut;

//<editor-fold desc="Data Methods">

  Fitness({
    required this.active,
    required this.rest,
    required this.goal_active,
    required this.goal_cut,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Fitness &&
          runtimeType == other.runtimeType &&
          active == other.active &&
          rest == other.rest &&
          goal_active == other.goal_active &&
          goal_cut == other.goal_cut);

  @override
  int get hashCode =>
      active.hashCode ^
      rest.hashCode ^
      goal_active.hashCode ^
      goal_cut.hashCode;

  @override
  String toString() {
    return 'Fitness{' +
        ' active: $active,' +
        ' rest: $rest,' +
        ' goal-active: $goal_active,' +
        ' goal-cut: $goal_cut,' +
        '}';
  }

  Fitness copyWith({
    double? active,
    double? rest,
    double? goal_active,
    double? goal_cut,
  }) {
    return Fitness(
      active: active ?? this.active,
      rest: rest ?? this.rest,
      goal_active: goal_active ?? this.goal_active,
      goal_cut: goal_cut ?? this.goal_cut,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'active': this.active,
      'rest': this.rest,
      'goal-active': this.goal_active,
      'goal-cut': this.goal_cut,
    };
  }

  factory Fitness.fromMap(Map<String, dynamic> map) {
    var a = map['active'];
    return Fitness(
      active: a is int ? a.toDouble() : a,
      rest: double.parse(map['rest'].toString()),
      goal_active: double.parse(map['goal-active'].toString()),
      goal_cut: double.parse(map['goal-cut'].toString()),
    );
  }

//</editor-fold>
}

///待办事项
class Todo {
  String modified_at;
  String time;
  String? finish_at;
  String title;
  String list;
  String? due_at;
  String create_at;
  String importance;

//<editor-fold desc="Data Methods">

  Todo({
    required this.modified_at,
    required this.time,
    required this.finish_at,
    required this.title,
    required this.list,
    required this.due_at,
    required this.create_at,
    required this.importance,
  });

  bool get isImportant => importance == "high";

  bool get isFinish => finish_at != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Todo &&
          runtimeType == other.runtimeType &&
          modified_at == other.modified_at &&
          time == other.time &&
          finish_at == other.finish_at &&
          title == other.title &&
          list == other.list &&
          due_at == other.due_at &&
          create_at == other.create_at &&
          importance == other.importance);

  @override
  int get hashCode =>
      modified_at.hashCode ^
      time.hashCode ^
      finish_at.hashCode ^
      title.hashCode ^
      list.hashCode ^
      due_at.hashCode ^
      create_at.hashCode ^
      importance.hashCode;

  @override
  String toString() {
    return 'Todo{' +
        ' modified_at: $modified_at,' +
        ' time: $time,' +
        ' finish_at: $finish_at,' +
        ' title: $title,' +
        ' list: $list,' +
        ' due_at: $due_at,' +
        ' create_at: $create_at,' +
        ' importance: $importance,' +
        '}';
  }

  Todo copyWith({
    String? modified_at,
    String? time,
    String? finish_at,
    String? title,
    String? list,
    String? due_at,
    String? create_at,
    String? importance,
  }) {
    return Todo(
      modified_at: modified_at ?? this.modified_at,
      time: time ?? this.time,
      finish_at: finish_at ?? this.finish_at,
      title: title ?? this.title,
      list: list ?? this.list,
      due_at: due_at ?? this.due_at,
      create_at: create_at ?? this.create_at,
      importance: importance ?? this.importance,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'modified_at': modified_at,
      'time': time,
      'finish_at': finish_at,
      'title': title,
      'list': list,
      'due_at': due_at,
      'create_at': create_at,
      'importance': importance,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      modified_at: map['modified_at'] as String,
      time: map['time'] as String,
      finish_at: map['finish_at'] as String?,
      title: map['title'] as String,
      list: map['list'] as String,
      due_at: map['due_at'] as String?,
      create_at: map['create_at'] as String,
      importance: map['importance'] as String,
    );
  }

//</editor-fold>
}

///总的 Dashboard 主页入口
class Dashboard {
  List<Express> express;
  Work work;
  dynamic todo;
  dynamic score;
  Fitness fitness;
  String? dayWork;
  List<real_diary.Diary> diaries = [];
  Plant plantInfo = Plant();

  String get dayWorkString => dayWork ?? "没有日报";

  bool get alertMorningDayWork => dayWork == null;

  bool get alertNightDayWork {
    var now = DateTime.now();
    if (!work.OffWork &&
        ((now.hour > 16 && now.hour <= 23) ||
            (now.hour == 16 && now.minute >= 30))) return true;
    return false;
  }

//<editor-fold desc="Data Methods">

  Dashboard(
      {required this.express,
      required this.work,
      required this.todo,
      required this.score,
      required this.fitness});

  Map<String, dynamic> toMap() {
    return {
      'express': express,
      'work': work,
      'todo': todo,
      'score': score,
      'fitness': fitness
    };
  }

  factory Dashboard.fromMap(Map<String, dynamic> map) {
    return Dashboard(
      express: (map["express"] as List).map((e) => Express.fromMap(e)).toList(),
      work: Work.fromMap(map['work']),
      todo: map['todo'],
      score: map['score'],
      fitness: Fitness.fromMap(map['fitness']),
    );
  }

//</editor-fold>

  ///获取今日带星标的待办事项，按照是否完成和时间排序
  List<Todo> get todayTodo {
    if (todo[TimeUtil.today] == null) return [];
    return (todo[TimeUtil.today] as List)
        .map((e) => Todo.fromMap(e))
        .where((element) => element.isImportant)
        .toList()
      ..sort((a, b) {
        if (a.isFinish && !b.isFinish) return 1;
        if (b.isFinish && !a.isFinish) {
          return -1;
        } else {
          return a.time.compareTo(b.time);
        }
      });
  }

  ///获取今日所有的待办事项，包括没有带星标的
  List<Todo> get todayAllTodo {
    return (todo[TimeUtil.today] as List).map((e) => Todo.fromMap(e)).toList();
  }

  int get cleanCount => 0;

  int get cleanMarvelCount => 0;

  double get cleanPercentInRange {
    if (cleanMarvelCount == 0) return 0;
    final res = cleanCount / cleanMarvelCount;
    return res <= 1.0 ? res : 1.0;
  }

  int get noBlueCount => 0;

  int get noBlueMarvelCount => 0;

  double get noBluePercentInRange {
    if (noBlueMarvelCount == 0) return 0;
    final res = noBlueCount / noBlueMarvelCount;
    return res <= 1.0 ? res : 1.0;
  }

  ///强制同步 Microsoft TO DO 待办事项
  static Future<String> focusSyncTodo(Config config) async {
    try {
      print("Sync with Todo now..");
      var resp = await get(Uri.parse(Config.todoSyncUrl),
          headers: config.cyberBase64Header);
      return jsonDecode(resp.body)["message"];
    } on Exception catch (e) {
      return e.toString();
    }
  }

  ///强制同步 HCM 打卡数据
  static Future<String> checkHCMCard(Config config) async {
    try {
      print("Checking HCM now..");
      var resp = await get(Uri.parse(Config.hcmCardCheckUrl),
          headers: config.cyberBase64Header);
      //刷新 API 以获取最新更改
      config.justNotify();
      return resp.body;
    } on Exception catch (e) {
      return e.toString();
    }
  }

  ///设置 Clean 数据
  static Future<String> setClean(Config config) async {
    var now = DateTime.now().hour;
    var isMorningTime = now >= 4 && now <= 18;
    var isYesterday = now < 4;
    try {
      print("Setting clean data, isMorning? $isMorningTime");
      var url = isMorningTime ? Config.morningCleanUrl : Config.nightCleanUrl;
      if (isYesterday) {
        url = url + "&yesterday=true";
        print("is midnight, use yesterday!!!");
      }
      var resp = await get(Uri.parse(url), headers: config.cyberBase64Header);
      config.justNotify();
      return jsonDecode(resp.body)["message"];
    } on Exception catch (e) {
      return e.toString();
    }
  }

  ///设置 Blue 数据
  static Future<String> setBlue(Config config, String date) async {
    try {
      print("Setting blue data, date: $date");
      var resp = await get(Uri.parse(Config.blueUrl + date),
          headers: config.cyberBase64Header);
      config.justNotify();
      return jsonDecode(resp.body)["message"];
    } on Exception catch (e) {
      return e.toString();
    }
  }

  ///获取最后一条笔记
  static Future<List<String?>> fetchLastNote(Config config) async {
    try {
      print("fetching last note...");
      var resp = await get(Uri.parse(Config.lastNoteUrl),
          headers: config.cyberBase64Header);
      var data = jsonDecode(resp.body);
      return [data["message"], data["data"] != null ? data["message"] : null];
    } on Exception catch (e) {
      return [e.toString(), null];
    }
  }

  ///上传一条笔记
  static Future<String> uploadOneNote(Config config, String content) async {
    try {
      print("uploading one note... length ${content.length}");
      var resp = await http.post(Uri.parse(Config.uploadNoteUrl),
          headers: config.cyberBase64Header
            ..addAll({"Content-Type": "application/json"}),
          body: jsonEncode({
            "from": "CyberMe Flutter Client",
            "content": content,
            "liveSeconds": 300
          }));
      var data = jsonDecode(resp.body);
      return data["message"];
    } on Exception catch (e) {
      return e.toString();
    }
  }

  ///从 API 加载大屏数据
  static Future<Dashboard?> loadFromApi(Config config) async {
    if (kDebugMode) {
      print("Loading from CyberMe... from user: ${config.user}");
    }
    final Response r = await get(Uri.parse(Config.dashboardUrl),
        headers: config.cyberBase64Header);
    final data = jsonDecode(r.body);
    DayInfo.debugInfo = sprintf("%s:%s\n", ["Config", config.toString()]);
    DayInfo.debugInfo += sprintf("%s, %s, %s, %s",
        [r.headers, r.body.substring(0, 20), r.request, r.statusCode]);
    if (data["message"].toString().contains("access denied") && kDebugMode) {
      print("response no auth: ${data.toString()}");
      return null;
    }
    final dashInfo = Dashboard.fromMap(data["data"]);
    final workResult = await get(Uri.parse(Config.dayWorkUrl),
        headers: config.cyberBase64Header);
    final workData = jsonDecode(workResult.body)["data"];
    dashInfo.dayWork = workData as String?;
    dashInfo.diaries = await real_diary.DiaryManager.loadFromApi(config);
    dashInfo.plantInfo = await Plant.loadFromApi(config);
    return dashInfo;
  }
}
