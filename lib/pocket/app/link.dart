import 'package:clipboard/clipboard.dart';
import 'package:cyberme_flutter/api/link.dart';
import 'package:cyberme_flutter/pocket/app/util.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

class QuickLinkView extends ConsumerStatefulWidget {
  const QuickLinkView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _QuickLinkViewState();
}

class _QuickLinkViewState extends ConsumerState<QuickLinkView> {
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void distroSearcher() {
    search.text = "dist-";
    ref.invalidate(linksProvider);
  }

  void distroHandler(bool manual) async {
    final url = await FlutterClipboard.paste();
    try {
      if ((url.startsWith("https://mazhangjing.com") ||
              url.startsWith("mazhangjing.com")) &&
          url.endsWith("current/release.json")) {
        final controller = ref.read(linksProvider.call(search.text).notifier);
        final date = await showDatePicker(
            context: context,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 30)));
        final time = await showTimePicker(
            context: context, initialTime: TimeOfDay.now());
        if (date == null || time == null) {
          await showSimpleMessage(context, content: "请选择一个日期");
          return;
        }
        final (msg, link) = await controller.addDistroUrl(url,
            DateTime(date.year, date.month, date.day, time.hour, time.minute));
        if (link.isNotEmpty) {
          await FlutterClipboard.copy(link);
          await showSimpleMessage(context,
              content: "已复制到剪贴板", useSnackBar: true);
        } else {
          await showSimpleMessage(context, content: msg);
        }
      } else {
        if (manual) {
          await showSimpleMessage(context, content: "剪贴板没有检测到正确的分发地址");
        }
      }
    } catch (e) {
      await showSimpleMessage(context, content: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(linksProvider.call(search.text)).value;
    return Scaffold(
        appBar: AppBar(title: const Text("短链接管理"), actions: [
          Padding(
            padding: const EdgeInsets.only(),
            child: IconButton(
                onPressed: () => distroSearcher(),
                icon: const Icon(Icons.search)),
          ),
          Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                  onPressed: () => distroHandler(true),
                  icon: const Icon(Icons.schedule_send)))
        ]),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: TextField(
                  controller: search,
                  autofocus: true,
                  decoration: InputDecoration(
                      hintText: "搜索",
                      suffixIcon: IconButton(
                          onPressed: handleAdd,
                          icon: const Icon(Icons.add, size: 25))),
                  onChanged: (_) => ref.invalidate(linksProvider))),
          const SizedBox(height: 10),
          data == null
              ? const Padding(
                  padding: EdgeInsets.only(top: 50),
                  child: CircularProgressIndicator())
              : data.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: Text(search.text.isEmpty ? "" : "没有结果"))
                  : Expanded(
                      child: ListView.builder(
                          itemBuilder: (context, index) {
                            final d = data[index];
                            return Dismissible(
                              key: ValueKey(d.id),
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.endToStart) {
                                  final res = await ref
                                      .read(linksProvider
                                          .call(search.text)
                                          .notifier)
                                      .delete(d.id);
                                  await showSimpleMessage(context,
                                      content: res, useSnackBar: true);
                                } else {
                                  await FlutterClipboard.copy(d.redirectUrl);
                                  await showSimpleMessage(context,
                                      content: "已拷贝链接至剪贴板", useSnackBar: true);
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
                                                  color: Colors.white,
                                                  fontSize: 15))))),
                              background: Container(
                                  color: Colors.blue,
                                  child: const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                          padding: EdgeInsets.only(left: 20),
                                          child: Text("拷贝到剪贴板",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15))))),
                              child: ListTile(
                                  onTap: () {
                                    if (d.redirectUrl == ":note") {
                                      showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                                  title: const Text("内容"),
                                                  content:
                                                      SingleChildScrollView(
                                                          child: Text(d.note)),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(),
                                                        child: const Text("确定"))
                                                  ]));
                                    } else {
                                      launchUrlString(d.redirectUrl);
                                    }
                                  },
                                  visualDensity: VisualDensity.compact,
                                  dense: true,
                                  title: Text(d.keyword),
                                  subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(d.redirectUrl,
                                            softWrap: false,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey)),
                                        Text(d.note,
                                            softWrap: true,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey))
                                      ])),
                            );
                          },
                          itemCount: data.length))
        ]));
  }

  handleAdd() async {
    final url = TextEditingController();
    final note = TextEditingController();
    var noteMaxLine = 1;
    var override = true;
    final data = await FlutterClipboard.paste();
    if (data.isNotEmpty) {
      url.text = data;
    }
    final searchMatch =
        ref.read(linksProvider.call(search.text)).value?.firstOrNull;
    if (searchMatch != null && searchMatch.keyword == search.text) {
      note.text = searchMatch.note;
      if (searchMatch.redirectUrl == ":note") noteMaxLine = 10;
    } else {
      note.text = "由 CyberMe Flutter 添加：${DateTime.now()}";
    }
    await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                      title: const Text("添加到短链接"),
                      content: SingleChildScrollView(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                            Text("https://go.mazhangjing.com/${search.text}"),
                            TextField(
                                controller: url,
                                autofocus: url.text.isEmpty ? true : false,
                                decoration:
                                    const InputDecoration(hintText: "跳转到")),
                            const SizedBox(height: 10),
                            TextField(
                                controller: note,
                                maxLines: noteMaxLine,
                                decoration:
                                    const InputDecoration(hintText: "备注")),
                            const SizedBox(height: 10),
                            Row(children: [
                              const Text("允许覆盖"),
                              const Spacer(),
                              Switch(
                                  value: override,
                                  onChanged: (v) =>
                                      setState(() => override = v))
                            ])
                          ])),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("取消")),
                        TextButton(
                            onPressed: () async {
                              if (url.text.isEmpty || search.text.isEmpty) {
                                await showSimpleMessage(context,
                                    content: "请输入内容");
                                return;
                              }
                              final res = await ref
                                  .read(
                                      linksProvider.call(search.text).notifier)
                                  .add(search.text, url.text,
                                      override: override, note: note.text);
                              Navigator.of(context).pop(true);
                              await showSimpleMessage(context, content: res);
                            },
                            child: const Text("添加"))
                      ]));
        });
  }
}
