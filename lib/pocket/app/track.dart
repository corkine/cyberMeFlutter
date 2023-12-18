import 'dart:convert';

import 'package:clipboard/clipboard.dart';
import 'package:cyberme_flutter/api/track.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setting = ref.watch(trackSettingsProvider).value;
    final data = ref.watch(trackDataProvider.call(search.text));

    final appBar =
        AppBar(centerTitle: true, title: const Text("Redis Track"), actions: [
      IconButton(
          onPressed: () =>
              ref.read(trackSettingsProvider.notifier).setTrackSortReversed(),
          icon: Icon(setting?.sortByName ?? true
              ? Icons.format_list_numbered
              : Icons.sort_by_alpha)),
      IconButton(onPressed: handleAddSearchItem, icon: const Icon(Icons.add))
    ]);

    if (setting == null) {
      return Scaffold(
          appBar: appBar,
          body: const Center(child: CupertinoActivityIndicator()));
    }

    final dataList = ListView.builder(
        itemBuilder: (ctx, idx) {
          final c = data[idx];
          return InkWell(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 10, right: 10, top: 8, bottom: 8),
                child: Row(
                    children: [Expanded(child: Text(c.$1)), Text(c.$2)],
                    mainAxisAlignment: MainAxisAlignment.spaceBetween),
              ),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (ctx) => TrackDetailView(url: c.$1, count: c.$2))));
        },
        itemCount: data.length);

    final searchBar = CupertinoSearchTextField(
        onChanged: (value) => setState(() {}),
        autofocus: true,
        controller: search,
        placeholder: "搜索",
        padding: const EdgeInsets.only(left: 10, right: 10));

    searchItem(e) {
      return RawChip(
          label: Text(e.title),
          tooltip: "${e.search}\n${e.id}",
          onDeleted: () => deleteQuickSearch(setting, e.id),
          onSelected: (v) {
            search.text = v ? e.search : "";
            setState(() {});
          },
          selected: search.text == e.search,
          deleteIconColor: Colors.black26,
          labelPadding: const EdgeInsets.only(left: 3, right: 3),
          deleteIcon: const Icon(Icons.close, size: 18),
          visualDensity: VisualDensity.compact);
    }

    return Scaffold(
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
                              .map((e) => searchItem(e))
                              .toList(growable: false))),
                  const SizedBox(height: 10)
                ])));
  }

  Future deleteQuickSearch(TrackSetting setting, String id) async {
    final value = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text("确定删除?"),
                content: const Text("此操作不可恢复。"),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("取消")),
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text("确定"))
                ]));
    if (value) {
      ref.read(trackSettingsProvider.notifier).setTrack(setting.searchItems
          .where((element) => element.id != id)
          .toList(growable: false));
    }
  }

  void handleAddSearchItem() async {
    var title = "";
    var searchC2 = TextEditingController(text: search.text);
    handleAdd() {
      if (title.isNotEmpty && searchC2.text.isNotEmpty) {
        ref.read(trackSettingsProvider.notifier).addTrack(TrackSearchItem(
            title: title,
            search: search.text,
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
        builder: (context) => AlertDialog(
                title: const Text("添加快捷方式"),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: searchC2,
                      decoration: const InputDecoration(labelText: "搜索内容")),
                  const SizedBox(height: 10),
                  TextField(
                      autofocus: true,
                      decoration: const InputDecoration(labelText: "快捷方式标题"),
                      onChanged: (value) => title = value)
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("取消")),
                  TextButton(onPressed: handleAdd, child: const Text("确定"))
                ]));
  }
}

class TrackDetailView extends StatefulWidget {
  final String url;
  final String count;

  const TrackDetailView({super.key, required this.url, required this.count});

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
    monthDayOne = DateTime(now.year, now.month, 1);
    lastWeekDayOne = weekDayOne.subtract(const Duration(days: 7));
    super.initState();
  }

  @override
  void didChangeDependencies() {
    fetchDetail(config).then((value) => setState(() {
          logs = value?.logs ?? [];
          isTrack = value?.monitor ?? false;
        }));
    super.didChangeDependencies();
  }

  List<Logs> logs = [];
  bool isTrack = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.url.split("/").last),
          actions: [
            IconButton(
                onPressed: () async {
                  await setTrack(config!, widget.url, !isTrack);
                  final d = await fetchDetail(config!);
                  logs = d?.logs ?? [];
                  isTrack = d?.monitor ?? false;
                  setState(() {});
                },
                icon: Icon(isTrack
                    ? Icons.visibility
                    : Icons.visibility_off_outlined)),
            IconButton(
                onPressed: () async {
                  await handleAddShortLink(config);
                  setState(() {});
                },
                icon:
                    const RotatedBox(quarterTurns: 1, child: Icon(Icons.link)))
          ],
        ),
        body: RefreshIndicator(
            onRefresh: () async {
              final d = await fetchDetail(config);
              logs = d?.logs ?? [];
              debugPrint("reload svc details done!");
            },
            child: Column(children: [
              Expanded(
                child: ListView.builder(
                    itemBuilder: (ctx, idx) {
                      final c = logs[idx];
                      return ListTile(
                          visualDensity: VisualDensity.compact,
                          onTap: () async {
                            await FlutterClipboard.copy(c.ip ?? "");
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("已拷贝地址到剪贴板")));
                          },
                          onLongPress: () async {
                            await launchUrlString(
                                "https://www.ipshudi.com/${c.ip}.htm");
                          },
                          title: Text(c.ip ?? "No IP"),
                          subtitle: dateRich(c.timestamp?.split(".").first),
                          trailing: Text(c.ipInfo ?? ""));
                    },
                    itemCount: logs.length),
              ),
              SafeArea(
                child: Padding(
                    padding: const EdgeInsets.only(
                        left: 15, right: 15, top: 3, bottom: 5),
                    child: Row(children: [
                      Text("今日访问：$todayCount"),
                      Text("本周访问：$weekCount"),
                      Text("本月访问：$monthCount")
                    ], mainAxisAlignment: MainAxisAlignment.spaceBetween)),
              )
            ])));
  }

  Future<Track?> fetchDetail(Config config) async {
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

  Future handleAddShortLink(Config config) async {
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
                                prefix: Text("go.mazhangjing.com/")),
                          ),
                          const SizedBox(height: 10),
                          Transform.translate(
                              offset: const Offset(-5, 0),
                              child: Row(children: [
                                Checkbox(
                                    value: overwrite,
                                    onChanged: (v) => setState(() {
                                          overwrite = v!;
                                        })),
                                const Text("覆盖现有关键字")
                              ]))
                        ])),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(kw.text);
                      },
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

  Widget dateRich(String? date) {
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
}
