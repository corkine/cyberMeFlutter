import 'package:clipboard/clipboard.dart';
import 'package:cyberme_flutter/api/gpt.dart';
import 'package:cyberme_flutter/api/todo.dart';
import 'package:cyberme_flutter/pocket/app/util.dart';
import 'package:cyberme_flutter/pocket/models/todo.dart';
import 'package:cyberme_flutter/util.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sticky_grouped_list/sticky_grouped_list.dart';

class TodoView extends ConsumerStatefulWidget {
  const TodoView({super.key});

  @override
  ConsumerState<TodoView> createState() => _TodoViewState();
}

class _TodoViewState extends ConsumerState<TodoView>
    with TickerProviderStateMixin {
  late DateTime weekDayOne;
  late DateTime lastWeekDayOne;
  late DateTime today;

  Set<String> selectLists = {};

  late ItemPositionsListener listener;
  late GroupedItemScrollController controller;

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
    controller = GroupedItemScrollController();
    listener = ItemPositionsListener.create();
    listener.itemPositions.addListener(fetchNextHandler);
    super.initState();
  }

  @override
  void dispose() {
    listener.itemPositions.removeListener(fetchNextHandler);
    super.dispose();
  }

  fetchNextHandler() {
    final item = listener.itemPositions.value.lastOrNull;
    final idx = item?.index ?? 0.0;
    if ((idx ~/ 2) >= todoLength - 1 && lastIdx != idx) {
      print("bottom reached!");
      ref.read(todoDBProvider.notifier).fetchNext();
    }
    lastIdx = idx;
  }

  int todoLength = 0;
  num lastIdx = 0;

  @override
  Widget build(BuildContext context) {
    final todos = (ref.watch(todoDBProvider).valueOrNull ?? [])
        .where((todo) => selectLists.isEmpty || selectLists.contains(todo.list))
        .toList();
    todoLength = todos.length;
    final lists = ref.watch(todoListsProvider);
    return Scaffold(
        appBar: buildAppBar(todos, lists),
        body: Stack(children: [buildListView(todos), buildListNameBar(lists)]));
  }

  AppBar buildAppBar(List<Todo> todos, List<String> lists) {
    final setting = IconButton(
        onPressed: handleSetting,
        icon: ref.read(todoLocalProvider).value?.isEmpty ?? true
            ? const Icon(Icons.settings_outlined)
            : const Icon(Icons.settings));
    final dayReportBtn = Tooltip(
        waitDuration: const Duration(milliseconds: 400),
        message: "运行日报脚本",
        child: IconButton(
            onPressed: handleAddDayReport,
            icon: const Icon(Icons.description_outlined)));
    final reportBtn = Tooltip(
        waitDuration: const Duration(milliseconds: 400),
        message: "GPT编周报",
        child: IconButton(
            onPressed: () => handleAddWeekReport(todos),
            icon: const Icon(Icons.android)));
    final reload =
        IconButton(onPressed: syncTodo, icon: const Icon(Icons.sync));
    final addTask = IconButton(
        onPressed: () => addNewTask(lists), icon: const Icon(Icons.add));
    return AppBar(actions: [addTask, dayReportBtn, reportBtn, reload, setting]);
  }

  StickyGroupedListView<Todo, String> buildListView(List<Todo> todos) {
    return StickyGroupedListView<Todo, String>(
        elements: todos,
        groupBy: (todo) =>
            (todo.date?.year.toString() ?? "") +
            (todo.date?.month.toString() ?? ""),
        groupSeparatorBuilder: (todo) => Padding(
            padding: const EdgeInsets.only(left: 15, top: 2, bottom: 2),
            child: Text(
                DateFormat("yyyy年M月").format(todo.date ?? DateTime.now()),
                style: const TextStyle(fontWeight: FontWeight.bold))),
        order: StickyGroupedListOrder.DESC,
        itemComparator: (a, b) =>
            a.date?.compareTo(b.date ?? DateTime.now()) ?? 0,
        stickyHeaderBackgroundColor:
            Theme.of(context).colorScheme.surfaceContainer,
        itemPositionsListener: listener,
        itemScrollController: controller,
        elementIdentifier: (todo) => todo.id ?? "",
        itemBuilder: (c, t) {
          final completed = t.status == "completed";
          const color = Colors.black;
          return Dismissible(
              key: ValueKey(t),
              child: ListTile(
                  title: Text(completed ? t.title ?? "" : "${t.title} ⚠",
                      style: const TextStyle(fontSize: 15, color: color)),
                  subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: DefaultTextStyle(
                          style: const TextStyle(fontSize: 12, color: color),
                          child: Row(children: [
                            Text(t.list ?? ""),
                            const Spacer(),
                            buildRichDate(t.date)
                          ])))),
              confirmDismiss: (direction) async {
                final ans = direction == DismissDirection.endToStart
                    ? await ref.read(todoDBProvider.notifier).deleteTodo(
                        listId: t.listId ?? "",
                        taskId: t.id ?? "",
                        updateList: true)
                    : await ref.read(todoDBProvider.notifier).makeTodo(
                        listId: t.listId ?? "",
                        taskId: t.id ?? "",
                        completed: !t.isCompleted,
                        updateList: true);
                await showSimpleMessage(context,
                    content: ans, useSnackBar: true);
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
                                  color: Colors.white, fontSize: 15))))),
              background: Container(
                  color: t.isCompleted ? Colors.orange : Colors.blue,
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Text("标记为${t.isCompleted ? "未完成" : "完成"}",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 15))))));
        });
  }

  Positioned buildListNameBar(List<String> lists) {
    return Positioned(
        bottom: 10,
        left: 10,
        right: 10,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: lists
                  .map((list) => Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: RawChip(
                            selected: selectLists.contains(list),
                            showCheckmark: false,
                            selectedColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            labelPadding:
                                const EdgeInsets.only(left: 10, right: 10),
                            padding: const EdgeInsets.only(left: 3, right: 3),
                            shape: RoundedRectangleBorder(
                                side:
                                    const BorderSide(color: Colors.transparent),
                                borderRadius: BorderRadius.circular(20)),
                            label: Text(list),
                            onPressed: () async {
                              if (selectLists.contains(list)) {
                                selectLists.remove(list);
                              } else {
                                selectLists.add(list);
                              }
                              await controller.scrollTo(
                                  index: 0,
                                  duration: const Duration(seconds: 1));
                              setState(() {});
                            }),
                      ))
                  .toList(growable: false)),
        ));
  }

  Widget buildRichDate(DateTime? date) {
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

  syncTodo() async {
    showWaitingBar(context, text: "正在同步");
    final res = await ref.read(todoDBProvider.notifier).sync(updateList: true);
    ScaffoldMessenger.of(context).clearMaterialBanners();
    await showSimpleMessage(context, content: res);
  }

  addNewTask(List<String> lists) async {
    final title = TextEditingController();
    var selectList = lists.first;
    var markFinished = true;
    var date = DateTime.now();
    handleAdd() async {
      if (title.text.isEmpty || selectList.isEmpty) {
        return await showSimpleMessage(context, content: "标题和列表不能为空");
      }
      final res = await ref.read(todoDBProvider.notifier).addTodo(
          due: DateFormat("yyyy-MM-dd").format(date),
          title: title.text,
          finished: markFinished,
          listName: selectList,
          updateList: true);
      await showSimpleMessage(context,
          content: res, useSnackBar: true, withPopFirst: true);
    }

    final node = FocusNode();
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
                        focusNode: node,
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
                          onSelected: (v) => setState(() => selectList = v)),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          InkWell(
                              onTap: () async {
                                final selectedDate = await showDatePicker(
                                    context: context,
                                    firstDate:
                                        date.add(const Duration(days: -30)),
                                    lastDate:
                                        date.add(const Duration(days: 300)));
                                if (selectedDate != null) {
                                  setState(() => date = selectedDate);
                                }
                              },
                              child: Text(
                                  "截止于 ${DateFormat("yyyy-MM-dd").format(date)}")),
                          const SizedBox(width: 5),
                          TextButton(
                              onPressed: () {
                                setState(() => date = DateTime.now()
                                    .add(const Duration(days: -1)));
                                FocusScope.of(context).requestFocus(node);
                              },
                              child: const Text("昨天")),
                        ],
                      ),
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

  void handleAddWeekReport(List<Todo> todo) async {
    final now = DateTime.now();
    var md = now.add(Duration(days: -1 * now.weekday + 1));
    md = DateTime(md.year, md.month, md.day);
    final work = todo.where((t) => t.list?.contains("工作") ?? false).where((t) {
      final d = t.date;
      if (d == null) return false;
      if (d.isBefore(md)) return false;
      return true;
    }).toList(growable: false);
    work.sort((a, b) => a.date!.compareTo(b.date!));
    final s = work.map((e) {
      final d = e.date!.weekday;
      var dd = "";
      switch (d) {
        case 1:
          dd = "周一";
          break;
        case 2:
          dd = "周二";
          break;
        case 3:
          dd = "周三";
          break;
        case 4:
          dd = "周四";
          break;
        case 5:
          dd = "周五";
          break;
        case 6:
          dd = "周六";
          break;
        case 7:
          dd = "周日";
          break;
        default:
          break;
      }
      return "$dd: ${e.title}";
    }).join("。");
    await showDebugBar(context, "正在运行 GPT, 请稍后");
    final (_, res) = await ref
        .read(gPTSettingsProvider.notifier)
        .request("根据我的一周工作日志生成一份周报和下周计划，"
            "不要使用 Markdown 标记，比如星号，使用数字标号"
            "要符合认知动作执行顺序，删除重复项并进行扩充"
            " $s");
    ScaffoldMessenger.of(context).clearMaterialBanners();
    await showModalBottomSheet(
        context: context,
        builder: (context) {
          return GPTWeekPlanView(res);
        });
  }

  void handleAddDayReport() async {
    final url = await ref.read(todoLocalProvider.future);
    runScript(url);
  }

  void handleSetting() async {
    final url = await ref.watch(todoLocalProvider.future);
    final newUrl = TextEditingController(text: url);
    final res = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: const Text("设置脚本"),
              content: TextField(
                  decoration: const InputDecoration(helperText: "脚本路径"),
                  controller: newUrl),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("取消")),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text("确定"))
              ]);
        });
    if (res == true) {
      await ref.read(todoLocalProvider.notifier).updatePath(newUrl.text);
      await showSimpleMessage(context, content: "已更新脚本路径", useSnackBar: true);
    } else {
      await showSimpleMessage(context, content: "脚本未更新", useSnackBar: true);
    }
  }
}

class GPTWeekPlanView extends ConsumerStatefulWidget {
  final String answer;
  const GPTWeekPlanView(this.answer, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _GPTWeekPlanViewState();
}

class _GPTWeekPlanViewState extends ConsumerState<GPTWeekPlanView> {
  final controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    controller.text = widget.answer;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, top: 20),
            child: Column(children: [
              TextField(maxLines: 9, controller: controller),
              ButtonBar(alignment: MainAxisAlignment.center, children: [
                TextButton(
                    onPressed: () {
                      controller.text = controller.text.replaceAll("*", "");
                    },
                    child: const Text("移星号")),
                TextButton(
                    onPressed: () {
                      controller.text = controller.text.replaceAll("*", "-");
                    },
                    child: const Text("星改杠")),
                TextButton(
                    onPressed: () {
                      FlutterClipboard.copy(controller.text);
                      setState(() => copyText = "已复制");
                      Future.delayed(const Duration(seconds: 1))
                          .then((value) => setState(() => copyText = "复制"));
                    },
                    child: Text(copyText)),
                TextButton(onPressed: () {}, child: const Text("确定"))
              ])
            ])));
  }

  String copyText = "复制";
}
