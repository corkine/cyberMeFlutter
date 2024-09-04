import 'dart:convert';

import 'package:cyberme_flutter/main.dart';
import 'package:cyberme_flutter/pocket/viewmodels/dispatch.dart';
import 'package:cyberme_flutter/pocket/views/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DispatchView extends ConsumerStatefulWidget {
  const DispatchView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DispatchViewState();
}

class _DispatchViewState extends ConsumerState<DispatchView> {
  addOrEditDispatch(DispatchItem? item) async {
    final title = TextEditingController(text: item?.name);
    final url = TextEditingController(text: item?.url);
    final desc = TextEditingController(text: item?.description);
    showDialog(
        context: context,
        builder: (context) {
          return Theme(
            data: appThemeData,
            child: AlertDialog(
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(hintText: "名称"),
                  ),
                  TextField(
                      controller: url,
                      decoration: const InputDecoration(hintText: "地址"),
                      maxLines: 3),
                  TextField(
                      controller: desc,
                      decoration: const InputDecoration(hintText: "描述"),
                      maxLines: 5)
                ]),
                actions: [
                  TextButton(
                      child: Text(item == null ? "添加" : "确定"),
                      onPressed: () async {
                        if (title.text == "" || url.text == "") {
                          showSimpleMessage(context, content: "请输入名称和地址");
                          return;
                        }
                        final res = await ref
                            .read(dispatchDbProvider.notifier)
                            .addOrUpdate((item ?? DispatchItem()).copyWith(
                                name: title.text,
                                url: url.text,
                                description: desc.text));
                        Navigator.of(context).pop();
                        showSimpleMessage(context,
                            content: res, useSnackBar: true);
                      })
                ]),
          );
        });
  }

  encodeDecode() async {
    final data = TextEditingController();
    final dataInDb = await Clipboard.getData("text/plain");
    if (dataInDb?.text != null) {
      data.text = dataInDb!.text!;
    }
    showDialog(
        context: context,
        builder: (context) {
          return Theme(
            data: appThemeData,
            child: AlertDialog(
                title: const Text("编码和解码"),
                content: TextField(
                    controller: data,
                    maxLines: 10,
                    decoration: const InputDecoration(hintText: "输入")),
                actions: [
                  TextButton(
                      child: const Text("编码"),
                      onPressed: () {
                        showSimpleMessage(context,
                            showCopy: true,
                            content: SimpleEncryptor.encrypt(data.text));
                      }),
                  TextButton(
                      child: const Text("解码"),
                      onPressed: () {
                        showSimpleMessage(context,
                            showCopy: true,
                            content: SimpleEncryptor.decrypt(data.text)!);
                      })
                ]),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(dispatchDbProvider).value ?? [];
    return Theme(
      data: appThemeData,
      child: Scaffold(
          appBar: AppBar(title: const Text('Dispatch'), actions: [
            IconButton(
                onPressed: () => addOrEditDispatch(null),
                icon: const Icon(Icons.add)),
            IconButton(icon: const Icon(Icons.key), onPressed: encodeDecode),
            const SizedBox(width: 10)
          ]),
          body: ListView.builder(
              itemBuilder: (context, index) {
                final item = data[index];
                return ListTile(
                    onTap: () => addOrEditDispatch(item),
                    onLongPress: () => showSimpleMessage(context,
                        title: "编码 Key",
                        showCopy: true,
                        content: SimpleEncryptor.encrypt(item.url)),
                    dense: true,
                    title: Text(item.name,
                        style: Theme.of(context).textTheme.bodyLarge),
                    subtitle: Text(item.url));
              },
              itemCount: data.length)),
    );
  }
}

class SimpleEncryptor {
  static const String _key =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  static const String _substitution =
      'NOPQRSTUVWXYZABCDEFGHIJKLMnopqrstuvwxyzabcdefghijklm9876543210-_';

  static String encrypt(String input) {
    String base64 = base64Encode(utf8.encode(input));

    return base64.split('').map((char) {
      int index = _key.indexOf(char);
      return index != -1 ? _substitution[index] : char;
    }).join('');
  }

  static String? decrypt(String? input) {
    if (input == null) return null;
    String base64 = input.split('').map((char) {
      int index = _substitution.indexOf(char);
      return index != -1 ? _key[index] : char;
    }).join('');

    return utf8.decode(base64Decode(base64));
  }
}
