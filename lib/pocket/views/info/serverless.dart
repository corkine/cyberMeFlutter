import 'package:cyberme_flutter/pocket/viewmodels/serverless.dart';
import 'package:cyberme_flutter/pocket/views/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ServerlessServiceView extends ConsumerStatefulWidget {
  const ServerlessServiceView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ServerlessServiceViewState();
}

class _ServerlessServiceViewState extends ConsumerState<ServerlessServiceView> {
  @override
  Widget build(BuildContext context) {
    final items = ref.watch(serverlessDbProvider).value ?? [];
    return Scaffold(
        appBar: AppBar(title: const Text('Serverless Function'), actions: [
          IconButton(onPressed: handleAdd, icon: const Icon(Icons.add)),
          const SizedBox(width: 5)
        ]),
        body: ListView.builder(
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                  dense: true,
                  title: Text(item.name),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                            ServerlessServiceItemView(item.name)));
                  },
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(
                        text:
                            "https://cyber.mazhangjing.com/cyber/service/func/${item.name}"));
                    showSimpleMessage(context,
                        content: "Copied URL to clipboard", useSnackBar: true);
                  },
                  trailing: IconButton(
                      onPressed: () => handleDelete(item.name),
                      icon: Icon(Icons.delete)));
            },
            itemCount: items.length));
  }

  void handleAdd() async {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => ServerlessServiceItemView('')));
  }

  void handleDelete(String name) async {
    final res = await ref.read(serverlessDbProvider.notifier).delete(name);
    showSimpleMessage(context, content: res, useSnackBar: true);
    ref.invalidate(serverlessDbProvider);
  }
}

class ServerlessServiceItemView extends ConsumerStatefulWidget {
  final String name;
  const ServerlessServiceItemView(this.name, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ServerlessServiceItemViewState();
}

class _ServerlessServiceItemViewState
    extends ConsumerState<ServerlessServiceItemView> {
  late String name = widget.name;
  late bool isNew = name.isEmpty;
  bool loading = true;
  late ServiceItem item;
  GlobalKey<FormState> _formKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (name.isNotEmpty) {
      isNew = false;
      ref.read(serverlessDbProvider.notifier).getByName(name).then((v) {
        loading = false;
        this.item = v!;
        setState(() {});
      });
    } else {
      setState(() {
        loading = false;
        item = ServiceItem(name: name);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar:
            AppBar(title: Text(name.isEmpty ? "New Script" : name), actions: [
          IconButton(onPressed: handleCopy, icon: const Icon(Icons.copy)),
          IconButton(onPressed: handleSave, icon: const Icon(Icons.save)),
          const SizedBox(width: 5)
        ]),
        body: buildForm());
  }

  Widget buildForm() {
    if (loading)
      return const Padding(padding: EdgeInsets.only(top: 20), child: null);
    return Form(
        key: _formKey,
        child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isNew)
                    TextFormField(
                        readOnly: !isNew,
                        initialValue: item.name,
                        onChanged: (v) => item = item.copyWith(name: v),
                        validator: (v) => v!.isEmpty ? "名称不能为空" : null,
                        decoration: const InputDecoration(
                            labelText: '名称', helperText: "名称需要保持唯一")),
                  TextFormField(
                      initialValue: item.description,
                      onChanged: (v) => item = item.copyWith(description: v),
                      decoration: const InputDecoration(labelText: '描述')),
                  Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text("脚本")),
                  Expanded(
                    child: TextFormField(
                        style: TextStyle(fontFamily: "consolas", fontSize: 12),
                        maxLines: null,
                        expands: true,
                        keyboardType: TextInputType.multiline,
                        initialValue: item.content,
                        onChanged: (v) => item = item.copyWith(content: v),
                        decoration: const InputDecoration()),
                  ),
                ])));
  }

  void handleSave() async {
    if (_formKey.currentState!.validate()) {
      final res =
          await ref.read(serverlessDbProvider.notifier).addOrUpdate(item);
      showSimpleMessage(context, content: res, useSnackBar: true);
      Navigator.of(context).pop();
      ref.invalidate(serverlessDbProvider);
    } else {
      showSimpleMessage(context, content: '表单验证失败', useSnackBar: true);
    }
  }

  void handleCopy() async {
    await Clipboard.setData(ClipboardData(text: item.content));
    showSimpleMessage(context, content: '已复制到剪贴板', useSnackBar: true);
  }
}
