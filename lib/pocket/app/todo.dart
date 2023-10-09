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

class _TodoViewState extends State<TodoView> with TickerProviderStateMixin {
  Config? config;
  int step = 60;
  int indent = 0;
  late DateTime weekDayOne;
  late DateTime lastWeekDayOne;

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
                                child: Text(reachedLimit ? "没有更多数据" : "正在加载...")));
                      }
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
                    itemCount: tl.length + 1);
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
                  style: const TextStyle(fontSize: 15, color: Colors.black)),
              subtitle: Padding(
                  padding: const EdgeInsets.only(top: 7),
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
    return AppBar(
        title: const Text("待办事项"),
        centerTitle: true,
        actions: useTab
            ? [viewBtn]
            : [
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
    bool thisWeek = !weekDayOne.isAfter(date);
    bool lastWeek = !thisWeek && !lastWeekDayOne.isAfter(date);
    final style = TextStyle(
        color: thisWeek
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

  Future fetchTodo() async {
    final url = Uri.parse(Config.todoUrl(indent, indent + step));
    debugPrint("req for $url");
    final r = await get(url, headers: config!.cyberBase64Header);
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

  prepareData(bool firstTime) {
    todo = [];
    todoMap = {};
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
