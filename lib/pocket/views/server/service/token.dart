import 'package:cyberme_flutter/pocket/views/server/service/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../viewmodels/service.dart';

class TokenEmbededView extends ConsumerWidget {
  const TokenEmbededView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens =
        ref.watch(serviceDbProvider).value?.tokens.values.toList() ?? [];
    tokens.sort((a, b) => a.name.compareTo(b.name));
    return ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: tokens.length,
        itemBuilder: (context, index) {
          final token = tokens[index];
          Widget subtitle;
          if (expiredTo(token.expired)
              .subtract(const Duration(days: 30))
              .isBefore(DateTime.now())) {
            subtitle = Text(expiredAt(token.expired) + " 到期",
                style: const TextStyle(fontSize: 12, color: Colors.red));
          } else {
            subtitle = Text(token.note, style: const TextStyle(fontSize: 12));
          }
          return ListTile(
              title: Text(token.name),
              subtitle: subtitle,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => TokenEditorView(token))),
              contentPadding: const EdgeInsets.only(left: 20, right: 5));
        });
  }
}

class TokenEditorView extends ConsumerStatefulWidget {
  final OAuthToken? token;
  const TokenEditorView(this.token, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _TokenEditorViewState();
}

class _TokenEditorViewState extends ConsumerState<TokenEditorView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _clientIdController;
  late TextEditingController _secretController;
  late DateTime _expired;
  late TextEditingController _noteController;
  late TextEditingController _manageUrlController;
  late TextEditingController _implController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.token?.name);
    _clientIdController = TextEditingController(text: widget.token?.clientId);
    _secretController = TextEditingController(text: widget.token?.secret);
    if (widget.token?.expired != null) {
      _expired = expiredTo(widget.token!.expired);
    } else {
      _expired = DateTime.now().add(const Duration(days: 30));
    }
    _manageUrlController = TextEditingController(text: widget.token?.manageUrl);
    _noteController = TextEditingController(text: widget.token?.note);
    _implController = TextEditingController(text: widget.token?.implDetails);
  }

  @override
  void dispose() {
    _clearForm();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _clientIdController.clear();
    _secretController.clear();
    _manageUrlController.clear();
    _noteController.clear();
    _implController.clear();
  }

  void _addOrUpdateToken([bool updateTime = true]) {
    if (_formKey.currentState!.validate()) {
      final newToken = (widget.token ?? OAuthToken(id: const Uuid().v4()))
          .copyWith(
              name: _nameController.text,
              clientId: _clientIdController.text,
              secret: _secretController.text,
              expired: _expired.millisecondsSinceEpoch ~/ 1000,
              manageUrl: _manageUrlController.text,
              note: _noteController.text,
              implDetails: _implController.text,
              update: DateTime.now().millisecondsSinceEpoch ~/ 1000);
      ref.read(serviceDbProvider.notifier).makeMemchangeOfToken(newToken);
      _clearForm();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdd = widget.token == null;
    return Scaffold(
        appBar: AppBar(title: Text(isAdd ? "Add" : "Edit"), actions: [
          IconButton(
              onPressed: () async {
                var token = widget.token!;
                if (await confirm(context, "确定删除 ${token.name} ?")) {
                  ref.read(serviceDbProvider.notifier).deleteToken(token.id);
                }
              },
              icon: const Icon(Icons.delete)),
          const SizedBox(width: 10)
        ]),
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
                      controller: _noteController,
                      decoration: const InputDecoration(labelText: 'Note')),
                  TextFormField(
                      controller: _clientIdController,
                      decoration: InputDecoration(
                          labelText: 'Client ID',
                          suffix: IconButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                    text: _clientIdController.text));
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Client ID copied')));
                              },
                              icon: const Icon(Icons.copy)))),
                  TextFormField(
                      controller: _secretController,
                      decoration: InputDecoration(
                          labelText: 'Secret',
                          suffix: IconButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                    text: _secretController.text));
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Client Secret copied')));
                              },
                              icon: const Icon(Icons.copy)))),
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
                      controller: _implController,
                      decoration:
                          const InputDecoration(labelText: 'Impl Details'),
                      maxLines: null)
                ])),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: _addOrUpdateToken,
            isExtended: true,
            label: Text(isAdd ? "添加密钥" : "更新密钥"),
            icon: Icon(isAdd ? Icons.add : Icons.save)));
  }
}
