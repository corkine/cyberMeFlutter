import 'dart:convert';

import 'package:cyberme_flutter/pocket/models/todo.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config.dart';

class TodoView extends StatefulWidget {
  const TodoView({super.key});

  @override
  State<TodoView> createState() => _TodoViewState();
}

class _TodoViewState extends State<TodoView>
    with SingleTickerProviderStateMixin {
  Config? config;
  int start = 0;
  int end = 30;
  Map<String, List<Todo>> data = {};
  List<Todo> todo = [];
  Map<String, List<Todo>> todoMap = {};
  List<Todo> todoFiltered = [];
  Set<String> lists = {};
  Set<String> selectLists = {};

  TabController? tc;
  bool useTab = true;
  late DateTime weekDayOne;

  @override
  void initState() {
    final now = DateTime.now();
    weekDayOne = now.subtract(Duration(
        days: now.weekday - 1,
        hours: now.hour,
        minutes: now.minute,
        seconds: now.second,
        milliseconds: now.millisecond,
        microseconds: now.microsecond));
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (config == null) {
      config = Provider.of<Config>(context);
      fetchTodo().then((value) => setState(() {}));
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: buildAppBar(),
        body: useTab ? (tc == null ? null : buildTabView()) : buildListView());
  }

  Column buildTabView() {
    return Column(mainAxisSize: MainAxisSize.max, children: [
      Expanded(
          child: TabBarView(
              children: lists.map((e) {
                final tl = todoMap[e]!;
                return ListView.builder(
                    itemBuilder: (c, i) {
                      final t = tl[i];
                      return ListTile(
                          title: Text(t.title ?? "",
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.black)),
                          subtitle: Padding(
                              padding: const EdgeInsets.only(top: 7),
                              child: DefaultTextStyle(
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black),
                                  child: Row(children: [
                                    Text(t.list ?? ""),
                                    const Spacer(),
                                    dateRich(t.date)
                                  ]))));
                    },
                    itemCount: tl.length);
              }).toList(growable: false),
              controller: tc)),
      TabBar(
          labelPadding: const EdgeInsets.only(bottom: 10, top: 10),
          tabs: lists.map((e) => Text(e)).toList(growable: false),
          controller: tc)
    ]);
  }

  Widget buildListView() {
    final tl = todoFiltered;
    return ListView.builder(
        itemBuilder: (c, i) {
          final t = tl[i];
          return ListTile(
              title: Text(t.title ?? "",
                  style: const TextStyle(fontSize: 15, color: Colors.black)),
              subtitle: Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: DefaultTextStyle(
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                    child: Row(children: [
                      Text(t.list ?? ""),
                      const Spacer(),
                      dateRich(t.date)
                    ]),
                  )));
        },
        itemCount: tl.length);
  }

  AppBar buildAppBar() {
    return AppBar(title: const Text("待办事项"), centerTitle: true, actions: [
      IconButton(
          onPressed: () => setState(() => useTab = !useTab),
          icon: useTab
              ? const RotatedBox(
                  quarterTurns: 2, child: Icon(Icons.table_chart_sharp))
              : const Icon(Icons.format_list_bulleted)),
      PopupMenuButton(
          itemBuilder: (c) {
            return lists
                .map((e) => PopupMenuItem(
                    child: Row(
                      children: [
                        Opacity(
                            opacity: selectLists.contains(e) ? 1 : 0,
                            child: const Icon(Icons.check)),
                        const SizedBox(width: 4),
                        Text(e)
                      ],
                    ),
                    onTap: () {
                      if (selectLists.contains(e)) {
                        selectLists.remove(e);
                      } else {
                        selectLists.add(e);
                      }
                      setState(() {});
                      updateFiltered();
                    }))
                .toList(growable: false);
          },
          icon: const Icon(Icons.filter_alt))
    ]);
  }

  Widget dateRich(DateTime? date) {
    if (date == null) return const Text("未知日期");
    final df = DateFormat("yyyy-MM-dd");
    bool thisWeek = weekDayOne.isBefore(date);
    final style = TextStyle(color: thisWeek ? Colors.green : Colors.black);
    switch (date.weekday) {
      case 1:
        return Text("${df.format(date)} 周一", style: style);
      case 2:
        return Text("${df.format(date)} 周二", style: style);
      case 3:
        return Text("${df.format(date)} 周三", style: style);
      case 4:
        return Text("${df.format(date)} 周四", style: style);
      case 5:
        return Text("${df.format(date)} 周五", style: style);
      case 6:
        return Text("${df.format(date)} 周六", style: style);
      default:
        return Text("${df.format(date)} 周日", style: style);
    }
  }

  updateFiltered() {
    todoFiltered = selectLists.isEmpty
        ? todo
        : todo
            .where((element) => selectLists.contains(element.list))
            .toList(growable: false);
    setState(() {});
  }

  Future fetchTodo() async {
    final r = await get(Uri.parse(Config.todoUrl(start, end)),
        headers: config!.cyberBase64Header);
    final d = jsonDecode(r.body);
    final m = d["message"] ?? "";
    final s = d["status"] as int? ?? -1;
    if (s <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
      return;
    }
    data = (d["data"] as Map).map((k, v) {
      final date = k as String;
      final todos = v as List;
      return MapEntry(
          date, todos.map((e) => Todo.fromJson(e)).toList(growable: false));
    });
    todo = [];
    for (final t in data.values) {
      todo.addAll(t);
      for (final tt in t) {
        if (!lists.contains(tt.list) && tt.list != null) {
          lists.add(tt.list!);
        }
        //添加到 map
        final origin = todoMap[tt.list!];
        if (origin != null) {
          todoMap[tt.list!]!.add(tt);
        } else {
          todoMap[tt.list!] = [tt];
        }
      }
    }
    todo.sort((t2, t1) {
      return t1.time?.compareTo(t2.time ?? "") ?? 0;
    });
    //执行 filter
    updateFiltered();
    tc = TabController(length: lists.length, vsync: this);
  }
}
