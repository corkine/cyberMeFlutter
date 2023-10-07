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
        body: Padding(
          padding: const EdgeInsets.only(left: 8, right: 8),
          child: RefreshIndicator(
              onRefresh: () async {
                dashboard = await Dashboard.loadFromApi(config!);
                setState(() {});
              },
              child: ListView(
                children: ((dashboard?.express) ?? [])
                    .map((e) => Card(
                            child: ListTile(
                          title: Row(
                            children: [
                              Text(e.name),
                              const Spacer(),
                              Text(e.lastUpdate,
                                  style: Theme.of(context).textTheme.labelSmall)
                            ],
                          ),
                          subtitle: Text(e.info),
                        )))
                    .toList(growable: false),
              )),
        ));
  }
}
