import 'dart:ffi';

import 'package:cyberme_flutter/api/gpt.dart';
import 'package:cyberme_flutter/main.dart';
import 'package:cyberme_flutter/pocket/app/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GPTView extends ConsumerStatefulWidget {
  const GPTView({super.key});

  @override
  ConsumerState<GPTView> createState() => _GPTViewState();
}

class _GPTViewState extends ConsumerState<GPTView> {
  final input = TextEditingController();
  @override
  void dispose() {
    input.dispose();
    fn.dispose();
    super.dispose();
  }

  String lastQuestion = "";
  String lastResp = "";
  final fn = FocusNode();

  @override
  Widget build(BuildContext context) {
    final setting = ref.watch(gPTSettingsProvider).value ?? const GPTSetting();
    return Theme(
        data: appThemeData,
        child: Scaffold(
            appBar: AppBar(title: const Text("Gemini Lite"), actions: [
              IconButton(
                  onPressed: handleAddLastQuestion, icon: const Icon(Icons.add))
            ]),
            body: Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      lastQuestion.isEmpty
                          ? const SizedBox()
                          : Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(children: [
                                const Icon(Icons.account_circle),
                                const SizedBox(width: 5),
                                GestureDetector(
                                    onTap: () {
                                      input.text = lastQuestion;
                                      FocusScope.of(context).requestFocus(fn);
                                    },
                                    child: Text(lastQuestion))
                              ])),
                      Expanded(
                          child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 44, 44, 44),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    const Padding(
                                        padding: EdgeInsets.only(
                                            left: 10, bottom: 5, top: 5),
                                        child: Row(children: [
                                          Icon(Icons.android),
                                          SizedBox(width: 10),
                                          Text("Gemini")
                                        ])),
                                    Expanded(
                                        child: GestureDetector(
                                            onTap: () {
                                              Clipboard.setData(ClipboardData(
                                                  text: lastResp));
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                                      content: Text("已复制到剪贴板"),
                                                      duration: Duration(
                                                          milliseconds: 400)));
                                            },
                                            onDoubleTap: () => setState(
                                                () => lastResp = "已清空"),
                                            child: SingleChildScrollView(
                                                child: Container(
                                                    width: double.infinity,
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(lastResp)))))
                                  ]))),
                      TextField(
                          focusNode: fn,
                          controller: input,
                          decoration: InputDecoration(
                              border: const UnderlineInputBorder(),
                              labelText: "输入问题",
                              suffix: IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: handleQuestion,
                                  icon: const Icon(Icons.send, size: 15))),
                          onSubmitted: (v) async => handleQuestion()),
                      setting.quickQuestion.isEmpty
                          ? const SizedBox()
                          : SafeArea(
                              child: Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Wrap(
                                      runSpacing: 5,
                                      spacing: 5,
                                      children: setting.quickQuestion.entries
                                          .map((e) {
                                        return RawChip(
                                          label: Text(e.key),
                                          selected: input.text == e.value,
                                          onPressed: () {
                                            input.text = e.value;
                                            FocusScope.of(context)
                                                .requestFocus(fn);
                                          },
                                          onDeleted: () =>
                                              handleDeleteQuickQuestion(e.key),
                                        );
                                      }).toList(growable: false))))
                    ]))));
  }

  handleQuestion() async {
    final v = input.text;
    if (v.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    lastResp = "等待中...";
    lastQuestion = v;
    setState(() {});
    final (_, resp) = await ref.read(gPTSettingsProvider.notifier).request(v);
    lastResp = resp;
    input.text = "";
    setState(() {});
  }

  void handleDeleteQuickQuestion(String item) async {
    if (await showSimpleMessage(context, content: "是否删除 $item？")) {
      await ref.read(gPTSettingsProvider.notifier).delete(item);
    }
  }

  void handleAddLastQuestion() async {
    final title = TextEditingController();
    final resp = await showDialog(
            context: context,
            builder: (context) => Theme(
                data: appThemeData,
                child: AlertDialog(
                    title: const Text("添加到收藏夹"),
                    content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("添加 ${input.text} 到收藏夹"),
                          TextField(
                              autofocus: true,
                              controller: title,
                              decoration:
                                  const InputDecoration(labelText: "输入名称"))
                        ]),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text("取消")),
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text("确定"))
                    ]))) ??
        false;
    if (resp && title.text.isNotEmpty) {
      await ref.read(gPTSettingsProvider.notifier).add(title.text, input.text);
      await showSimpleMessage(context, content: "添加成功");
    }
  }
}
