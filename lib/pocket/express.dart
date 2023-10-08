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
}
