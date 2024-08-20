import 'dart:convert';

import 'package:clipboard/clipboard.dart';
import 'package:cyberme_flutter/pocket/viewmodels/track.dart';
import 'package:cyberme_flutter/main.dart';
import 'package:cyberme_flutter/pocket/views/util.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../config.dart';
import '../../../models/track.dart';

class TrackDetailView extends ConsumerStatefulWidget {
  final String url;
  final int count;
  final int? privCount;

  const TrackDetailView(
      {super.key, required this.url, required this.count, this.privCount});

  @override
  ConsumerState<TrackDetailView> createState() => _TrackDetailViewState();
}

class _TrackDetailViewState extends ConsumerState<TrackDetailView> {
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
    weekDayOne = getThisWeekMonday();
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

    final logsFiltered =
        ref.watch(trackUrlFilteredLogsProvider.call(logs)).value ?? logs;

    final appBar = AppBar(title: Text(widget.url.split("/").last), actions: [
      IconButton(
          onPressed: handleAddTrack,
          icon: isTrack
              ? const Icon(Icons.visibility,
                      color: Color.fromARGB(255, 255, 120, 111))
                  .animate()
                  .shake(delay: 1.seconds, rotation: 0.4)
              : const Icon(Icons.visibility_off_outlined)),
      IconButton(
          onPressed: () async {
            await showAddShortLinkDialog();
            setState(() {});
          },
          icon: const RotatedBox(quarterTurns: 1, child: Icon(Icons.link))),
      IconButton(
          onPressed: () => showModalBottomSheet(
              backgroundColor: Colors.transparent,
              context: context,
              builder: (context) => TrackDetailFilterView(logs)),
          icon: logsFiltered.length == logs.length
              ? const Icon(Icons.filter_alt_off)
              : const Icon(Icons.filter_alt, color: Colors.green)
                  .animate()
                  .shake(delay: 1.seconds))
    ]);

    final items = ListView.builder(
        itemBuilder: (ctx, idx) {
          final c = logsFiltered[idx];
          final tag = c.iptag as String? ?? "";
          return ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              onTap: () async {
                showDialog(
                    context: context,
                    builder: (context) => Theme(
                        data: appThemeData,
                        child: SimpleDialog(
                            title: Text(c.ip.toString()),
                            children: [
                              SimpleDialogOption(
                                  onPressed: () async {
                                    await FlutterClipboard.copy(c.ip ?? "");
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text("已拷贝地址到剪贴板")));
                                  },
                                  child: const Text("拷贝地址到剪贴板")),
                              SimpleDialogOption(
                                  onPressed: () => launchUrlString(
                                      "https://www.ipshudi.com/${c.ip}.htm"),
                                  child: const Text("查看 IP 归属地详情...")),
                              tag.isEmpty
                                  ? SimpleDialogOption(
                                      onPressed: () => addIpTag(c),
                                      child: const Text("添加标签"))
                                  : SimpleDialogOption(
                                      onPressed: () => removeIpTag(c),
                                      child: const Text("删除标签",
                                          style: TextStyle(color: Colors.red)))
                            ])));
              },
              title: Text(c.ip ?? "No IP"),
              subtitle: buildDataRich(c.timestamp?.split(".").first),
              trailing: Text(
                  tag.isEmpty ? c.ipInfo ?? "" : "${c.iptag}\n${c.ipInfo}",
                  textAlign: TextAlign.end));
        },
        itemCount: logsFiltered.length);

    return Theme(
        data: appThemeData,
        child: Scaffold(
            appBar: appBar,
            body: RefreshIndicator(
                onRefresh: () async {
                  final d = await fetchDetail();
                  setState(() => logs = d?.logs ?? []);
                },
                child: Column(children: [
                  Expanded(
                      child: AnimatedOpacity(
                          opacity: logsFiltered.isNotEmpty ? 1 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: items)),
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

  addIpTag(Logs c) async {
    Navigator.of(context).pop();
    final label = TextEditingController();
    final answer = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Theme(
              data: appThemeData,
              child: AlertDialog(
                  title: Text("请输入 ${c.ip} 地址标签"),
                  content: TextField(
                      autofocus: true,
                      controller: label,
                      decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          hintText: "请输入 IP 地址标签")),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text("取消")),
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text("确定"))
                  ]),
            ));
    if (answer == true && label.text.isNotEmpty) {
      await ref
          .read(trackMarksProvider.notifier)
          .addOrRemoveLabel(c.ip!, label.text, true);
      final d = await fetchDetail();
      setState(() => logs = d?.logs ?? []);
    }
  }

  removeIpTag(Logs c) async {
    Navigator.of(context).pop();
    await ref
        .read(trackMarksProvider.notifier)
        .addOrRemoveLabel(c.ip!, "", false);
    final d = await fetchDetail();
    setState(() => logs = d?.logs ?? []);
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

class TrackDetailFilterView extends ConsumerStatefulWidget {
  final List<Logs> logs;
  const TrackDetailFilterView(this.logs, {super.key});

  @override
  ConsumerState<TrackDetailFilterView> createState() =>
      _TrackDetailFilterViewState();
}

class _TrackDetailFilterViewState extends ConsumerState<TrackDetailFilterView> {
  @override
  Widget build(BuildContext context) {
    final logs =
        ref.watch(trackUrlFiltersProvider.call(widget.logs)).value ?? {};
    final savedTrackCount = ref.read(trackMarksProvider).value?.length ?? -1;
    logs.remove("");
    return Theme(
        data: appThemeData,
        child: Scaffold(
            body: Padding(
                padding: const EdgeInsets.only(
                    left: 10, right: 10, top: 10, bottom: 10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("显示标签", style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 10),
                      Expanded(
                          child: logs.isEmpty
                              ? const Text("当前日志无 IP 地址标签")
                              : Wrap(
                                  runSpacing: 5,
                                  spacing: 5,
                                  children: logs.entries
                                      .map((e) => RawChip(
                                            label: Text(e.key),
                                            selected: !e.value,
                                            onSelected: (v) {
                                              ref
                                                  .read(trackMarksProvider
                                                      .notifier)
                                                  .set(e.key, !v);
                                            },
                                          ))
                                      .toList(growable: false))),
                      const Spacer(),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("已存储 $savedTrackCount 个键"),
                            const SizedBox(width: 20),
                            TextButton(
                                onPressed: () => ref
                                    .read(trackMarksProvider.notifier)
                                    .clean(true),
                                child: const Text("清空"))
                          ])
                    ]))));
  }
}
