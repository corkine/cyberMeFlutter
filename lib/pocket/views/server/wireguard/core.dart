import 'dart:convert';

import 'package:cyberme_flutter/pocket/viewmodels/wireguard.dart';
import 'package:cyberme_flutter/pocket/views/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';

class WireguardView extends ConsumerStatefulWidget {
  const WireguardView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _WireguardViewState();
}

class _WireguardViewState extends ConsumerState<WireguardView> {
  @override
  Widget build(BuildContext context) {
    final res = ref.watch(netDbProvider).value ?? [];
    return Scaffold(
        appBar: AppBar(
          title: const Text("Wiregaurd"),
          actions: [
            IconButton(onPressed: () async {}, icon: const Icon(Icons.add)),
            const SizedBox(width: 5)
          ],
        ),
        body: ListView.builder(
            itemBuilder: (context, index) {
              final v = res[index];
              return Dismissible(
                  key: ValueKey(v.id),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      if (await showSimpleMessage(context,
                          content: "确实要删除此网络吗?")) {
                        final res =
                            await ref.read(netDbProvider.notifier).delete(v.id);
                        await showSimpleMessage(context,
                            content: res, useSnackBar: true);
                      }
                    } else {
                      await ref.read(netDbProvider.notifier).change(Net(
                          id: const Uuid().v4(),
                          name: v.name + "_copy",
                          server: v.server,
                          clients: v.clients,
                          lastUpdate: v.lastUpdate));
                      await showSimpleMessage(context,
                          content: "已按照模板拷贝网络", useSnackBar: true);
                    }
                    return false;
                  },
                  secondaryBackground: Container(
                      color: Colors.red,
                      child: const Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                              padding: EdgeInsets.only(right: 20),
                              child: Text("删除",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 15))))),
                  background: Container(
                      color: Colors.blue,
                      child: const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                              padding: EdgeInsets.only(left: 20),
                              child: Text("原样拷贝",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 15))))),
                  child: ListTile(
                      dense: true,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => WireguardNodeView(net: v))),
                      title: Text(v.name),
                      trailing: CircleAvatar(
                          child: Text(v.clients.length.toString()),
                          backgroundColor:
                              Theme.of(context).colorScheme.tertiaryContainer),
                      subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.server.ip + ":" + v.server.port),
                            Text(v.server.name)
                          ])));
            },
            itemCount: res.length));
  }
}

void showWireGuardQRDialog(BuildContext context, String configContent) {
  String encodedConfig = configContent;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Scan this QR code to configure WireGuard'),
          const SizedBox(height: 10),
          QrImageView(
              data: encodedConfig, version: QrVersions.auto, size: 200.0)
        ])),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

class WireguardNodeView extends ConsumerStatefulWidget {
  final Net net;
  const WireguardNodeView({super.key, required this.net});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _WireguardNodeViewState();
}

class _WireguardNodeViewState extends ConsumerState<WireguardNodeView> {
  late Net net = widget.net;
  @override
  Widget build(BuildContext context) {
    ref.listen(netDbProvider, (o, n) {
      for (var e in (n.value ?? [])) {
        if (e.id == net.id) {
          net = e;
          setState(() {});
          break;
        }
      }
    });
    return Scaffold(
        appBar: AppBar(
            actions: [
              IconButton(
                  onPressed: () async {
                    final res =
                        await ref.read(netDbProvider.notifier).change(net);
                    showSimpleMessage(context, content: res, useSnackBar: true);
                  },
                  icon: const Icon(Icons.save)),
              IconButton(
                  onPressed: () async {
                    final cs = [
                      ...net.clients,
                      const NetClient(
                          address: "10.0.0.R/24",
                          allowedIPs: "0.0.0.0/0",
                          name: "REPLACE_ME",
                          privateKey: "",
                          publicKey: "")
                    ];
                    await ref
                        .read(netDbProvider.notifier)
                        .localChange(net.copyWith(clients: cs));
                  },
                  icon: const Icon(Icons.add)),
              const SizedBox(width: 5)
            ],
            title: InkWell(
                onTap: () async {
                  final nv = await showInputDialog(context, value: net.name);
                  if (nv.isNotEmpty) {
                    await ref
                        .read(netDbProvider.notifier)
                        .localChange(net.copyWith(name: nv));
                  }
                },
                child: Text(net.name, style: const TextStyle(fontSize: 16)))),
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              margin:
                  const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 0),
              padding: const EdgeInsets.only(
                  left: 20, right: 20, top: 10, bottom: 10),
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  color: Theme.of(context).colorScheme.primaryContainer),
              child: buildServer(context)),
          Expanded(child: buildClients())
        ]));
  }

  ListView buildClients() {
    return ListView.builder(
        itemBuilder: (context, index) {
          final c = net.clients[index];
          return ListTile(
              title: InkWell(
                  onLongPress: () async {
                    if (await showSimpleMessage(context,
                        content: "确定删除此客户端吗?")) {
                      final cs = [...net.clients];
                      cs.removeAt(index);
                      await ref
                          .read(netDbProvider.notifier)
                          .localChange(net.copyWith(clients: cs));
                    }
                  },
                  onTap: () async {
                    final nv = await showInputDialog(context, value: c.name);
                    if (nv.isNotEmpty) {
                      final cs = [...net.clients];
                      cs[index] = c.copyWith(name: nv);
                      await ref
                          .read(netDbProvider.notifier)
                          .localChange(net.copyWith(clients: cs));
                    }
                  },
                  child: Text(c.name)),
              subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () async {
                        final nv =
                            await showInputDialog(context, value: c.address);
                        if (nv.isNotEmpty) {
                          final cs = [...net.clients];
                          cs[index] = c.copyWith(address: nv);
                          await ref
                              .read(netDbProvider.notifier)
                              .localChange(net.copyWith(clients: cs));
                        }
                      },
                      child: Text(c.address,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary)),
                    ),
                    InkWell(
                      onTap: () async {
                        final nv =
                            await showInputDialog(context, value: c.allowedIPs);
                        if (nv.isNotEmpty) {
                          final cs = [...net.clients];
                          cs[index] = c.copyWith(allowedIPs: nv);
                          await ref
                              .read(netDbProvider.notifier)
                              .localChange(net.copyWith(clients: cs));
                        }
                      },
                      child: Text("AllowIPs: ${c.allowedIPs}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.secondary)),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero),
                          onLongPress: () async {
                            final nv = await showInputDialog(context,
                                value: c.publicKey);
                            if (nv.isNotEmpty) {
                              final cs = [...net.clients];
                              cs[index] = c.copyWith(publicKey: nv);
                              await ref
                                  .read(netDbProvider.notifier)
                                  .localChange(net.copyWith(clients: cs));
                            }
                          },
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: c.publicKey));
                            showSimpleMessage(context,
                                content: "已拷贝", useSnackBar: true);
                          },
                          child: const Text("公钥")),
                      const SizedBox(width: 6),
                      OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero),
                          onLongPress: () async {
                            final nv = await showInputDialog(context,
                                value: c.privateKey);
                            if (nv.isNotEmpty) {
                              final cs = [...net.clients];
                              cs[index] = c.copyWith(privateKey: nv);
                              await ref
                                  .read(netDbProvider.notifier)
                                  .localChange(net.copyWith(clients: cs));
                            }
                          },
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: c.privateKey));
                            showSimpleMessage(context,
                                content: "已拷贝", useSnackBar: true);
                          },
                          child: const Text("私钥")),
                      const SizedBox(width: 6),
                      OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero),
                          onPressed: () {
                            final config = genConfig(net, c);
                            Clipboard.setData(ClipboardData(text: config));
                            showSimpleMessage(context,
                                content: "已拷贝", useSnackBar: true);
                          },
                          child: const Text("配置")),
                      const SizedBox(width: 6),
                      OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero),
                          onPressed: () {
                            showWireGuardQRDialog(context, genConfig(net, c));
                          },
                          child: const Text("QR")),
                      const SizedBox(width: 6),
                      OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero),
                          onPressed: () {
                            final config = genCommand(net, c);
                            Clipboard.setData(ClipboardData(text: config));
                            showSimpleMessage(context,
                                content: "已拷贝", useSnackBar: true);
                          },
                          child: const Text("命令")),
                    ])
                  ]));
        },
        itemCount: net.clients.length);
  }

  Column buildServer(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () async {
            final nv = await showInputDialog(context, value: net.server.name);
            if (nv.isNotEmpty) {
              await ref.read(netDbProvider.notifier).localChange(
                  net.copyWith(server: net.server.copyWith(name: nv)));
            }
          },
          child: Text(net.server.name,
              style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        ),
        InkWell(
          onTap: () async {
            final nv = await showInputDialog(context,
                value: net.server.ip + ":" + net.server.port);
            if (nv.isNotEmpty) {
              final ip = nv.split(":")[0];
              final port = nv.split(":")[1];
              await ref.read(netDbProvider.notifier).localChange(net.copyWith(
                  server: net.server.copyWith(ip: ip, port: port)));
            }
          },
          child: Text(net.server.ip + ":" + net.server.port,
              style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            OutlinedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: net.server.publicKey));
                  showSimpleMessage(context, content: "已拷贝", useSnackBar: true);
                },
                onLongPress: () async {
                  final nv = await showInputDialog(context,
                      value: net.server.publicKey);
                  if (nv.isNotEmpty) {
                    await ref.read(netDbProvider.notifier).localChange(net
                        .copyWith(server: net.server.copyWith(publicKey: nv)));
                  }
                },
                child: const Text("公钥")),
            const SizedBox(width: 8),
            OutlinedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: net.server.privateKey));
                  showSimpleMessage(context, content: "已拷贝", useSnackBar: true);
                },
                onLongPress: () async {
                  final nv = await showInputDialog(context,
                      value: net.server.privateKey);
                  if (nv.isNotEmpty) {
                    await ref.read(netDbProvider.notifier).localChange(net
                        .copyWith(server: net.server.copyWith(privateKey: nv)));
                  }
                },
                child: const Text("私钥")),
          ],
        )
      ],
    );
  }

  String genConfig(Net net, NetClient c) {
    return """
[Interface]
PrivateKey = ${c.privateKey}
Address = ${c.address}
DNS = 1.1.1.1

[Peer]
PublicKey = ${net.server.publicKey}
AllowedIPs = ${c.allowedIPs}
Endpoint = ${net.server.ip}:${net.server.port}
PersistentKeepalive = 15
""";
  }

  String genCommand(Net net, NetClient c) {
    return "sudo wg set wg0 peer ${c.publicKey} allowed-ips ${c.address.split("/").first}";
  }
}

Future<String> showInputDialog(BuildContext context,
    {String title = '输入', String hint = '', String value = ''}) async {
  TextEditingController c = TextEditingController(text: value);

  return await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: TextField(
              autofocus: true,
              controller: c,
              decoration: InputDecoration(hintText: hint),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop('');
                },
              ),
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(c.text);
                },
              ),
            ],
          );
        },
      ) ??
      '';
}
