import 'package:cyberme_flutter/api/basic.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'todo.g.dart';

@riverpod
class Todos extends _$Todos {
  @override
  FutureOr<String> build() async {
    final s = await SharedPreferences.getInstance();
    final url = s.getString("todo-script-path") ?? "";
    return url;
  }

  Future updatePath(String newPath) async {
    final s = await SharedPreferences.getInstance();
    await s.setString("todo-script-path", newPath);
    state = AsyncData(newPath);
  }

  Future<String> addTodo(
      {required String title,
      required String due,
      bool finished = false,
      required String listName,
      required String listId}) async {
    if (listName.isEmpty || listId.isEmpty) {
      return "添加失败，列表名或列表 Id 不能为空";
    }
    final (_, msg) = await postFrom("/cyber/todo/ms-todo", {
      "list-id": listId,
      "list-name": listName,
      "title": title,
      "due": due,
      "finished": finished
    });
    return msg;
  }

  Future<String> makeTodo(
      {required String listId,
      required String taskId,
      required bool completed}) async {
    if (listId.isEmpty || taskId.isEmpty) {
      return "更新失败，列表和任务 Id 均不能为空";
    }
    final (_, msg) = await patchFrom("/cyber/todo/ms-todo",
        {"list": listId, "task": taskId, "completed": completed});
    return msg;
  }

  Future<String> deleteTodo(
      {required String listId, required String taskId}) async {
    if (listId.isEmpty || taskId.isEmpty) {
      return "删除失败，列表和任务 Id 均不能为空";
    }
    final (_, msg) = await deleteFrom(
        "/cyber/todo/ms-todo", {"list": listId, "task": taskId});
    return msg;
  }
}
