import 'package:cyberme_flutter/main.dart';
import 'package:cyberme_flutter/pocket/viewmodels/expired.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ExpiredView extends ConsumerStatefulWidget {
  const ExpiredView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ExpiredViewState();
}

class _ExpiredViewState extends ConsumerState<ExpiredView> {
  bool force = false;
  Widget good = Icon(Icons.check, color: Colors.green);
  Widget bad = Icon(Icons.close, color: Colors.red);
  @override
  Widget build(BuildContext context) {
    final items = ref.watch(getExpiredItemsProvider.call(force: force)).value ??
        ExpiredItems();
    return Theme(
        data: appThemeData,
        child: Scaffold(
            appBar: AppBar(title: Text("过期提醒"), actions: [
              IconButton(
                  onPressed: () {
                    force = true;
                    ref.invalidate(getExpiredItemsProvider);
                  },
                  icon: Icon(Icons.refresh)),
              const SizedBox(width: 10)
            ]),
            body: Padding(
                padding: const EdgeInsets.only(left: 5, right: 5),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                          onTap: () => Navigator.pushNamed(
                              context, "/app/server",
                              arguments: {"index": 1}),
                          leading: items.server.isEmpty ? good : bad,
                          title: Text("服务器"),
                          subtitle: buildHint(items.server)),
                      ListTile(
                          onTap: () => Navigator.pushNamed(
                              context, "/app/server",
                              arguments: {"index": 2}),
                          leading: items.token.isEmpty ? good : bad,
                          title: Text("访问密钥"),
                          subtitle: buildHint(items.token)),
                      ListTile(
                          onTap: () =>
                              Navigator.pushNamed(context, "/app/image"),
                          leading: items.registry.isEmpty ? good : bad,
                          title: Text("容器仓库"),
                          subtitle: buildHint(items.registry)),
                      ListTile(
                          onTap: () =>
                              Navigator.pushNamed(context, "/app/cert-manager"),
                          leading: items.cert.isEmpty ? good : bad,
                          title: Text("HTTPS证书"),
                          subtitle: buildHint(items.cert))
                    ]))));
  }

  Widget buildHint(List<String> items) {
    if (items.isEmpty)
      return Text("OK");
    else
      return Text(items.join("\n"));
  }
}
