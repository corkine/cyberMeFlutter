import 'dart:convert';

import 'package:clipboard/clipboard.dart';
import 'package:cyberme_flutter/pocket/models/day.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import 'config.dart';

class ExpressView extends StatefulWidget {
  const ExpressView({super.key});

  @override
  State<ExpressView> createState() => _ExpressViewState();
}

class _ExpressViewState extends State<ExpressView> {
  @override
  void didChangeDependencies() {
    if (dashboard == null) {
      config = Provider.of<Config>(context, listen: false);
      Dashboard.loadFromApi(config!)
          .then((value) => setState(() => dashboard = value));
    }
    super.didChangeDependencies();
  }

  Config? config;
  Dashboard? dashboard;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(title: const Text("快递追踪"), centerTitle: true),
            body: Column(children: [
              Expanded(
                  child: RefreshIndicator(
                      onRefresh: () async {
                        dashboard = await Dashboard.loadFromApi(config!);
                        setState(() {});
                      },
                      child: ListView(
                          children: ((dashboard?.express) ?? [])
                              .map((e) => buildExpressTile(e, context))
                              .toList(growable: false)))),
              ButtonBar(alignment: MainAxisAlignment.center, children: [
                TextButton(
                    onPressed: () async {
                      dashboard = await Dashboard.loadFromApi(config!);
                      setState(() {});
                    },
                    child: const Text("刷新")),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (c) => ExpressAddView(config: config!)));
                    },
                    child: const Text("添加快递"))
              ])
            ])));
  }

  ListTile buildExpressTile(Express e, BuildContext context) {
    return ListTile(
        onTap: () {
          showCupertinoModalPopup(
              context: context,
              builder: (context) => CupertinoActionSheet(
                      actions: [
                        CupertinoActionSheetAction(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await handleDeleteExpress(e.id);
                              dashboard = await Dashboard.loadFromApi(config!);
                              setState(() {});
                            },
                            child: const Text("删除"))
                      ],
                      cancelButton: CupertinoActionSheetAction(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("取消"))));
        },
        onLongPress: () {
          FlutterClipboard.copy(e.id).then((value) =>
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text("已拷贝快递单号到剪贴板。"))));
        },
        title: Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(children: [
              Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(e.id,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: Colors.black45))
            ])),
        subtitle: DefaultTextStyle(
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ...e.extra.map((e) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.$1),
                        Text(e.$2),
                        const SizedBox(height: 5)
                      ]))
            ])));
  }

  handleDeleteExpress(String no) async {
    final r = await get(Uri.parse(Config.deleteExpress(no)),
        headers: config!.cyberBase64Header);
    final d = jsonDecode(r.body);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(d["message"])));
  }
}

class ExpressAddView extends StatefulWidget {
  final Config config;

  const ExpressAddView({super.key, required this.config});

  @override
  State<ExpressAddView> createState() => _ExpressAddViewState();
}

class _ExpressAddViewState extends State<ExpressAddView> {
  final formKey = GlobalKey<FormState>();
  var rewrite = false;
  var wait = true;
  var id = TextEditingController();
  var note = '';
  var sfPhone = '';

  @override
  void initState() {
    super.initState();
    FlutterClipboard.paste().then((value) => id.text = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("添加快递"), centerTitle: true),
        body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
                key: formKey,
                child: Column(children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: "快递单号*"),
                    validator: (v) => v!.isNotEmpty ? null : "需要提供单号",
                    controller: id,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "快递备注*"),
                    validator: (v) => v!.isNotEmpty ? null : "需要提供快递备注",
                    onChanged: (e) => note = e,
                  ),
                  TextFormField(
                      decoration: const InputDecoration(
                          labelText: "收货人手机后四位", helperText: "顺丰快递需要填写"),
                      onChanged: (e) => sfPhone = e),
                  const SizedBox(height: 10),
                  Transform.translate(
                      offset: const Offset(-10, 0),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Checkbox(
                                value: rewrite,
                                onChanged: (n) => setState(() {
                                      rewrite = n!;
                                    })),
                            const Text("如果存在，则覆盖")
                          ])),
                  Transform.translate(
                      offset: const Offset(-10, -10),
                      child: Row(children: [
                        Checkbox(
                            value: wait,
                            onChanged: (n) => setState(() {
                                  wait = n!;
                                })),
                        const Text("如果不存在，则加入等待列表")
                      ])),
                  ButtonBar(children: [
                    TextButton(
                        onPressed: () {
                          formKey.currentState?.reset();
                          id.clear();
                        },
                        child: const Text("清空")),
                    TextButton(
                        onPressed: () async {
                          final d = await FlutterClipboard.paste();
                          if (d.isNotEmpty) {
                            setState(() => id.text = d);
                          }
                        },
                        child: const Text("从剪贴板粘贴单号")),
                    TextButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            handleAdd(
                                widget.config,
                                sfPhone.isNotEmpty
                                    ? "${id.text}:$sfPhone"
                                    : id.text,
                                note,
                                rewrite,
                                wait);
                          }
                        },
                        child: const Text("提交"))
                  ])
                ]))));
  }

  handleAdd(Config c, String no, String note, bool rewrite, bool wait) async {
    final r = await get(
        Uri.parse(Config.expressAddUrl(note, rewrite, wait, no)),
        headers: c.cyberBase64Header);
    final d = jsonDecode(r.body);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(d["message"])));
  }
}
