import 'package:clipboard/clipboard.dart';
import 'package:cyberme_flutter/pocket/models/day.dart';
import 'package:flutter/material.dart';
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
    return Scaffold(
        appBar: AppBar(title: const Text("快递追踪")),
        body: RefreshIndicator(
            onRefresh: () async {
              dashboard = await Dashboard.loadFromApi(config!);
              setState(() {});
            },
            child: ListView(
                children: ((dashboard?.express) ?? [])
                    .map((e) => ListTile(
                        onTap: () {
                          FlutterClipboard.copy(e.id).then((value) =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("已拷贝快递单号到剪贴板。"))));
                        },
                        title: Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(children: [
                            Text(e.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Text(e.lastUpdate.split(".").firstOrNull ?? "",
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: Colors.black45))
                          ]),
                        ),
                        subtitle: DefaultTextStyle(
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black87),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...e.extra.map((e) => Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(e.$1),
                                            Text(e.$2),
                                            const SizedBox(height: 5)
                                          ]))
                                ]))))
                    .toList(growable: false))));
  }

  void handleAdd() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (c) => const ExpressAddView()));
  }
}

class ExpressAddView extends StatefulWidget {
  const ExpressAddView({super.key});

  @override
  State<ExpressAddView> createState() => _ExpressAddViewState();
}

class _ExpressAddViewState extends State<ExpressAddView> {
  final formKey = GlobalKey<FormState>();
  var rewrite = false;
  var wait = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("添加新的快递")),
        body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
                key: formKey,
                child: Column(children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: "快递单号*"),
                    validator: (v) => v!.isNotEmpty ? null : "需要提供单号",
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "快递备注*"),
                    validator: (v) => v!.isNotEmpty ? null : "需要提供快递备注",
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: "收货人手机后四位", helperText: "顺丰快递需要填写"),
                  ),
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
                          if (formKey.currentState!.validate()) {}
                        },
                        child: const Text("提交"))
                  ])
                ]))));
  }
}
