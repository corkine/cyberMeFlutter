import 'package:cyberme_flutter/pocket/views/server/service/common.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:uuid/uuid.dart';

import '../../../viewmodels/service.dart';

class ServerEmbededView extends ConsumerWidget {
  const ServerEmbededView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servers =
        ref.watch(serviceDbProvider).value?.servers.values.toList() ?? [];
    servers.sort((b, a) => a.priority.compareTo(b.priority));
    return ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: servers.length,
        itemBuilder: (context, index) {
          final server = servers[index];
          Widget subtitle;
          subtitle = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Text(
                    "${server.cpuCount}C.${server.memoryGB}G.${server.diskGB}G",
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.primary)),
                const SizedBox(width: 5),
                if (expiredTo(server.expired)
                    .subtract(const Duration(days: 30))
                    .isBefore(DateTime.now()))
                  Text(expiredAt(server.expired) + "到期",
                      style: const TextStyle(fontSize: 11, color: Colors.red))
              ]),
              Text(server.sshUrl,
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.secondary)),
            ],
          );
          return ListTile(
              title: Row(
                children: [
                  Text(server.name),
                ],
              ),
              subtitle: subtitle,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ServerEditorView(server))),
              onLongPress: () async {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        ServerEditorView(server.copyWith(id: ""))));
              },
              contentPadding: const EdgeInsets.only(left: 20, right: 5),
              trailing: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Container(
                      padding: const EdgeInsets.only(
                          left: 7, right: 7, bottom: 2, top: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
                      child: Text(server.band,
                          style: const TextStyle(fontSize: 12)))));
        });
  }
}

class ServerEditorView extends ConsumerStatefulWidget {
  final Server? server;
  const ServerEditorView(this.server, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ServerEditorViewState();
}

class _ServerEditorViewState extends ConsumerState<ServerEditorView> {
  final _formKey = GlobalKey<FormState>();
  late bool isAdd = widget.server?.id.isEmpty ?? true;
  late bool addFromTemplate =
      widget.server != null && widget.server!.id.isEmpty;
  late Server server = widget.server != null
      ? widget.server!.copyWith(
          id: widget.server!.id.isEmpty ? const Uuid().v4() : widget.server!.id)
      : Server(id: const Uuid().v4());

  void _addOrUpdateServer() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      ref.read(serviceDbProvider.notifier).makeMemchangeOfServer(server);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(isAdd
                ? addFromTemplate
                    ? "Add From Template"
                    : "Add"
                : "Edit"),
            actions: [
              if (!isAdd)
                IconButton(
                    onPressed: () async {
                      if (await confirm(context, "确定删除 ${server.name} ?")) {
                        Navigator.of(context).pop();
                        ref
                            .read(serviceDbProvider.notifier)
                            .deleteServer(server.id);
                      }
                    },
                    icon: const Icon(Icons.delete)),
              const SizedBox(width: 3)
            ]),
        body: Form(
            key: _formKey,
            child: ListView(
                padding: const EdgeInsets.only(left: 16, right: 16),
                children: [
                  TextFormField(
                      initialValue: server.name,
                      onSaved: (v) => server = server.copyWith(name: v ?? ""),
                      decoration: const InputDecoration(labelText: 'Name*'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      }),
                  TextFormField(
                      initialValue: server.cpuCount.toString(),
                      onSaved: (v) =>
                          server = server.copyWith(cpuCount: int.parse(v!)),
                      decoration: const InputDecoration(labelText: 'Cores*'),
                      validator: (value) {
                        if (value == null || int.tryParse(value) == null) {
                          return 'Please enter a Integer';
                        }
                        return null;
                      }),
                  TextFormField(
                      initialValue: server.memoryGB.toString(),
                      onSaved: (v) =>
                          server = server.copyWith(memoryGB: int.parse(v!)),
                      decoration: const InputDecoration(
                          labelText: 'Memory*', suffixText: "GB"),
                      validator: (value) {
                        if (value == null || int.tryParse(value) == null) {
                          return 'Please enter a Integer';
                        }
                        return null;
                      }),
                  TextFormField(
                      initialValue: server.diskGB.toString(),
                      onSaved: (v) =>
                          server = server.copyWith(diskGB: int.parse(v!)),
                      decoration: const InputDecoration(
                          labelText: 'Disk*', suffixText: "GB"),
                      validator: (value) {
                        if (value == null || int.tryParse(value) == null) {
                          return 'Please enter a Integer';
                        }
                        return null;
                      }),
                  Padding(
                      padding: const EdgeInsets.only(top: 15, bottom: 10),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Expiry Date*'),
                                  Text(expiredFormat(expiredTo(server.expired)))
                                ]),
                            IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: server.expired != 0
                                        ? expiredTo(server.expired)
                                        : DateTime.now()
                                            .add(const Duration(days: 30)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2101),
                                  );
                                  if (picked != null) {
                                    server = server.copyWith(
                                        expired: expiredFrom(picked));
                                    setState(() {});
                                  }
                                })
                          ])),
                  TextFormField(
                      initialValue: server.manageUrl,
                      onSaved: (newValue) =>
                          server = server.copyWith(manageUrl: newValue!),
                      decoration: InputDecoration(
                          labelText: 'Manage URL*',
                          suffix: IconButton(
                              onPressed: () => launchUrlString(
                                  server.manageUrl.startsWith("http")
                                      ? server.manageUrl
                                      : "https://" + server.manageUrl),
                              icon: const Icon(Icons.launch))),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a manage URL';
                        }
                        return null;
                      }),
                  TextFormField(
                      initialValue: server.sshUrl,
                      onSaved: (newValue) =>
                          server = server.copyWith(sshUrl: newValue!),
                      decoration: InputDecoration(
                          labelText: 'Endpoint URL*',
                          suffix: IconButton(
                              onPressed: () => launchUrlString(
                                  server.sshUrl.startsWith("http")
                                      ? server.sshUrl
                                      : "https://" + server.sshUrl),
                              icon: const Icon(Icons.launch))),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a valid URL';
                        }
                        return null;
                      }),
                  const SizedBox(height: 10),
                  TextFormField(
                      initialValue: server.priority.toString(),
                      validator: (v) =>
                          int.tryParse(v ?? "") == null ? "请输入数字" : null,
                      onSaved: (v) =>
                          server = server.copyWith(priority: int.parse(v!)),
                      decoration: const InputDecoration(labelText: 'Priority')),
                  const SizedBox(height: 10),
                  TextFormField(
                      initialValue: server.band,
                      onSaved: (v) => server = server.copyWith(band: v ?? ""),
                      decoration: const InputDecoration(labelText: 'Band')),
                  const SizedBox(height: 10),
                  TextFormField(
                      initialValue: server.note,
                      onSaved: (v) => server = server.copyWith(note: v ?? ""),
                      decoration: const InputDecoration(labelText: 'Note'),
                      maxLines: null),
                  const SizedBox(height: 100),
                ])),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: _addOrUpdateServer,
            label: Text(isAdd ? "添加服务器" : "更新服务器"),
            icon: Icon(isAdd ? Icons.add : Icons.save)));
  }
}
