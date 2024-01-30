import 'dart:convert';

import 'package:cyberme_flutter/api/todo.dart';
import 'package:cyberme_flutter/main.dart';
import 'package:cyberme_flutter/pocket/app/util.dart';
import 'package:cyberme_flutter/pocket/models/todo.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';

import '../config.dart';

class TodoView extends ConsumerStatefulWidget {
  const TodoView({super.key});

  @override
  ConsumerState<TodoView> createState() => _TodoViewState();
}

class _TodoViewState extends ConsumerState<TodoView>
    with TickerProviderStateMixin {
  int step = 60;
  int indent = 0;
  late DateTime weekDayOne;
  late DateTime lastWeekDayOne;
  late DateTime today;

  var loading = false;
  var reachedLimit = false;
  var useTab = true;

  Map<String, List<Todo>> data = {};
  Map<String, ScrollController> scs = {};

  // used by list
  List<Todo> todo = [];
  Set<String> lists = {};
  Set<String> selectLists = {};
  List<Todo> todoFiltered = [];

  // used by tab
  Map<String, List<Todo>> todoMap = {};
  TabController? tc;

  @override
  void initState() {
    final now = DateTime.now();
    today = DateTime(now.year, now.month, now.day);
    weekDayOne = now.subtract(Duration(
        days: now.weekday - 1,
        hours: now.hour,
        minutes: now.minute,
        seconds: now.second,
        milliseconds: now.millisecond,
        microseconds: now.microsecond));
    lastWeekDayOne = weekDayOne.subtract(const Duration(days: 7));
    super.initState();
  }

  initScrollController() {
    for (final sc in scs.values) {
      sc.dispose();
    }
    scs = {};
    for (final l in ["global", ...lists]) {
      final sc = ScrollController();
      sc.addListener(() {
        if (sc.position.pixels == sc.position.maxScrollExtent && !loading) {
          debugPrint("reached end of data for $l");
          setState(() {
            loading = true;
          });
          if (!reachedLimit) {
            makeNextRange();
            debugPrint("next step is $indent, step $step");
            fetchTodo().then((value) => setState(() {
                  debugPrint("loading new data done!");
                  loading = false;
                }));
          }
        }
      });
      scs[l] = sc;
    }
  }

  initTabController() {
    if (useTab) {
      final lastIdx = tc?.index ?? 0;
      tc?.dispose();
      tc = TabController(
          length: lists.length, vsync: this, initialIndex: lastIdx);
    }
  }

  @override
  void dispose() {
    for (var element in scs.values) {
      debugPrint("disposing $element");
      element.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    fetchTodo().then((value) => setState(() {}));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: buildAppBar(),
        body: useTab ? (tc == null ? null : buildTabView()) : buildListView());
  }

  Widget buildTabView() {
    return Column(mainAxisSize: MainAxisSize.max, children: [
      Expanded(
          child: TabBarView(
              children: lists.map((e) {
                final tl = todoMap[e]!;
                return ListView.builder(
                    controller: scs[e],
                    itemBuilder: (c, i) {
                      if (i >= tl.length) {
                        return Center(
                            child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child:
                                    Text(reachedLimit ? "没有更多数据" : "正在加载...")));
                      }
                      final t = tl[i];
                      return Dismissible(
                        key: ValueKey(t),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.endToStart) {
                            final res = await ref
                                .read(todosProvider.notifier)
                                .deleteTodo(
                                    listId: t.listId ?? "", taskId: t.id ?? "");
                            await showSimpleMessage(context,
                                content: res, useSnackBar: true);
                            fetchTodo().then((value) => setState(() {}));
                          }
                          return false;
                        },
                        secondaryBackground: Container(
                            color: Colors.red,
                            child: const Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                    padding: EdgeInsets.only(right: 20),
                                    child: Text("删除",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15))))),
                        background: Container(
                            color: Colors.blue,
                            child: const Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                    padding: EdgeInsets.only(left: 20),
                                    child: Text("TODO",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15))))),
                        child: ListTile(
                            onLongPress: () => showDebugBar(context, t),
                            visualDensity: VisualDensity.compact,
                            title: Text(t.title ?? "",
                                style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.black,
                                    decoration: t.status == "completed"
                                        ? TextDecoration.lineThrough
                                        : null)),
                            subtitle: Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: DefaultTextStyle(
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black),
                                    child: Row(children: [
                                      Text(t.list ?? ""),
                                      const Spacer(),
                                      dateRich(t.date)
                                    ])))),
                      );
                    },
                    itemCount: tl.length + 1);
              }).toList(growable: false),
              controller: tc)),
      SafeArea(
          child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelPadding: const EdgeInsets.only(bottom: 10, top: 10),
              tabs: lists.map((e) => Text(e)).toList(growable: false),
              controller: tc))
    ]);
  }

  Widget buildListView() {
    final tl = todoFiltered;
    return ListView.builder(
        controller: scs["global"],
        itemBuilder: (c, i) {
          if (i >= tl.length) {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(reachedLimit ? "没有更多数据" : "正在加载...")));
          }
          final t = tl[i];
          return ListTile(
              title: Text(t.title ?? "",
                  style: TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                      decoration: t.status == "completed"
                          ? TextDecoration.lineThrough
                          : null)),
              subtitle: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: DefaultTextStyle(
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                      child: Row(children: [
                        Text(t.list ?? ""),
                        const Spacer(),
                        dateRich(t.date)
                      ]))));
        },
        itemCount: tl.length + 1);
  }

  AppBar buildAppBar() {
    final viewBtn = IconButton(
        onPressed: () {
          setState(() => useTab = !useTab);
          initTabController();
        },
        icon: useTab
            ? const RotatedBox(
                quarterTurns: 2, child: Icon(Icons.table_chart_sharp))
            : const Icon(Icons.format_list_bulleted));
    final reload =
        IconButton(onPressed: syncTodo, icon: const Icon(Icons.sync));
    final addTask =
        IconButton(onPressed: addNewTask, icon: const Icon(Icons.add));
    return AppBar(
        title: const Text("TODO"),
        centerTitle: false,
        actions: useTab
            ? [addTask, reload, viewBtn]
            : [
                addTask,
                reload,
                viewBtn,
                PopupMenuButton(
                    tooltip: "List Filter",
                    itemBuilder: (c) {
                      return lists
                          .map((e) => PopupMenuItem(
                              child: Row(children: [
                                Opacity(
                                    opacity: selectLists.contains(e) ? 1 : 0,
                                    child: const Icon(Icons.check)),
                                const SizedBox(width: 4),
                                Text(e)
                              ]),
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
    bool isToday = !today.isAfter(date);
    bool thisWeek = !weekDayOne.isAfter(date);
    bool lastWeek = !thisWeek && !lastWeekDayOne.isAfter(date);
    final style = TextStyle(
        decoration: isToday ? TextDecoration.underline : null,
        color: isToday
            ? Colors.lightGreen
            : thisWeek
                ? Colors.lightGreen
                : lastWeek
                    ? Colors.blueGrey
                    : Colors.grey);
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

  makeNextRange() {
    indent += (step + 1);
  }

  syncTodo() async {
    showWaitingBar(context, text: "正在同步");
    var resp = await get(Uri.parse(Config.todoSyncUrl),
        headers: config.cyberBase64Header);
    final res = jsonDecode(resp.body)["message"];
    ScaffoldMessenger.of(context).clearMaterialBanners();
    await showSimpleMessage(context, content: res);
    fetchTodo().then((value) => setState(() {}));
  }

  addNewTask() async {
    final title = TextEditingController();
    var selectList = lists.indexed
            .where((element) => element.$1 == tc?.index)
            .map((e) => e.$2)
            .firstOrNull ??
        lists.firstOrNull ??
        "";
    var markFinished = true;
    var date = DateTime.now();
    handleAdd() async {
      if (title.text.isEmpty || selectList.isEmpty) {
        return await showSimpleMessage(context, content: "标题和列表不能为空");
      }
      final res = await ref.read(todosProvider.notifier).addTodo(
          due: DateFormat("yyyy-MM-dd").format(date),
          title: title.text,
          finished: markFinished,
          listName: selectList,
          listId: listName2Id[selectList] ?? "");
      await showSimpleMessage(context,
          content: res, useSnackBar: true, withPopFirst: true);
      fetchTodo().then((value) => setState(() {}));
    }

    await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
                title: const Text("添加待办事项"),
                content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        onSubmitted: (_) => handleAdd(),
                        autofocus: true,
                        decoration: const InputDecoration(
                            border: UnderlineInputBorder(), hintText: "标题"),
                        controller: title,
                      ),
                      const SizedBox(height: 10),
                      PopupMenuButton(
                          initialValue: selectList,
                          tooltip: "",
                          child: Text("添加到 $selectList"),
                          itemBuilder: (context) => lists
                              .map((e) =>
                                  PopupMenuItem(child: Text(e), value: e))
                              .toList(),
                          onSelected: (v) {
                            setState(() {
                              selectList = v;
                            });
                          }),
                      const SizedBox(height: 5),
                      InkWell(
                          onTap: () async {
                            final selectedDate = await showDatePicker(
                                context: context,
                                firstDate: date.add(const Duration(days: -3)),
                                lastDate: date.add(const Duration(days: 3)));
                            if (selectedDate != null) {
                              setState(() => date = selectedDate);
                            }
                          },
                          child: Text(
                              "截止于 ${DateFormat("yyyy-MM-dd").format(date)}")),
                      const SizedBox(height: 3),
                      Transform.translate(
                          offset: const Offset(-8, 0),
                          child: Row(children: [
                            Checkbox(
                                value: markFinished,
                                onChanged: (v) =>
                                    setState(() => markFinished = v!)),
                            const Text("标记为已完成")
                          ]))
                    ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("取消")),
                  TextButton(onPressed: handleAdd, child: const Text("确定"))
                ]);
          });
        });
  }

  Future fetchTodo() async {
    final url = Uri.parse(Config.todoUrl(indent, indent + step));
    debugPrint("req for $url");
    final r = await get(url, headers: config.cyberBase64Header);
    final d = jsonDecode(r.body);
    final m = d["message"] ?? "";
    final s = d["status"] as int? ?? -1;
    if (s <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
      return;
    }
    final c = (d["data"] as Map).map((k, v) {
      final date = k as String;
      final todos = v as List;
      return MapEntry(
          date, todos.map((e) => Todo.fromJson(e)).toList(growable: false));
    });
    if (indent == 0) {
      data = c;
      prepareData(true);
    } else {
      data.addAll(c);
      prepareData(false);
    }
    if (indent >= 1000) {
      debugPrint("reached max limit");
      reachedLimit = true;
    }
  }

  Map<String, String> listName2Id = {};

  prepareData(bool firstTime) {
    todo = [];
    todoMap = {};
    for (final t in data.values) {
      todo.addAll(t);
      for (final tt in t) {
        if (!lists.contains(tt.list) && tt.list != null) {
          lists.add(tt.list!);
          listName2Id[tt.list!] = tt.listId ?? "";
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
    todoMap.forEach((key, value) =>
        value.sort((t2, t1) => t1.time?.compareTo(t2.time ?? "") ?? 0));
    todo.sort((t2, t1) => t1.time?.compareTo(t2.time ?? "") ?? 0);
    //执行 filter
    updateFiltered();
    if (firstTime) initScrollController();
    //每次获取数据可能有新列表，因此如果使用 tab 每次都要初始化 tabController
    initTabController();
  }
}
