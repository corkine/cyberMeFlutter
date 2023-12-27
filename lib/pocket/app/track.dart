import 'dart:convert';

import 'package:clipboard/clipboard.dart';
import 'package:cyberme_flutter/api/track.dart';
import 'package:cyberme_flutter/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../api/statistics.dart';
import '../config.dart';
import '../models/track.dart';

class TrackView extends ConsumerStatefulWidget {
  const TrackView({super.key});

  @override
  ConsumerState<TrackView> createState() => _TrackViewState();
}

class _TrackViewState extends ConsumerState<TrackView> {
  final search = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(trackSettingsProvider.future).then((value) {
      setState(() => search.text = value.lastSearch);
    });
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    ref.read(trackSettingsProvider.notifier).setLastSearch(search.text,
        originData: ref.read(fetchTrackProvider).value, withUpload: true);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final setting = ref.watch(trackSettingsProvider).value;
    final data = ref.watch(trackDataProvider.call(search.text));

    final appBar =
        AppBar(centerTitle: false, title: const Text("Track!Me"), actions: [
      IconButton(
          onPressed: () => showModalBottomSheet(
              context: context,
              builder: (context) => const ServiceView(useSheet: true)),
          icon: const Icon(Icons.dashboard)),
      IconButton(
          onPressed: () => showModalBottomSheet(
              context: context, builder: (context) => const StatisticsView()),
          icon: const Icon(Icons.leaderboard)),
      IconButton(
          onPressed: () =>
              ref.read(trackSettingsProvider.notifier).setTrackSortReversed(),
          icon: Icon(setting?.sortByName ?? true
              ? Icons.format_list_numbered
              : Icons.sort_by_alpha)),
      IconButton(onPressed: handleAddSearchItem, icon: const Icon(Icons.add))
    ]);

    if (setting == null) {
      return Theme(
          data: appThemeData,
          child: Scaffold(
              appBar: appBar,
              body: const Center(child: CupertinoActivityIndicator())));
    }

    final dataList = ListView.builder(
        itemBuilder: (ctx, idx) {
          final c = data[idx];
          final privCount = setting.lastData[c.$1];
          final deltaCount = privCount == null ? 0 : c.$2 - privCount;
          final deltaStyle = deltaCount > 0
              ? const TextStyle(color: Colors.green, fontSize: 10)
              : const TextStyle(color: Colors.red, fontSize: 10);
          return InkWell(
              child: Padding(
                  padding: const EdgeInsets.only(
                      left: 10, right: 10, top: 8, bottom: 8),
                  child: Row(children: [
                    Expanded(
                        child: Text(c.$1,
                            overflow: TextOverflow.ellipsis, maxLines: 1)),
                    const SizedBox(width: 5),
                    Text(c.$2.toString()),
                    Text(
                        deltaCount == 0
                            ? ""
                            : " ${deltaCount > 0 ? "+" : ""}$deltaCount",
                        style: deltaStyle)
                  ], mainAxisAlignment: MainAxisAlignment.spaceBetween)),
              onLongPress: () => showPopupMenu(data, c),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (ctx) => TrackDetailView(url: c.$1, count: c.$2))));
        },
        itemCount: data.length);

    final searchBar = CupertinoSearchTextField(
        onChanged: (value) => setState(() {}),
        controller: search,
        placeholder: "搜索",
        style: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.only(left: 10, right: 10));
    final changed = ref.watch(trackSearchChangedProvider);
    return Theme(
        data: appThemeData,
        child: Scaffold(
            appBar: appBar,
            body: RefreshIndicator(
                onRefresh: () async => await ref.refresh(fetchTrackProvider),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: dataList),
                      Container(
                          height: 45,
                          padding: const EdgeInsets.only(
                              left: 10, right: 10, top: 5, bottom: 10),
                          child: searchBar),
                      Padding(
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: Wrap(
                              spacing: 5,
                              runSpacing: 5,
                              children: setting.searchItems
                                  .map((e) => buildSearchItemChip(
                                      setting, e, changed.contains(e.search)))
                                  .toList(growable: false))),
                      const SizedBox(height: 10)
                    ]))));
  }

  Widget buildSearchItemChip(setting, e, isChange) {
    return GestureDetector(
        onLongPress: () => showDialog(
            context: context,
            builder: (context) => Theme(
                data: appThemeData,
                child: SimpleDialog(children: [
                  SimpleDialogOption(
                      onPressed: () {
                        ref.read(trackSettingsProvider.notifier).setTrack(
                            setting.searchItems
                                .where((element) => element.id != e.id)
                                .toList(growable: false));
                        Navigator.of(context).pop();
                      },
                      child: const Text("删除"))
                ]))),
        child: RawChip(
            label: Text(e.title + (isChange ? "*" : ""),
                style: TextStyle(
                    color: isChange ? Colors.greenAccent : Colors.white)),
            onSelected: (v) {
              search.text = v ? e.search : "";
              setState(() {});
            },
            selected: search.text == e.search,
            labelPadding: const EdgeInsets.only(left: 3, right: 3),
            visualDensity: VisualDensity.compact));
  }

  void showPopupMenu(data, c) => showDialog(
      context: context,
      builder: (context) => SimpleDialog(title: Text(c.$1), children: [
            SimpleDialogOption(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final res =
                      await ref.read(deleteTrackProvider.call([c.$1]).future);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(res)));
                },
                child: const Text("删除当前项")),
            SimpleDialogOption(
                onPressed: () async {
                  final userAnswer = await showDialog<bool>(
                      barrierDismissible: false,
                      context: context,
                      builder: (context) => AlertDialog(
                              title: const Text("确定"),
                              content: const Text("此操作不可撤销，确定执行？"),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text("取消")),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text("确定"))
                              ]));
                  if (userAnswer == true) {
                    Navigator.of(context).pop();
                    final res = await ref.read(deleteTrackProvider
                        .call(data.map((e) => e.$1).toList())
                        .future);
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(res)));
                  }
                },
                child: const Text("删除当前搜索结果所有项"))
          ]));

  void handleAddSearchItem() async {
    var title = "";
    var enableTrack = true;
    var searchC2 = TextEditingController(text: search.text);

    handleAdd() {
      if (title.isNotEmpty && searchC2.text.isNotEmpty) {
        ref.read(trackSettingsProvider.notifier).addTrack(TrackSearchItem(
            title: title,
            search: search.text,
            track: enableTrack,
            id: DateTime.now().millisecondsSinceEpoch.toString()));
        Navigator.of(context).pop();
      } else {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                    title: const Text("警告"),
                    content: const Text("搜索内容和标题均不能为空"),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("确定"))
                    ]));
      }
    }

    await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
                    title: const Text("添加快捷方式"),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextField(
                          controller: searchC2,
                          decoration: const InputDecoration(labelText: "搜索内容")),
                      const SizedBox(height: 10),
                      TextField(
                          autofocus: true,
                          decoration:
                              const InputDecoration(labelText: "快捷方式标题"),
                          onChanged: (value) => title = value),
                      const SizedBox(height: 10),
                      Transform.translate(
                          offset: const Offset(-10, 0),
                          child: Row(children: [
                            Checkbox.adaptive(
                                visualDensity: VisualDensity.compact,
                                value: enableTrack,
                                onChanged: (v) {
                                  setState(() => enableTrack = v!);
                                }),
                            const SizedBox(width: 10),
                            const Text("追踪变更")
                          ]))
                    ]),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("取消")),
                      TextButton(onPressed: handleAdd, child: const Text("确定"))
                    ])));
  }
}

class TrackDetailView extends StatefulWidget {
  final String url;
  final int count;
  final int? privCount;

  const TrackDetailView(
      {super.key, required this.url, required this.count, this.privCount});

  @override
  State<TrackDetailView> createState() => _TrackDetailViewState();
}

class _TrackDetailViewState extends State<TrackDetailView> {
  late DateTime weekDayOne;
  late DateTime lastWeekDayOne;
  late DateTime monthDayOne;
  late DateTime today;
  int todayCount = -1;
  int weekCount = -1;
  int monthCount = -1;
  List<Logs> logs = [];
  bool isTrack = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    today = DateTime(now.year, now.month, now.day);
    weekDayOne = now.subtract(Duration(
        days: now.weekday - 1,
        hours: now.hour,
        minutes: now.minute,
        seconds: now.second,
        milliseconds: now.millisecond,
        microseconds: now.microsecond));
    monthDayOne = DateTime(now.year, now.month, 1);
    lastWeekDayOne = weekDayOne.subtract(const Duration(days: 7));
    fetchDetail().then((value) => setState(() {
          logs = value?.logs ?? [];
          isTrack = value?.monitor ?? false;
        }));
  }

  @override
  Widget build(BuildContext context) {
    handleAddTrack() async {
      await setTrack(config, widget.url, !isTrack);
      final d = await fetchDetail();
      logs = d?.logs ?? [];
      isTrack = d?.monitor ?? false;
      setState(() {});
    }

    final appBar = AppBar(title: Text(widget.url.split("/").last), actions: [
      IconButton(
          onPressed: handleAddTrack,
          icon:
              Icon(isTrack ? Icons.visibility : Icons.visibility_off_outlined)),
      IconButton(
          onPressed: () async {
            await showAddShortLinkDialog();
            setState(() {});
          },
          icon: const RotatedBox(quarterTurns: 1, child: Icon(Icons.link)))
    ]);

    final items = ListView.builder(
        itemBuilder: (ctx, idx) {
          final c = logs[idx];
          return ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              onTap: () async {
                await FlutterClipboard.copy(c.ip ?? "");
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text("已拷贝地址到剪贴板")));
              },
              onLongPress: () async {
                await launchUrlString("https://www.ipshudi.com/${c.ip}.htm");
              },
              title: Text(c.ip ?? "No IP"),
              subtitle: buildDataRich(c.timestamp?.split(".").first),
              trailing: Text(c.ipInfo ?? ""));
        },
        itemCount: logs.length);

    return Theme(
        data: appThemeData,
        child: Scaffold(
            appBar: appBar,
            body: RefreshIndicator(
                onRefresh: () async {
                  final d = await fetchDetail();
                  logs = d?.logs ?? [];
                  debugPrint("reload svc details done!");
                },
                child: Column(children: [
                  Expanded(child: items),
                  SafeArea(
                      child: Padding(
                          padding: const EdgeInsets.only(
                              left: 15, right: 15, top: 3, bottom: 5),
                          child: Row(
                              children: [
                                Text("今日访问：$todayCount"),
                                Text("本周访问：$weekCount"),
                                Text("本月访问：$monthCount")
                              ],
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween)))
                ]))));
  }

  Future showAddShortLinkDialog() async {
    final kw = TextEditingController();
    var overwrite = false;
    var keyword = await showDialog<String>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text("请输入短链接关键字"),
                content: StatefulBuilder(
                    builder: (c, setState) =>
                        Column(mainAxisSize: MainAxisSize.min, children: [
                          TextField(
                              controller: kw,
                              decoration: const InputDecoration(
                                  labelText: "短链",
                                  prefix: Text("go.mazhangjing.com/"))),
                          const SizedBox(height: 10),
                          Transform.translate(
                              offset: const Offset(-5, 0),
                              child: Row(children: [
                                Checkbox(
                                    value: overwrite,
                                    onChanged: (v) =>
                                        setState(() => overwrite = v!)),
                                const Text("覆盖现有关键字")
                              ]))
                        ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(kw.text),
                      child: const Text("确定"))
                ]),
        barrierDismissible: false);
    if (keyword!.isEmpty) return;
    final r = await post(Uri.parse(Config.goPostUrl),
        headers: config.cyberBase64JsonContentHeader,
        body: jsonEncode({
          "keyword": keyword,
          "redirectURL":
              "https://cyber.mazhangjing.com/visits/${base64Encode(utf8.encode(widget.url))}/logs",
          "note": "由 CyberMe Flutter 添加",
          "override": overwrite
        }));
    final d = jsonDecode(r.body);
    final m = d["message"] ?? "没有消息";
    final s = (d["status"] as int?) ?? -1;
    var fm = m;
    if (s > 0) {
      await FlutterClipboard.copy("https://go.mazhangjing.com/$keyword");
      fm = fm + "，已将链接拷贝到剪贴板。";
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(fm),
        action: SnackBarAction(label: "OK", onPressed: () {})));
  }

  Widget buildDataRich(String? date) {
    if (date == null) return const Text("未知日期");
    final date1 = DateFormat("yyyy-MM-dd'T'HH:mm:ss").parse(date);
    final df = DateFormat("yyyy-MM-dd HH:mm");
    bool isToday = !today.isAfter(date1);
    bool thisWeek = !weekDayOne.isAfter(date1);
    bool lastWeek = !thisWeek && !lastWeekDayOne.isAfter(date1);
    final style = TextStyle(
        decoration: isToday ? TextDecoration.underline : null,
        decorationColor: Colors.lightGreen,
        color: isToday
            ? Colors.lightGreen
            : thisWeek
                ? Colors.lightGreen
                : lastWeek
                    ? Colors.blueGrey
                    : Colors.grey);
    switch (date1.weekday) {
      case 1:
        return Text("${df.format(date1)} 周一", style: style);
      case 2:
        return Text("${df.format(date1)} 周二", style: style);
      case 3:
        return Text("${df.format(date1)} 周三", style: style);
      case 4:
        return Text("${df.format(date1)} 周四", style: style);
      case 5:
        return Text("${df.format(date1)} 周五", style: style);
      case 6:
        return Text("${df.format(date1)} 周六", style: style);
      default:
        return Text("${df.format(date1)} 周日", style: style);
    }
  }

  Future<Track?> fetchDetail() async {
    final Response r = await get(
        Uri.parse(Config.logsUrl(base64Encode(utf8.encode(widget.url)))),
        headers: config.cyberBase64Header);
    final d = jsonDecode(r.body);
    todayCount = 0;
    weekCount = 0;
    monthCount = 0;
    if ((d["status"] as int?) == 1) {
      final data = Track.fromJson(d["data"]);
      for (final log in (data.logs ?? <Logs>[])) {
        final dateStr = log.timestamp?.split(".").first;
        if (dateStr != null) {
          final date = DateFormat("yyyy-MM-dd'T'HH:mm:ss").parse(dateStr);
          if (date.isAfter(today)) todayCount += 1;
          if (date.isAfter(weekDayOne)) weekCount += 1;
          if (date.isAfter(monthDayOne)) monthCount += 1;
        }
      }
      return data;
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(d["message"])));
      return null;
    }
  }

  Future setTrack(Config config, String key, bool trackStatus) async {
    final r = await post(Uri.parse(Config.trackUrl),
        headers: config.cyberBase64JsonContentHeader,
        body: jsonEncode({"key": "visit:" + key, "add": trackStatus}));
    final data = jsonDecode(r.body);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(data["message"])));
  }
}

class ServiceView extends ConsumerWidget {
  final bool useSheet;
  const ServiceView({super.key, this.useSheet = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(getServiceStatusProvider).value?.$1;
    Widget content;
    if (s == null) {
      content = const Center(child: CupertinoActivityIndicator());
    } else {
      final items = ListView.builder(
          itemBuilder: (c, i) {
            final item = s[i];
            handleShowDetail() {
              if (useSheet) {
                showModalBottomSheet(
                    context: context,
                    builder: (context) => ServiceDetails(item));
              } else {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (c) => ServiceDetails(item)));
              }
            }

            return Card(
                elevation: 1,
                child: ListTile(
                    onTap: handleShowDetail,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                            color:
                                item.endOfSupport ? Colors.red : Colors.green,
                            width: 1)),
                    title: Text(item.serviceName ?? "未知服务"),
                    subtitle: Text(
                        "当前版本 ${item.version}，建议版本 ${item.suggestVersion}"),
                    trailing: Text(item.endOfSupport ? "已停止" : "运行中")));
          },
          itemCount: s.length);
      content = Padding(
          padding: const EdgeInsets.all(8.0),
          child: RefreshIndicator(
              onRefresh: () async =>
                  await ref.refresh(getServiceStatusProvider),
              child: items));
    }
    return Theme(
        data: appThemeData,
        child: Scaffold(
            appBar: AppBar(title: const Text("App Service")), body: content));
  }
}

class ServiceDetails extends ConsumerStatefulWidget {
  final ServiceStatus status;

  const ServiceDetails(this.status, {super.key});

  @override
  ConsumerState<ServiceDetails> createState() => _ServiceDetailsState();
}

class _ServiceDetailsState extends ConsumerState<ServiceDetails> {
  late var status = widget.status;

  setStatusToggle(BuildContext context, WidgetRef ref) async {
    handleAction() async {
      Navigator.of(context).pop();
      final msg = await setServiceStatus(status.path!, status.endOfSupport);
      final s = await ref.refresh(getServiceStatusProvider.future);
      for (var element in s.$1) {
        if (element.path == status.path) {
          status = element;
          setState(() {});
          break;
        }
      }
      showDialog(
          context: context,
          builder: (c) => AlertDialog(
                  backgroundColor: appThemeData.colorScheme.background,
                  title: Text("操作结果",
                      style: appThemeData.textTheme.headlineLarge
                          ?.copyWith(fontSize: 20)),
                  content: Text(msg, style: appThemeData.textTheme.bodyLarge),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("确认"))
                  ]));
    }

    showDialog(
        context: context,
        builder: (c) => AlertDialog(
                backgroundColor: appThemeData.colorScheme.background,
                title: Text("确认操作",
                    style: appThemeData.textTheme.headlineLarge
                        ?.copyWith(fontSize: 20, color: Colors.red)),
                content: Text(
                    "是否要${status.endOfSupport ? "启动" : "停止"}服务？此操作可能影响正在使用应用的用户，请谨慎操作！",
                    style: appThemeData.textTheme.bodyLarge),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("取消")),
                  TextButton(onPressed: handleAction, child: const Text("确认"))
                ]));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
        data: appThemeData,
        child: Scaffold(
            appBar: AppBar(title: Text(status.serviceName ?? "未知服务"), actions: [
              IconButton(
                  onPressed: () => setStatusToggle(context, ref),
                  icon: status.endOfSupport
                      ? const Icon(Icons.play_arrow, color: Colors.green)
                      : const Icon(Icons.stop, color: Colors.red))
            ]),
            body: Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text("运行日志",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...status.logs.map((e) => Text(e)),
                      const SizedBox(height: 20),
                      const Text("运行状态",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                          "当前版本 ${status.version}\n建议版本 ${status.suggestVersion}"),
                      Text("运行路径 ${status.path}"),
                      Text("支持状态 ${status.endOfSupport ? "已停止" : "运行中"}"),
                      Text("模板消息 ${status.endOfSupportMessage ?? "无"}")
                    ])))));
  }
}

class StatisticsView extends ConsumerWidget {
  const StatisticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(getStatisticsProvider).value?.$1;
    return Theme(
        data: appThemeData,
        child: Scaffold(
            appBar: AppBar(title: const Text("API Statistics"), actions: [
              IconButton(
                  onPressed: () => ref.refresh(getStatisticsProvider),
                  icon: const Icon(Icons.refresh))
            ]),
            body: s == null
                ? const Center(child: CupertinoActivityIndicator())
                : SingleChildScrollView(
                    child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(children: [
                          buildOf("Web 主页接口", s.dashboard),
                          buildOf("客户端接口", s.client),
                          buildOf("短链接系统", s.go),
                          buildOf("故事系统", s.story),
                          buildOf("任务系统", s.task),
                          buildOf("问卷系统", s.psych)
                        ])))));
  }

  Widget buildOf(String item, count) {
    return Card(
        elevation: 1,
        child: ListTile(title: Text(item), trailing: Text(count.toString())));
  }
}
