import 'dart:convert';

import 'package:clipboard/clipboard.dart';
import 'package:cyberme_flutter/main.dart';
import 'package:cyberme_flutter/pocket/config.dart';
import 'package:cyberme_flutter/pocket/models/ticket.dart' as t;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';

class TicketPainter extends CustomPainter {
  final bool isHistory;

  TicketPainter({super.repaint, required this.isHistory});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isHistory
          ? const Color.fromARGB(255, 78, 78, 78)
          : Colors.red.shade400
      ..style = PaintingStyle.fill;

    canvas.drawRect(const Rect.fromLTWH(-1, 10, 60, 12), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class TicketShowPage extends ConsumerStatefulWidget {
  const TicketShowPage({super.key});

  @override
  ConsumerState<TicketShowPage> createState() => _TicketShowPageState();
}

class _TicketShowPageState extends ConsumerState<TicketShowPage> {
  List<t.Data> recent = [];
  List<t.Data> history = [];

  @override
  void initState() {
    super.initState();
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
    final d = await ticketRecent(config) as List<t.Data>;
    recent = d.where((element) => !element.isHistory).toList(growable: false);
    history = d.where((element) => element.isHistory).toList(growable: false);
    setState(() {});
  }

  bool showJustTake = true;

  @override
  Widget build(BuildContext context) {
    final recentCards = recent
        .where((element) =>
            showJustTake ? (element.canceled ?? false) == false : true)
        .map((e) => buildCard(e, handleDeleteTicket, context));
    final historyCards = history
        .where((element) =>
            showJustTake ? (element.canceled ?? false) == false : true)
        .map((e) => buildCard(e, handleDeleteTicket, context));
    return Theme(
        data: appThemeData,
        child: Scaffold(
            body: CustomScrollView(slivers: [
          SliverAppBar.large(
              actions: [
                IconButton(
                    onPressed: handleParse, icon: const Icon(Icons.add_card)),
                IconButton(
                    onPressed: handleReloadTickets,
                    icon: const Icon(Icons.refresh)),
                IconButton(
                    onPressed: () =>
                        setState(() => showJustTake = !showJustTake),
                    icon: Icon(
                        showJustTake ? Icons.filter_alt : Icons.filter_alt_off))
              ],
              pinned: true,
              foregroundColor: Colors.black,
              stretch: true,
              expandedHeight: 190,
              flexibleSpace: Container(
                  decoration: const BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage("images/train3.png"),
                          fit: BoxFit.cover,
                          alignment: Alignment.center)))),
          SliverList(
              delegate: SliverChildListDelegate([
            Padding(
                padding: const EdgeInsets.only(left: 15, top: 15),
                child: CustomPaint(
                    painter: TicketPainter(isHistory: false),
                    child: const Text("待出行车票",
                        style: TextStyle(fontWeight: FontWeight.bold)))),
            ...recentCards,
            Padding(
                padding: const EdgeInsets.only(left: 15, top: 8),
                child: CustomPaint(
                    painter: TicketPainter(isHistory: true),
                    child: const Text("历史车票",
                        style: TextStyle(fontWeight: FontWeight.bold)))),
            ...historyCards
          ])),
          SliverToBoxAdapter(
              child: ButtonBar(alignment: MainAxisAlignment.center, children: [
            TextButton(onPressed: handleParse, child: const Text("解析票据"))
          ]))
        ])));
  }

  handleParse() async {
    await showModalBottomSheet(
        showDragHandle: false,
        isScrollControlled: true,
        context: context,
        builder: (c) => SizedBox(
              height: MediaQuery.maybeSizeOf(context)!.height / 1.5,
              child: const TicketParsePage(),
            ));
    await handleReloadTickets();
  }
}

class TicketParsePage extends StatefulWidget {
  const TicketParsePage({super.key});

  @override
  State<TicketParsePage> createState() => _TicketParsePageState();
}

class _TicketParsePageState extends State<TicketParsePage> {
  final input = TextEditingController();
  List<t.Data> data = [];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appThemeData,
      child: Scaffold(
          //appBar: AppBar(title: const Text("12306 票据解析")),
          body: Column(mainAxisSize: MainAxisSize.max, children: [
        const SizedBox(height: 10),
        Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
                controller: input,
                maxLines: 3,
                decoration:
                    const InputDecoration(border: OutlineInputBorder()))),
        ButtonBar(alignment: MainAxisAlignment.spaceAround, children: [
          TextButton(
              onPressed: () async {
                final str = await FlutterClipboard.paste();
                input.text = str;
                data = [];
                setState(() {});
              },
              child: const Text("从剪贴板读取")),
          TextButton(onPressed: handleParseTicket, child: const Text("解析票据")),
          TextButton(
              onPressed: () {
                input.text = "";
                data = [];
                setState(() {});
              },
              child: const Text("清空")),
          TextButton(
              onPressed: () => FocusScope.of(context).unfocus(),
              child: const Text("隐藏键盘"))
        ]),
        data.isEmpty
            ? const Text("")
            : Expanded(
                child: SingleChildScrollView(
                    child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: buildParseResult(context))))
      ])),
    );
  }

  Column buildParseResult(BuildContext context) {
    return Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(),
          Text("解析结果", style: Theme.of(context).textTheme.bodyLarge),
          ...data.map((e) => buildCard(e, (_, a, b) async {}, context)),
          const SizedBox(height: 10),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("未返回任何解析结果"),
          action: SnackBarAction(label: "确定", onPressed: () {})));
      /*showDialog(
          context: context,
          builder: (c) => AlertDialog(
                  title: const Text("结果"),
                  content: const Text("未返回任何解析结果"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("确定"))
                  ]));*/
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
  handleChange() async {
    Navigator.of(context).pop();
    if (ticket.canceled == null || ticket.canceled! == false) {
      await deleteTicket(ticket, true, false);
    } else {
      await deleteTicket(ticket, false, true);
    }
  }

  handleDelete() async {
    final res = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
                title: const Text("删除票据"),
                content: const Text("确定删除此票据吗，此操作不可恢复。"),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("取消")),
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text("确定"))
                ])) as bool;
    if (res) {
      Navigator.of(context).pop();
      await deleteTicket(ticket, false, false);
    } else {
      Navigator.of(context).pop();
    }
  }

  handlePopup() {
    showDialog(
        context: context,
        builder: (context) => Theme(
            data: appThemeData,
            child:
                SimpleDialog(title: Text(ticket.trainNo.toString()), children: [
              SimpleDialogOption(
                  onPressed: handleChange,
                  child: Text(
                      ticket.canceled == null || ticket.canceled! == false
                          ? "改签"
                          : "取消改签")),
              SimpleDialogOption(
                  onPressed: handleDelete, child: const Text("删除"))
            ])));
  }

  return ListTile(
      onTap: handlePopup,
      title: Row(children: [
        Text(ticket.startPretty ?? "未知目的地"),
        const Padding(
            padding: EdgeInsets.only(left: 3, right: 3), child: Text("→")),
        Text(ticket.endPretty ?? "未知终点"),
        const SizedBox(width: 5),
        Text(
            ticket.canceled == null || ticket.canceled! == false ? "" : "(已改签)",
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
      ]));
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
