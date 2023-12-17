import 'package:cyberme_flutter/api/tv.dart';
import 'package:cyberme_flutter/pocket/app/statistics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../main.dart';

class TvView extends ConsumerStatefulWidget {
  const TvView({super.key});

  @override
  ConsumerState<TvView> createState() => _TvViewState();
}

class _TvViewState extends ConsumerState<TvView> {
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(seriesDBProvider).value;
    Widget content;
    if (data == null) {
      content = const Center(child: CupertinoActivityIndicator());
    } else {
      final now = DateTime.now();
      content = RefreshIndicator(
          onRefresh: () async => await ref.refresh(seriesDBProvider),
          child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                return TvItem(item, now);
              }));
    }
    return Theme(
        data: appThemeData,
        child: Scaffold(
            appBar: AppBar(title: const Text('TV Series'), actions: [
              IconButton(onPressed: handleAdd, icon: const Icon(Icons.add))
            ]),
            body: content));
  }

  handleAdd() async {
    final nameC = TextEditingController();
    final urlC = TextEditingController();
    var nameErr = "";
    var urlErr = "";
    final widget = Theme(
      data: themeData,
      child: StatefulBuilder(
          builder: (context, setState) => AlertDialog(
                  title: const Text("添加追踪"),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(
                        controller: nameC,
                        decoration: InputDecoration(
                            errorText: nameErr.isEmpty ? null : nameErr,
                            labelText: "名称",
                            hintText: "请输入名称",
                            border: const UnderlineInputBorder())),
                    TextField(
                        controller: urlC,
                        decoration: InputDecoration(
                            errorText: urlErr.isEmpty ? null : urlErr,
                            suffix:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(
                                  onPressed: () async {
                                    final data =
                                        await Clipboard.getData("text/plain");
                                    urlC.text = data!.text ?? "";
                                  },
                                  icon: const Icon(Icons.paste, size: 16)),
                              IconButton(
                                  onPressed: () async {
                                    final name = urlC.text.isEmpty
                                        ? null
                                        : await ref
                                            .read(seriesDBProvider.notifier)
                                            .findName(urlC.text);
                                    if (name == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text("无法从 URL 解析名称")));
                                    } else {
                                      nameC.text = name;
                                      setState(() {});
                                    }
                                  },
                                  icon:
                                      const Icon(Icons.find_in_page, size: 16))
                            ]),
                            labelText: "URL",
                            hintText: "请输入URL",
                            border: const UnderlineInputBorder()))
                  ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("取消")),
                    TextButton(
                        onPressed: () async {
                          nameErr = "";
                          urlErr = "";
                          if (nameC.text.isEmpty) {
                            nameErr = "名称不允许为空";
                          }
                          if (urlC.text.isEmpty) {
                            urlErr = "URL 不允许为空";
                          } else if (RegExp(r"^https?://")
                                  .hasMatch(urlC.text) ==
                              false) {
                            urlErr = "URL 不合法";
                          }
                          if (nameErr.isNotEmpty || urlErr.isNotEmpty) {
                            setState(() {});
                            return;
                          }
                          final res = await ref
                              .read(seriesDBProvider.notifier)
                              .add(nameC.text, urlC.text);
                          showCupertinoDialog(
                              context: context,
                              builder: (ctx) => CupertinoAlertDialog(
                                      title: const Text("结果"),
                                      content: Text(res),
                                      actions: [
                                        CupertinoDialogAction(
                                            onPressed: () {
                                              ref.invalidate(seriesDBProvider);
                                              Navigator.of(context).pop();
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text("确定"))
                                      ]));
                        },
                        child: const Text("确定"))
                  ])),
    );
    showDialog(context: context, builder: (ctx) => widget);
  }
}

class TvItem extends ConsumerStatefulWidget {
  final Series item;
  final DateTime now;
  const TvItem(this.item, this.now, {super.key});

  @override
  ConsumerState<TvItem> createState() => _TvItemState();
}

class _TvItemState extends ConsumerState<TvItem> {
  late Series item;
  late List<String> series;
  late bool recentUpdate;
  late String lastUpdate;
  late bool lastWatched;
  late String updateAt;

  @override
  void initState() {
    super.initState();
    item = widget.item;
    series = [...item.info.series];
    series.sort();
    recentUpdate = widget.now.difference(item.updateAt).inDays < 3;
    lastUpdate = series.lastOrNull ?? "无更新信息";
    lastWatched = item.info.watched.contains(lastUpdate);
    updateAt = DateFormat("yyyy-MM-dd HH:mm").format(item.updateAt);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
        onTap: () => handleTapItem(item, lastUpdate),
        title: Row(children: [
          Container(
              padding: const EdgeInsets.only(left: 8, right: 8),
              decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 60, 61, 60),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(item.id.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12))),
          const SizedBox(width: 5),
          Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold))
        ]),
        subtitle:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 4),
          RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                  text: lastUpdate,
                  style: recentUpdate
                      ? const TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          color: Colors.green)
                      : TextStyle(
                          color: Theme.of(context).colorScheme.onBackground),
                  children: [
                    if (lastWatched)
                      TextSpan(
                          text: " (已看)",
                          style: TextStyle(
                              color: recentUpdate
                                  ? Colors.green
                                  : Theme.of(context)
                                      .colorScheme
                                      .onBackground)),
                    TextSpan(
                        text: " @$updateAt",
                        style: const TextStyle(
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.normal,
                            color: Colors.grey,
                            fontSize: 12)),
                  ]))
        ]));
  }

  handleTapItem(Series item, String lastUpdate) {
    handleDelete() async {
      Navigator.of(context).pop();
      final msg = await ref.read(seriesDBProvider.notifier).delete(item.id);
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: const Text("结果"),
                  content: Text(msg),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ref.invalidate(seriesDBProvider);
                        },
                        child: const Text("确定"))
                  ]));
    }

    handleUpdate() async {
      Navigator.of(context).pop();
      final msg = await ref
          .read(seriesDBProvider.notifier)
          .updateWatched(item.name, lastUpdate);
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: const Text("结果"),
                  content: Text(msg),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ref.invalidate(seriesDBProvider);
                        },
                        child: const Text("确定"))
                  ]));
    }

    handleUpdateAll() async {
      Navigator.of(context).pop();
      final msg = await ref
          .read(seriesDBProvider.notifier)
          .updateAllWatched(item.name, item.info.series);
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: const Text("结果"),
                  content: Text(msg),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ref.invalidate(seriesDBProvider);
                        },
                        child: const Text("确定"))
                  ]));
    }

    showDialog(
        context: context,
        builder: (ctx) => SimpleDialog(title: Text(item.name), children: [
              SimpleDialogOption(
                  onPressed: () => launchUrlString(item.url),
                  child: const Text("查看详情...")),
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(item.toString()),
                        duration: const Duration(seconds: 120)));
                  },
                  child: const Text("调试信息")),
              SimpleDialogOption(
                  onPressed: handleUpdateAll, child: const Text("标记所有已看")),
              SimpleDialogOption(
                  onPressed: handleUpdate, child: const Text("标记当前已看")),
              SimpleDialogOption(
                  onPressed: handleDelete, child: const Text("删除"))
            ]));
  }
}
