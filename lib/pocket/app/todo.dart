import 'package:clipboard/clipboard.dart';
import 'package:cyberme_flutter/api/gpt.dart';
import 'package:cyberme_flutter/api/todo.dart';
import 'package:cyberme_flutter/pocket/app/util.dart';
import 'package:cyberme_flutter/pocket/models/todo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      debugPrint("bottom reached!");
      ref.read(todoDBProvider.notifier).fetchNext();
    }
    lastIdx = idx;
  }

  int todoLength = 0;
  num lastIdx = 0;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(todoSettingsProvider).valueOrNull ?? TodoSetting();
    final lists = ref.watch(todoListsProvider);
    if (selectLists.isEmpty) {
      selectLists = Set.from(lists);
    }
    final todos = (ref.watch(todoDBProvider).valueOrNull ?? [])
        .where((todo) => selectLists.contains(todo.list))
        .toList();
    todoLength = todos.length;
    return Scaffold(
        appBar: buildAppBar(s, todos, lists),
        body: Stack(children: [
          buildListView(s, todos, lists),
          buildListNameBar(lists)
        ]));
  }

  AppBar buildAppBar(TodoSetting s, List<Todo> todos, List<String> lists) {
    final sortByList = Tooltip(
        waitDuration: const Duration(milliseconds: 400),
        message: "提醒事项按照列表排序",
        child: IconButton(
            onPressed: () => ref
                .read(todoSettingsProvider.notifier)
                .save((t) => t.copyWith(useListSort: !s.useListSort)),
            icon:
                Icon(s.useListSort ? Icons.reviews : Icons.reviews_outlined)));
    final groupByMode = Tooltip(
        waitDuration: const Duration(milliseconds: 400),
        message: "按照周分组",
        child: IconButton(
            onPressed: () => ref
                .read(todoSettingsProvider.notifier)
                .save((t) => t.copyWith(useWeekGroup: !s.useWeekGroup)),
            icon: Icon(
                s.useWeekGroup ? Icons.view_week : Icons.view_week_outlined)));
    final reportBtn = Tooltip(
        waitDuration: const Duration(milliseconds: 400),
        message: "GPT编周报",
        child: IconButton(
            onPressed: () => handleAddWeekReport(todos),
            icon: const Icon(Icons.android)));
    final reload =
        IconButton(onPressed: handleSyncTodo, icon: const Icon(Icons.sync));
    final addTask = IconButton(
        onPressed: () => handleAddNewTask(lists), icon: const Icon(Icons.add));
    return AppBar(
        actions: [addTask, reportBtn, reload, sortByList, groupByMode]);
  }

  final _dfGroup = DateFormat("yyyyMM");
  final _dfDay = DateFormat("yyyy年M月");

  int _weekOfYear(DateTime date) {
    // 获取该日期的第一天
    DateTime firstDayOfYear = DateTime(date.year, 1, 1);
    // 计算该日期是第几天
    int dayOfYear = date.difference(firstDayOfYear).inDays + 1;
    // 计算星期几
    int dayOfWeek = date.weekday;
    // 计算第几周
    int weekOfYear = ((dayOfYear - dayOfWeek + 10) / 7).floor();
    return weekOfYear;
  }

  String _groupBy(todo) => _dfGroup.format(todo.date ?? DateTime.now());

  Widget _groupBySeparator(todo) => Container(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
          padding: const EdgeInsets.only(left: 13, top: 2, bottom: 2),
          child: Text(_dfDay.format(todo.date ?? DateTime.now()),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary))));

  String _groupByWeek(todo) =>
      _weekOfYear(todo.date ?? DateTime.now()).toString().padLeft(3, '0');

  Widget _groupBySeparatorWeek(todo) => Container(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
          padding: const EdgeInsets.only(left: 13, top: 2, bottom: 2),
          child: Text(
              "${todo.date?.year ?? DateTime.now().year}年第${_weekOfYear(todo.date ?? DateTime.now())}周",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary))));

  _groupItemComparator(TodoSetting s) {
    return (Todo a, Todo b) {
      if (s.useListSort) {
        //分组回顾模式，直接按列表排，列表中按时间排
        final al = a.list ?? "";
        final bl = b.list ?? "";
        if (al != bl) {
          return bl.compareTo(al);
        }
        final ad = a.date ?? DateTime.now();
        final bd = b.date ?? DateTime.now();
        return ad.compareTo(bd);
      } else {
        //先按日期比较，再按完成与否比较，之后按列表比较，最后按时间比较(暂时没有时间)
        final ad =
            DateTime(a.date?.year ?? 0, a.date?.month ?? 0, a.date?.day ?? 0);
        final bd =
            DateTime(b.date?.year ?? 0, b.date?.month ?? 0, b.date?.day ?? 0);
        if (ad == bd) {
          final ac = a.isCompleted;
          final bc = b.isCompleted;
          if (ac == bc) {
            //TODO 有时间按时间排
            return b.list?.compareTo(a.list ?? "") ?? 0;
          } else {
            return ac ? -10 : 10;
          }
        } else {
          return ad.compareTo(bd);
        }
      }
    };
  }

  StickyGroupedListView<Todo, String> buildListView(
      TodoSetting s, List<Todo> todos, List<String> lists) {
    return StickyGroupedListView<Todo, String>(
        elements: todos,
        groupBy: s.useWeekGroup ? _groupByWeek : _groupBy,
        groupSeparatorBuilder:
            s.useWeekGroup ? _groupBySeparatorWeek : _groupBySeparator,
        order: StickyGroupedListOrder.DESC,
        itemComparator: _groupItemComparator(s),
        stickyHeaderBackgroundColor:
            Theme.of(context).colorScheme.surfaceContainer,
        itemPositionsListener: listener,
        itemScrollController: controller,
        elementIdentifier: (todo) => todo.id ?? "",
        itemBuilder: (c, t) {
          final completed = t.status == "completed";
          final color = Theme.of(context).colorScheme.onSurface;
          return Dismissible(
              key: ValueKey(t),
              child: InkWell(
                  onTap: () => handleTodoContextMenu(t, lists),
                  child: Container(
                      color: t.date == today
                          ? Theme.of(context).colorScheme.surfaceContainer
                          : null,
                      padding: const EdgeInsets.only(
                          left: 13, right: 13, bottom: 7, top: 7),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(t.title ?? "",
                                style: TextStyle(
                                    fontSize: 15,
                                    color: completed
                                        ? color
                                        : const Color.fromARGB(255, 163, 7, 7),
                                    height: 1.3,
                                    overflow: TextOverflow.fade)),
                            Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: DefaultTextStyle(
                                    style:
                                        TextStyle(fontSize: 12, color: color),
                                    child: Row(children: [
                                      Text(t.list ?? ""),
                                      const Spacer(),
                                      buildRichDate(t.date)
                                    ])))
                          ]))),
              confirmDismiss: (direction) async {
                final confirm = await showSimpleMessage(context,
                    content: "你确定执行此操作吗？", useSnackBar: false);
                if (!confirm) return false;
                final ans = direction == DismissDirection.endToStart
                    ? await ref.read(todoDBProvider.notifier).deleteTodo(
                        listId: t.listId ?? "",
                        taskId: t.id ?? "",
                        updateList: true)
                    : await ref.read(todoDBProvider.notifier).makeTodo(
                        listId: t.listId ?? "",
                        taskId: t.id ?? "",
                        title: t.title ?? "",
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
                              selectedColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              labelPadding:
                                  const EdgeInsets.only(left: 10, right: 10),
                              padding: const EdgeInsets.only(left: 3, right: 3),
                              shape: RoundedRectangleBorder(
                                  side: const BorderSide(
                                      color: Colors.transparent),
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
                    .toList(growable: false))));
  }

  Widget buildRichDate(DateTime? date) {
    if (date == null) return const Text("未知日期");
    final df = DateFormat("yyyy-MM-dd");
    bool isToday = df.format(date) == df.format(today);
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
    if (thisWeek) {
      if (isToday) {
        return Text("${df.format(date)} 今天", style: style);
      } else if (date.year == today.year && date.month == today.month) {
        if (date.day + 1 == today.day) {
          return Text("${df.format(date)} 昨天", style: style);
        } else if (date.day + 2 == today.day) {
          return Text("${df.format(date)} 前天", style: style);
        }
      }
    }
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

  handleTodoContextMenu(Todo t, List<String> lists) async {
    copyToClipboard() {
      Navigator.of(context).pop();
      Clipboard.setData(ClipboardData(text: t.title ?? ""));
      showSimpleMessage(context, content: "已复制到剪贴板", useSnackBar: true);
    }

    editTitle() async {
      Navigator.of(context).pop();
      final tc = TextEditingController(text: t.title);
      final newTitle = await showDialog<String?>(
          context: context,
          builder: (context) => AlertDialog(
                  content: TextField(
                      controller: tc,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          border: InputBorder.none, labelText: "标题")),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        child: const Text("取消")),
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(tc.text),
                        child: const Text("确定"))
                  ]));
      if (newTitle != null) {
        final ans = await ref.read(todoDBProvider.notifier).makeTodo(
            listId: t.listId ?? "",
            taskId: t.id ?? "",
            title: newTitle,
            completed: t.isCompleted,
            updateList: true);
        await showSimpleMessage(context, content: ans, useSnackBar: true);
      } else {
        await showSimpleMessage(context, content: "您已取消操作", useSnackBar: true);
      }
    }

    doItTomorrow() async {
      Navigator.of(context).pop();
      if (!t.isCompleted) {
        await ref.read(todoDBProvider.notifier).makeTodo(
            listId: t.listId ?? "",
            taskId: t.id ?? "",
            title: t.title ?? "",
            completed: true,
            updateList: false);
      }
      final res = await ref.read(todoDBProvider.notifier).addTodo(
          due: DateFormat("yyyy-MM-dd")
              .format(today.add(const Duration(days: 1))),
          title: (t.title ?? "") + " (续)",
          finished: false,
          listName: t.list ?? "",
          updateList: true);
      await showSimpleMessage(context, content: res.$1, useSnackBar: true);
    }

    changeList() async {
      final list = await showDialog<String>(
          context: context,
          builder: (context) =>
              SimpleDialog(title: const Text("更改列表"), children: [
                for (var list in lists)
                  if (list != t.list!)
                    SimpleDialogOption(
                        onPressed: () async => Navigator.of(context).pop(list),
                        child: Text(list))
              ]));
      if (list != null) {
        Navigator.of(context).pop();
        final res = await ref.read(todoDBProvider.notifier).addTodo(
            title: t.title!,
            due: DateFormat("yyyy-MM-dd").format(t.date ?? DateTime.now()),
            listName: list,
            finished: t.isCompleted,
            updateList: false);
        final addSuccess = res.$3;
        if (!addSuccess) {
          await showSimpleMessage(context, content: res.$1);
        } else {
          await ref
              .read(todoDBProvider.notifier)
              .deleteTodo(listName: list, taskId: t.id!, updateList: true);
          await showSimpleMessage(context,
              content: "更改待办事项列表成功", useSnackBar: true);
        }
      }
    }

    addSame() async {
      Navigator.of(context).pop();
      final res = await ref.read(todoDBProvider.notifier).addTodo(
          due: DateFormat("yyyy-MM-dd").format(today),
          title: t.title ?? "未命名待办事项",
          finished: false,
          listName: t.list ?? "",
          updateList: true);
      await showSimpleMessage(context, content: res.$1, useSnackBar: true);
    }

    return await showDialog(
        context: context,
        builder: (context) => SimpleDialog(title: const Text("选项"), children: [
              if (!t.isCompleted && t.date == today)
                SimpleDialogOption(
                    onPressed: doItTomorrow, child: const Text("标记明天继续")),
              SimpleDialogOption(onPressed: addSame, child: const Text("原样新建")),
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.of(context).pop();
                    handleAddNewTask(lists,
                        hintTitle: t.title, hintList: t.list ?? "");
                  },
                  child: const Text("基于此新建...")),
              SimpleDialogOption(
                  onPressed: changeList, child: const Text("更改列表...")),
              SimpleDialogOption(
                  onPressed: editTitle, child: const Text("修改标题...")),
              SimpleDialogOption(
                  onPressed: copyToClipboard, child: const Text("复制到剪贴板")),
            ]));
  }

  handleSyncTodo() async {
    showWaitingBar(context, text: "正在同步");
    final res = await ref.read(todoDBProvider.notifier).sync(updateList: true);
    ScaffoldMessenger.of(context).clearMaterialBanners();
    await showSimpleMessage(context, content: res);
  }

  handleAddNewTask(List<String> lists,
      {String? hintTitle, String? hintList}) async {
    final title = TextEditingController(text: hintTitle ?? "");
    var selectList = hintList ?? lists.first;
    var markFinished = false;
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
          content: res.$1, useSnackBar: true, withPopFirst: true);
    }

    final node = FocusNode();
    await showModal(context, StatefulBuilder(builder: (context, setState) {
      return Scaffold(
          appBar: AppBar(title: const Text("添加待办事项")),
          body: Padding(
              padding: const EdgeInsets.only(
                  top: 0, bottom: 10, left: 15, right: 15),
              child: Column(
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
                        controller: title),
                    const SizedBox(height: 10),
                    Wrap(runSpacing: 5, spacing: 5, children: [
                      for (var list in lists)
                        RawChip(
                            label: Text(list),
                            selected: list == selectList,
                            onPressed: () {
                              if (list.contains("工作")) {
                                markFinished = true;
                              } else {
                                markFinished = false;
                              }
                              setState(() => selectList = list);
                            })
                    ]),
                    const SizedBox(height: 5),
                    Row(children: [
                      InkWell(
                          onTap: () async {
                            final selectedDate = await showDatePicker(
                                context: context,
                                firstDate: date.add(const Duration(days: -30)),
                                lastDate: date.add(const Duration(days: 300)));
                            if (selectedDate != null) {
                              setState(() => date = selectedDate);
                            }
                          },
                          child: Text(
                              "截止于 ${DateFormat("yyyy-MM-dd").format(date)}")),
                      const SizedBox(width: 5),
                      TextButton(
                          onPressed: () {
                            setState(() => date =
                                DateTime.now().add(const Duration(days: -1)));
                            FocusScope.of(context).requestFocus(node);
                          },
                          child: const Text("昨天"))
                    ]),
                    const SizedBox(height: 3),
                    Transform.translate(
                        offset: const Offset(-8, 0),
                        child: Row(children: [
                          Checkbox(
                              value: markFinished,
                              onChanged: (v) =>
                                  setState(() => markFinished = v!)),
                          const Text("标记为已完成")
                        ])),
                    const Spacer(),
                    SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                            onPressed: handleAdd, child: const Text("确定")))
                  ])));
    }));
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
