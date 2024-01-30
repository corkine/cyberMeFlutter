import 'package:cyberme_flutter/api/basic.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'todo.g.dart';

@riverpod
class Todos extends _$Todos {
  @override
  FutureOr<bool> build() async {
    return true;
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
