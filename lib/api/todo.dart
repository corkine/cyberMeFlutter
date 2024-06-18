import 'dart:convert';

import 'package:cyberme_flutter/api/basic.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pocket/config.dart';
import '../pocket/models/todo.dart';

part 'todo.freezed.dart';
part 'todo.g.dart';

@riverpod
class TodoDB extends _$TodoDB {
  int indent = 0;
  int step = 60;

  Future<List<Todo>> fetch(int indent, int step) async {
    final url = Uri.parse(Config.todoUrl(indent, indent + step));
    debugPrint("req for $url");
    final r = await get(url, headers: config.cyberBase64Header);
    final d = jsonDecode(r.body);
    final s = d["status"] as int? ?? -1;
    if (s <= 0) {
      debugPrint("error fetch todo");
      return [];
    }
    final c = (d["data"] as Map).map((k, v) {
      final date = k as String;
      final todos = v as List;
      return MapEntry(
          date, todos.map((e) => Todo.fromJson(e)).toList(growable: false));
    });
    return c.values.expand((element) => element).toList();
  }

  Future<void> fetchUpdate(int indent, int step) async {
    final res = await fetch(indent, step);
    state = AsyncData(res);
  }

  @override
  Future<List<Todo>> build() async {
    final data = await fetch(0, step);
    indent = indent + step;
    return data;
  }

  Future<String> fetchNext() async {
    final data = await fetch(indent, step);
    indent = indent + step;
    state = AsyncData([...?state.value, ...data]);
    return "获取 $indent - ${indent + step} 数据成功";
  }

  Future<String> sync({bool updateList = false}) async {
    final resp = await get(Uri.parse(Config.todoSyncUrl),
        headers: config.cyberBase64Header);
    final msg = jsonDecode(resp.body)["message"];
    if (updateList) {
      await fetchUpdate(0, indent);
    }
    return msg;
  }

  Future<String> addTodo(
      {required String title,
      required String due,
      bool finished = false,
      required String listName,
      bool updateList = false}) async {
    if (listName.isEmpty) {
      return "添加失败，列表名或列表 Id 不能为空";
    }
    final listId = (state.valueOrNull ?? [])
        .where((t) => t.list == listName)
        .firstOrNull
        ?.listId;
    if (listId == null) {
      return "添加失败，列表 Id 找不到";
    }
    final (_, msg) = await postFrom("/cyber/todo/ms-todo", {
      "list-id": listId,
      "list-name": listName,
      "title": title,
      "due": due,
      "finished": finished
    });
    if (updateList) {
      await fetchUpdate(0, indent);
    }
    return msg;
  }

  Future<String> deleteTodo(
      {required String listId,
      required String taskId,
      bool updateList = false}) async {
    if (listId.isEmpty || taskId.isEmpty) {
      return "删除失败，列表和任务 Id 均不能为空";
    }
    final (_, msg) = await deleteFrom(
        "/cyber/todo/ms-todo", {"list": listId, "task": taskId});
    if (updateList) {
      await fetchUpdate(0, indent);
    }
    return msg;
  }

  Future<String> makeTodo(
      {required String listId,
      required String taskId,
      bool? completed,
      String? title,
      bool updateList = false}) async {
    if (listId.isEmpty || taskId.isEmpty) {
      return "更新失败，列表和任务 Id 均不能为空";
    }
    if (completed == null && title == null) {
      return "更新失败，至少需要设置一个参数";
    }
    final (_, msg) = await patchFrom("/cyber/todo/ms-todo", {
      "list": listId,
      "task": taskId,
      "title": title,
      "completed": completed
    });
    if (updateList) {
      await fetchUpdate(0, indent);
    }
    return msg;
  }
}

@riverpod
List<String> todoLists(TodoListsRef ref) {
  final res = ref.watch(todoDBProvider).valueOrNull ?? [];
  return res
      .map((e) => e.list)
      .toSet()
      .where((e) => e != null)
      .map((e) => e!)
      .toList(growable: false);
}

@freezed
class TodoSetting with _$TodoSetting {
  factory TodoSetting(
      {@Default(false) bool useListSort,
      @Default(false) bool useWeekGroup}) = _TodoSetting;

  factory TodoSetting.fromJson(Map<String, dynamic> json) =>
      _$TodoSettingFromJson(json);
}

@riverpod
class TodoSettings extends _$TodoSettings {
  final key = "todo-setting";
  @override
  FutureOr<TodoSetting> build() async {
    final s = await SharedPreferences.getInstance();
    return TodoSetting.fromJson(jsonDecode(s.getString(key) ?? "{}"));
  }

  Future save(TodoSetting Function(TodoSetting) trans) async {
    final s = await SharedPreferences.getInstance();
    final n = trans(state.valueOrNull ?? TodoSetting());
    await s.setString(key, jsonEncode(n.toJson()));
    state = AsyncData(n);
  }
}
