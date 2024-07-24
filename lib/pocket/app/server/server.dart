import 'package:cyberme_flutter/pocket/app/server/common.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:uuid/uuid.dart';

import '../../../api/service.dart';

class ServerEmbededView extends ConsumerWidget {
  const ServerEmbededView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servers =
        ref.watch(serviceDbProvider).value?.servers.values.toList() ?? [];
    return ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: servers.length,
        itemBuilder: (context, index) {
          final server = servers[index];
          Widget subtitle;
          if (expiredTo(server.expired)
              .subtract(const Duration(days: 30))
              .isBefore(DateTime.now())) {
            subtitle = Text(expiredAt(server.expired) + " 到期",
                style: const TextStyle(fontSize: 12, color: Colors.red));
          } else {
            subtitle = Text(server.band, style: const TextStyle(fontSize: 12));
          }
          return ListTile(
              title: Text(server.name),
              subtitle: subtitle,
              onTap: () => launchUrlString("https://" + server.manageUrl),
              contentPadding: const EdgeInsets.only(left: 20, right: 5),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => ServerEditorView(server)))),
                IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => ref
                        .read(serviceDbProvider.notifier)
                        .deleteServer(server.id))
              ]));
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
  late TextEditingController _nameController;
  late TextEditingController _cpuCountController;
  late TextEditingController _memoryController;
  late TextEditingController _diskController;
  late TextEditingController _bandController;
  late DateTime _expired;
  late TextEditingController _noteController;
  late TextEditingController _manageUrlController;
  late TextEditingController _sshUrlController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.server?.name);
    _cpuCountController =
        TextEditingController(text: widget.server?.cpuCount.toString());
    _memoryController =
        TextEditingController(text: widget.server?.memoryGB.toString());
    _diskController =
        TextEditingController(text: widget.server?.diskGB.toString());
    _bandController =
        TextEditingController(text: widget.server?.band.toString());
    if (widget.server?.expired != null) {
      _expired = expiredTo(widget.server!.expired);
    } else {
      _expired = DateTime.now().add(const Duration(days: 30));
    }
    _noteController = TextEditingController(text: widget.server?.note);
    _manageUrlController =
        TextEditingController(text: widget.server?.manageUrl);
    _sshUrlController = TextEditingController(text: widget.server?.sshUrl);
  }

  @override
  void dispose() {
    _clearForm();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _cpuCountController.clear();
    _memoryController.clear();
    _diskController.clear();
    _bandController.clear();
    _manageUrlController.clear();
    _sshUrlController.clear();
    _noteController.clear();
  }

  void _addOrUpdateServer() {
    if (_formKey.currentState!.validate()) {
      final newServer = (widget.server ?? Server(id: const Uuid().v4()))
          .copyWith(
              name: _nameController.text,
              cpuCount: int.parse(_cpuCountController.text),
              memoryGB: int.parse(_memoryController.text),
              diskGB: int.parse(_diskController.text),
              expired: _expired.millisecondsSinceEpoch ~/ 1000,
              manageUrl: _manageUrlController.text,
              band: _bandController.text,
              note: _noteController.text,
              sshUrl: _sshUrlController.text);
      ref.read(serviceDbProvider.notifier).makeMemchangeOfServer(newServer);
      _clearForm();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdd = widget.server == null;
    return Scaffold(
        appBar: AppBar(title: Text(isAdd ? "Add" : "Edit")),
        body: Form(
            key: _formKey,
            child: ListView(
                padding: const EdgeInsets.only(left: 16, right: 16),
                children: [
                  TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name*'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      }),
                  TextFormField(
                      controller: _cpuCountController,
                      decoration: const InputDecoration(labelText: 'Cores*'),
                      validator: (value) {
                        if (value == null || int.tryParse(value) == null) {
                          return 'Please enter a Integer';
                        }
                        return null;
                      }),
                  TextFormField(
                      controller: _memoryController,
                      decoration: const InputDecoration(
                          labelText: 'Memory*', suffixText: "GB"),
                      validator: (value) {
                        if (value == null || int.tryParse(value) == null) {
                          return 'Please enter a Integer';
                        }
                        return null;
                      }),
                  TextFormField(
                      controller: _diskController,
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
                                  Text(expiredFormat(_expired))
                                ]),
                            IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: _expired,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2101),
                                  );
                                  if (picked != null && picked != _expired) {
                                    setState(() {
                                      _expired = picked;
                                    });
                                  }
                                })
                          ])),
                  TextFormField(
                      controller: _manageUrlController,
                      decoration: const InputDecoration(
                          labelText: 'Manage URL*', prefixText: "https://"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a manage URL';
                        }
                        return null;
                      }),
                  TextFormField(
                      controller: _sshUrlController,
                      decoration: const InputDecoration(
                          labelText: 'Endpoint URL*', prefixText: "https://"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a valid URL';
                        }
                        return null;
                      }),
                  TextFormField(
                      controller: _bandController,
                      decoration: const InputDecoration(labelText: 'Band')),
                  TextFormField(
                      controller: _noteController,
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
