import 'package:cyberme_flutter/pocket/viewmodels/dns.dart';
import 'package:cyberme_flutter/pocket/views/server/common.dart';
import 'package:cyberme_flutter/pocket/views/util.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'record.dart';

class DnsView extends ConsumerStatefulWidget {
  const DnsView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DnsViewState();
}

mixin Loading {
  Widget loading = const Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
        CircularProgressIndicator(),
        SizedBox(height: 10),
        Text("正在加载...")
      ]));
  Widget error(String msg) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error, color: Colors.red),
      const SizedBox(height: 10),
      Text("加载失败: $msg", style: const TextStyle(color: Colors.red))
    ]));
  }
}

class _DnsViewState extends ConsumerState<DnsView> with Loading {
  @override
  Widget build(BuildContext context) {
    final setting = ref.watch(dnsSettingDbProvider).value ?? DnsSetting();
    final zone = ref.watch(getZoneProvider).value;
    final body = zone == null
        ? loading
        : zone.$1.isNotEmpty
            ? error(zone.$1)
            : ListView.builder(
                itemBuilder: (context, index) {
                  final z = zone.$2![index];
                  return ListTile(
                    dense: true,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => ZoneDnsView(setting, z)));
                    },
                    title: Text(z.name,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary)),
                    subtitle: DefaultTextStyle(
                        style: TextStyle(
                            fontFamily: "consolas",
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.secondary),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (z.original_registrar.isNotEmpty)
                                Text(z.original_registrar.toString()),
                              Text("更新于: " +
                                  z.modified_on.toString().substring(0, 10)),
                            ])),
                    trailing: z.status == "active"
                        ? const Icon(Icons.online_prediction,
                            color: Colors.green)
                        : const Icon(Icons.offline_bolt, color: Colors.red),
                  );
                },
                itemCount: zone.$2!.length);
    return Scaffold(
        appBar: AppBar(title: const Text("DNS"), actions: [
          IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => DnsSettingView(setting: setting)))),
          const SizedBox(width: 10)
        ]),
        body: body);
  }
}

class DnsSettingView extends ConsumerStatefulWidget {
  final DnsSetting setting;
  const DnsSettingView({required this.setting, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DnsSettingViewState();
}

class _DnsSettingViewState extends ConsumerState<DnsSettingView> {
  late var data = widget.setting;
  final key = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("DNS Setting"), actions: [
          IconButton(
              onPressed: () async {
                if (!key.currentState!.validate()) return;
                key.currentState!.save();
                final res =
                    await ref.read(dnsSettingDbProvider.notifier).save(data);
                await showSimpleMessage(context, content: res);
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.save)),
          const SizedBox(width: 10)
        ]),
        body: Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: Form(
              key: key,
              child: Column(children: [
                TextFormField(
                    initialValue: data.cloudflareEmail,
                    decoration:
                        const InputDecoration(labelText: "Cloudflare Email"),
                    onSaved: (value) =>
                        data = data.copyWith(cloudflareEmail: value!),
                    validator: (value) =>
                        value!.isEmpty ? "Email is required" : null),
                TextFormField(
                  initialValue: data.cloudflareApiKey,
                  decoration:
                      const InputDecoration(labelText: "Cloudflare API Key"),
                  onSaved: (value) =>
                      data = data.copyWith(cloudflareApiKey: value!),
                  validator: (value) =>
                      value!.isEmpty ? "API Key is required" : null,
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Text(
                      "Api Token Expired: ${expiredFormat(expiredTo(data.cloudflareExpiredAt == 0 ? DateTime.now().millisecondsSinceEpoch ~/ 1000 : data.cloudflareExpiredAt))}"),
                  const Spacer(),
                  TextButton(
                      onPressed: () async {
                        final res = await showDatePicker(
                            context: context,
                            initialDate: data.cloudflareExpiredAt == 0
                                ? DateTime.now()
                                : DateTime.fromMillisecondsSinceEpoch(
                                    data.cloudflareExpiredAt * 1000),
                            firstDate: DateTime(2019),
                            lastDate: DateTime(2035));
                        if (res != null) {
                          data = data.copyWith(
                              cloudflareExpiredAt:
                                  res.millisecondsSinceEpoch ~/ 1000);
                          setState(() {});
                        }
                      },
                      child: const Text("Edit"))
                ])
              ])),
        ));
  }
}
