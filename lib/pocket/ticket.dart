import 'dart:convert';

import 'package:clipboard/clipboard.dart';
import 'package:cyberme_flutter/pocket/config.dart';
import 'package:cyberme_flutter/pocket/models/ticket.dart' as t;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'main.dart';

class TicketShowPage extends StatefulWidget {
  const TicketShowPage({super.key});

  @override
  State<TicketShowPage> createState() => _TicketShowPageState();
}

class _TicketShowPageState extends State<TicketShowPage> {
  List<t.Data> recent = [];
  List<t.Data> history = [];
  late Config config;

  @override
  void initState() {
    super.initState();
    config = Provider.of<Config>(context, listen: false);
    handleReloadTickets();
  }

  Future handleDeleteTicket(
      t.Data ticket, bool canceled, bool undoCanceled) async {
    final res = await ticketDelete(config, ticket,
        canceled: canceled, undoCanceled: undoCanceled);
    await showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(title: const Text("结果"), content: Text(res), actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("确定"))
            ]));
    await handleReloadTickets();
  }

  Future handleReloadTickets() async {
    debugPrint("reload ticket from server");
    final d = await ticketRecent(config) as List<t.Data>;
    recent = d.where((element) => !element.isHistory).toList(growable: false);
    history = d.where((element) => element.isHistory).toList(growable: false);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("12306 最近车票"), actions: [
          IconButton(
              onPressed: () => Navigator.of(context)
                  .pushNamed(R.ticketParse.route)
                  .then((value) => Future.delayed(
                      const Duration(milliseconds: 1500), handleReloadTickets)),
              icon: const Icon(Icons.add_sharp))
        ]),
        body: Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: RefreshIndicator(
                onRefresh: handleReloadTickets,
                child: ListView(children: [
                  const Padding(
                      padding: EdgeInsets.only(left: 8, top: 8),
                      child: Text("待出行车票")),
                  ...recent
                      .map((e) => buildCard(e, handleDeleteTicket, context))
                      .toList(growable: false),
                  const Padding(
                      padding: EdgeInsets.only(left: 8, top: 8),
                      child: Text("历史车票")),
                  ...history
                      .map((e) => buildCard(e, handleDeleteTicket, context))
                      .toList(growable: false)
                ]))));
  }
}

class TicketParsePage extends StatefulWidget {
  const TicketParsePage({super.key});

  @override
  State<TicketParsePage> createState() => _TicketParsePageState();
}

class _TicketParsePageState extends State<TicketParsePage> {
  final input = TextEditingController();
  late Config config;
  List<t.Data> data = [];

  @override
  void initState() {
    super.initState();
    config = Provider.of<Config>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("12306 票据解析")),
        body: Column(mainAxisSize: MainAxisSize.max, children: [
          Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                  controller: input,
                  maxLines: 10,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()))),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: [
                ElevatedButton(
                    onPressed: () async {
                      final str = await FlutterClipboard.paste();
                      input.text = str;
                      data = [];
                      setState(() {});
                    },
                    child: const Text("从剪贴板读取")),
                ElevatedButton(
                    onPressed: handleParseTicket, child: const Text("解析票据")),
                ElevatedButton(
                    onPressed: () {
                      input.text = "";
                      data = [];
                      setState(() {});
                    },
                    child: const Text("清空"))
              ]),
          const SizedBox(height: 20),
          data.isEmpty
              ? const Text("")
              : Expanded(
                  child: SingleChildScrollView(
                      child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: buildParseResult(context))))
        ]));
  }

  Column buildParseResult(BuildContext context) {
    return Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(),
          Padding(
              padding: const EdgeInsets.all(5),
              child: Text("解析结果",
                  style: Theme.of(context).textTheme.headlineSmall)),
          ...data.map((e) => buildCard(e, (_, a, b) async {}, context)),
          const SizedBox(height: 20),
          SizedBox(
              width: double.infinity,
              child: Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: ElevatedButton(
                      onPressed: handleUpdateToServer,
                      child: const Text("更新到服务器"),
                      style: ButtonStyle(
                          foregroundColor: MaterialStatePropertyAll(
                              Theme.of(context).colorScheme.onPrimaryContainer),
                          backgroundColor: MaterialStatePropertyAll(
                              Theme.of(context)
                                  .colorScheme
                                  .primaryContainer))))),
          const SizedBox(height: 20)
        ]);
  }

  Future handleParseTicket() async {
    data = await tickerParse(config, input.text);
    if (data.isEmpty) {
      showDialog(
          context: context,
          builder: (c) => AlertDialog(
                  title: const Text("结果"),
                  content: const Text("未返回任何解析结果"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("确定"))
                  ]));
    } else {
      setState(() {});
    }
  }

  Future<String?> requireInput(String require) async {
    var ctr = TextEditingController();
    return showDialog(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text("补充数据"),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [Text(require), TextField(controller: ctr)]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text("取消")),
                  TextButton(
                      onPressed: () => Navigator.of(context)
                          .pop(ctr.text.isEmpty ? null : ctr.text),
                      child: const Text("确定"))
                ]));
  }

  Future handleUpdateToServer() async {
    for (final d in data) {
      d.end ??= await requireInput(
          "于 ${d.dateTime} 从 ${d.start} 的行程 ${d.trainNo} 需要补充终止站点");
      if (d.siteNo == null) {
        await Future.delayed(const Duration(seconds: 1));
        d.siteNo = await requireInput(
            "于 ${d.dateTime} 从 ${d.start} 到 ${d.end} 的行程需要补充座次信息");
      }
    }
    final resp = await ticketUpdate(config, data);
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 600));
    await showDialog(
        context: context,
        builder: (c) =>
            AlertDialog(title: const Text("结果"), content: Text(resp), actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("确定"))
            ]));
  }
}

final formatter = DateFormat("yyyy-MM-dd HH:mm");
final dateFormatter = DateFormat("yyyy-MM-dd");
final timeFormatter = DateFormat("HH:mm");

Widget buildCard(t.Data ticket,
    Future Function(t.Data, bool, bool) deleteTicket, BuildContext context) {
  return GestureDetector(
    onTap: () {
      showCupertinoModalPopup(
          context: context,
          builder: (context) => CupertinoActionSheet(
                  actions: [
                    CupertinoActionSheetAction(
                        onPressed: () {}, child: const Text("修改")),
                    CupertinoActionSheetAction(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          if (ticket.canceled == null ||
                              ticket.canceled! == false) {
                            await deleteTicket(ticket, true, false);
                          } else {
                            await deleteTicket(ticket, false, true);
                          }
                        },
                        child: Text(
                            ticket.canceled == null || ticket.canceled! == false
                                ? "改签"
                                : "取消改签")),
                    CupertinoActionSheetAction(
                        onPressed: () async {
                          final res = await showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => AlertDialog(
                                      title: const Text("删除票据"),
                                      content: const Text("确定删除此票据吗，此操作不可恢复。"),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pop(false),
                                            child: const Text("取消")),
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text("确定"))
                                      ])) as bool;
                          if (res) {
                            Navigator.of(context).pop();
                            await deleteTicket(ticket, false, false);
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text("删除"),
                        isDestructiveAction: true)
                  ],
                  cancelButton: CupertinoActionSheetAction(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("取消"))));
    },
    child: Card(
        elevation: 0.1,
        child: ListTile(
            title: Row(children: [
              Text(ticket.startPretty ?? "未知目的地"),
              const Padding(
                  padding: EdgeInsets.only(left: 3, right: 3),
                  child: Text("→")),
              Text(ticket.endPretty ?? "未知终点"),
              const SizedBox(width: 5),
              Text(
                  ticket.canceled == null || ticket.canceled! == false
                      ? ""
                      : "(已改签)",
                  style: const TextStyle(fontSize: 10))
            ]),
            subtitle: Row(children: [
              Text("${dateFormatter.format(ticket.dateTime!)} "),
              Text(timeFormatter.format(ticket.dateTime!),
                  style: const TextStyle(decoration: TextDecoration.underline)),
              const Text("开"),
              const Spacer(),
              const SizedBox(width: 5),
              SizedBox(
                  width: 60,
                  child: Text("${ticket.trainNo}",
                      style: const TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(width: 5),
              SizedBox(child: Text(ticket.siteNo ?? ""), width: 70)
            ]))),
  );
}

Future<dynamic> ticketRecent(Config config) async {
  final r = await get(
      Uri.parse(Config.recentTicketUrl + "?include-canceled=true"),
      headers: config.cyberBase64Header);
  final j = jsonDecode(r.body);
  if ((j["status"] as int) > 0) {
    final d = (j["data"] as List<dynamic>?) ?? [];
    return d.map((e) => t.Data.fromJson(e)).toList(growable: false);
  }
  return [];
}

Future<String> ticketDelete(Config config, t.Data ticket,
    {bool canceled = false, bool undoCanceled = false}) async {
  final date = DateFormat("yyyyMMdd_HH:mm").format(ticket.dateTime!);
  try {
    final r = await get(
        Uri.parse(Config.deleteTicketUrl +
            date +
            "?is-canceled=$canceled&undo-canceled=$undoCanceled"),
        headers: config.cyberBase64Header);
    final j = jsonDecode(r.body);
    return j["message"] ?? "无返回信息";
  } catch (e) {
    return e.toString();
  }
}

Future<dynamic> tickerParse(Config config, String content,
    {bool dry = true}) async {
  final Response r = await post(Uri.parse(Config.parseTicketUrl),
      headers: config.cyberBase64JsonContentHeader,
      body: jsonEncode({"content": content, "dry": dry}));
  final jsonData = jsonDecode(r.body);
  if (dry) {
    final data = t.Ticket.fromJson(jsonData);
    return data.data ?? [];
  } else {
    return jsonData["message"] ?? "服务未返回消息";
  }
}

Future<dynamic> ticketUpdate(Config config, List<t.Data> tickets) async {
  final data =
      jsonEncode(tickets.map((e) => e.toJson()).toList(growable: false));
  final Response r = await post(Uri.parse(Config.addTicketsUrl),
      headers: config.cyberBase64JsonContentHeader, body: data);
  final jsonData = jsonDecode(r.body);
  return jsonData["message"] ?? "服务未返回消息";
}
