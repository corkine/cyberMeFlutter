import 'package:cyberme_flutter/api/notes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NoteView extends ConsumerStatefulWidget {
  const NoteView({super.key});

  @override
  ConsumerState<NoteView> createState() => _NoteViewState();
}

class _NoteViewState extends ConsumerState<NoteView> {
  @override
  Widget build(BuildContext context) {
    final note = ref.watch(quickNotesProvider).value;
    if (note == null) return const Center(child: CupertinoActivityIndicator());
    Widget content;
    final addFromClipboardButton = CupertinoButton(
        onPressed: () async {
          final content = await Clipboard.getData("text/plain");
          if (content == null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text("剪贴板无内容")));
            return;
          }
          //显示对话框确认内容，如果是，则调用 API
          final res = await showDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                    title: const Text("确认新建？"),
                    content: Text(content.text ?? ""),
                    actions: [
                      CupertinoDialogAction(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("取消")),
                      CupertinoDialogAction(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text("确认")),
                    ],
                  ));
          if (res != true) return;
          final message = await ref
              .read(quickNotesProvider.notifier)
              .setNote(content.text ?? "");
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        },
        child: const Text("从剪贴板新建"));
    if (note.$2.isNotEmpty) {
      content = Center(
          child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(note.$2),
                    const SizedBox(height: 10),
                    ButtonBar(alignment: MainAxisAlignment.center, children: [
                      CupertinoButton(
                          onPressed: () async {
                            await ref.refresh(quickNotesProvider.future);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("已刷新")));
                          },
                          child: const Text("刷新")),
                      addFromClipboardButton
                    ])
                  ])));
    } else {
      content = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text("最近一次笔记："),
                Text(note.$1?.Content ?? "无内容"),
                const SizedBox(height: 10),
                Text("更新于：${note.$1?.LastUpdate ?? "无更新时间"}"),
                Text("来自于：${note.$1?.From ?? "无来源"}"),
                Text("有效期：${note.$1?.LiveSeconds ?? "无有效期"} 秒"),
                const SizedBox(height: 10),
                ButtonBar(alignment: MainAxisAlignment.center, children: [
                  CupertinoButton(
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: note.$1?.Content ?? ""));
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("已复制到剪贴板")));
                      },
                      child: const Text("拷贝")),
                  CupertinoButton(
                      onPressed: () async {
                        await ref.refresh(quickNotesProvider.future);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text("已刷新")));
                      },
                      child: const Text("刷新")),
                  addFromClipboardButton
                ])
              ]));
    }
    return Scaffold(appBar: AppBar(title: const Text("笔记")), body: content);
  }
}
