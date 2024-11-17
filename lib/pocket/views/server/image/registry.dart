import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../viewmodels/image.dart';
import '../../util.dart';

class RegistryView extends ConsumerStatefulWidget {
  const RegistryView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RegistryViewState();
}

class _RegistryViewState extends ConsumerState<RegistryView> {
  final bg1 = Container(
      color: Colors.red,
      child: const Align(
          alignment: Alignment.centerRight,
          child: Padding(
              padding: EdgeInsets.only(right: 20),
              child: Text("删除",
                  style: TextStyle(color: Colors.white, fontSize: 15)))));
  final bg2 = Container(
      color: Colors.blue,
      child: const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
              padding: EdgeInsets.only(left: 20),
              child: Text("编辑",
                  style: TextStyle(color: Colors.white, fontSize: 15)))));
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(getRegistryProvider).value ?? [];
    final now = DateTime.now();
    return ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];
          final expired = item.expiredAt > 0
              ? DateTime.fromMillisecondsSinceEpoch(item.expiredAt)
                  .difference(now)
                  .inDays
              : 0;
          return Dismissible(
              key: ValueKey(item.id),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.endToStart) {
                  if (await showSimpleMessage(context, content: "确定删除此仓库吗?")) {
                    final res = await ref
                        .read(imageDbProvider.notifier)
                        .deleteRegistry(item.id);
                    await showSimpleMessage(context,
                        content: res, useSnackBar: true);
                    return true;
                  }
                } else {
                  await handleEdit(item, false);
                  return false;
                }
                return false;
              },
              secondaryBackground: bg1,
              background: bg2,
              child: ListTile(
                  title: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            padding: const EdgeInsets.only(left: 4, right: 4),
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.2)),
                            child: Text(item.id.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 12, fontFamily: "Consolas"))),
                        Text(item.note,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        if (expired != 0 && expired < 30)
                          Text("/ $expired 天后过期",
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12))
                      ]),
                  onTap: () => handleBatch(item),
                  onLongPress: () => handleEdit(item, true),
                  trailing: IconButton(
                      onPressed: () => launchUrlString(item.manageUrl),
                      icon: const Icon(Icons.open_in_browser_sharp)),
                  dense: true,
                  subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text(item.user), Text(item.url)])));
        });
  }

  void handleBatch(Registry item) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => RepoBatchView(registry: item)));
  }

  Future<void> handleEdit(Registry item, bool asNew) async {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => RepoAddEditView(
            copyFromOld: asNew,
            registry: asNew ? item.copyWith(id: "", expiredAt: 0) : item)));
  }
}

class RepoBatchView extends ConsumerStatefulWidget {
  final Registry registry;
  const RepoBatchView({super.key, required this.registry});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RepoBatchViewState();
}

class _RepoBatchViewState extends ConsumerState<RepoBatchView> {
  late final registry = widget.registry;
  final input = TextEditingController();
  final input2 = TextEditingController();
  final prefix = TextEditingController();
  bool showOriginal = true;
  bool flat = false;
  int useLocalhost = 0;
  bool homeBrew = false;
  @override
  void dispose() {
    input.dispose();
    input2.dispose();
    prefix.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: DefaultTextStyle(
                style: const TextStyle(fontSize: 13, color: Colors.black),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(registry.id.toUpperCase()),
                      Text(registry.note)
                    ])),
            actions: [
              IconButton(
                  onPressed: () =>
                      {showOriginal = !showOriginal, setState(() {})},
                  icon: Icon(showOriginal ? Icons.raw_on : Icons.raw_off)),
              const SizedBox(width: 3)
            ]),
        body: Column(children: [
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8, bottom: 3),
                  child: TextField(
                      decoration: const InputDecoration(
                          contentPadding: EdgeInsets.only(
                              left: 8, right: 8, top: 8, bottom: 8),
                          border: OutlineInputBorder(),
                          hintText: "输入多个仓库名称, 回车区分"),
                      controller: showOriginal ? input : input2,
                      expands: true,
                      maxLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(fontSize: 12),
                      autocorrect: true))),
          Padding(
              padding: const EdgeInsets.only(left: 5, right: 9),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                IgnorePointer(
                  ignoring: homeBrew,
                  child: Radio.adaptive(
                      value: 0,
                      groupValue: useLocalhost,
                      onChanged: (v) {
                        setState(() {
                          useLocalhost = v!;
                        });
                      }),
                ),
                const Text("DockerHub"),
                Radio.adaptive(
                    value: 1,
                    groupValue: useLocalhost,
                    onChanged: (v) {
                      setState(() {
                        useLocalhost = v!;
                      });
                    }),
                const Text("Localhost"),
                const Spacer(),
                Checkbox.adaptive(
                    value: homeBrew,
                    onChanged: (v) {
                      setState(() {
                        homeBrew = v!;
                        if (homeBrew) {
                          prefix.text = "";
                          flat = false;
                          useLocalhost = 1;
                        }
                      });
                    }),
                const Text("Homebrew")
              ])),
          if (!homeBrew)
            Padding(
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: Row(children: [
                  Expanded(
                      child: TextField(
                          readOnly: homeBrew,
                          controller: prefix,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(labelText: "前缀"))),
                  const SizedBox(width: 8),
                  Transform.translate(
                      offset: const Offset(0, 8),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Checkbox.adaptive(
                            value: flat,
                            onChanged: (v) {
                              if (homeBrew) return;
                              if (v == true && prefix.text.isEmpty) {
                                showSimpleMessage(context,
                                    content: "请输入前缀",
                                    useSnackBar: true,
                                    duration: 5000);
                              } else {
                                setState(() => flat = v!);
                              }
                            }),
                        const Text("拍平")
                      ]))
                ])),
          const SizedBox(height: 10),
          Wrap(children: [
            TextButton(
                onPressed: () {
                  final cmd =
                      "docker login --username ${registry.user} ${registry.url}";
                  setState(() {
                    input2.text = cmd;
                    showOriginal = false;
                  });
                  Clipboard.setData(ClipboardData(text: cmd));
                },
                child: const Text("登录")),
            TextButton(
                onLongPress: handlePullTagPush,
                onPressed: handlePull,
                child: const Text("拉取")),
            TextButton(onPressed: handleTag, child: const Text("打标签")),
            TextButton(onPressed: handlePush, child: const Text("推送")),
            TextButton(onPressed: handleRecord, child: const Text("记录"))
          ]),
          const SizedBox(height: 10)
        ]));
  }

  String repoUrl2Normal(String url) {
    if (!url.contains(":")) url = url + ":latest";
    final sp = url.split("/");
    if (sp.length > 2) return url;
    var host = useLocalhost == 0 ? "docker.io" : "localhost";
    var defaultNS = useLocalhost == 0 ? "library" : "corkine";
    if (sp.length > 1) return "$host/$url";
    return "$host/$defaultNS/$url";
  }

  void handlePull() {
    if (input.text.isEmpty) {
      showSimpleMessage(context,
          content: "请输入仓库名称, 回车区分", useSnackBar: true, duration: 5000);
      return;
    }
    final cmd = input.text
        .split("\n")
        .map((line) {
          if (line.isEmpty) return "";
          return "docker pull ${repoUrl2Normal(line)}";
        })
        .where((e) => e.isNotEmpty)
        .join("\n");
    setState(() {
      showOriginal = false;
      input2.text = cmd;
    });
    Clipboard.setData(ClipboardData(text: cmd));
  }

  void handleTag() {
    if (input.text.isEmpty) {
      showSimpleMessage(context,
          content: "请输入仓库名称, 回车区分", useSnackBar: true, duration: 5000);
      return;
    }
    final cmd = input.text
        .split("\n")
        .map((line) {
          if (line.isEmpty) return "";
          var origin = repoUrl2Normal(line);
          var repline = origin.split("/").skip(1).join("/");
          if (flat) {
            repline = repline.replaceAll("/", "_");
          }
          return "docker tag $origin ${registry.url}/${prefix.text.isEmpty ? "" : prefix.text + "/"}$repline";
        })
        .where((e) => e.isNotEmpty)
        .join("\n");
    setState(() {
      input2.text = cmd;
      showOriginal = false;
    });
    Clipboard.setData(ClipboardData(text: cmd));
  }

  void handlePush() {
    if (input.text.isEmpty) {
      showSimpleMessage(context,
          content: "请输入仓库名称, 回车区分", useSnackBar: true, duration: 5000);
      return;
    }
    final cmd = input.text
        .split("\n")
        .map((line) {
          if (line.isEmpty) return "";
          var origin = repoUrl2Normal(line);
          var repline = origin.split("/").skip(1).join("/");
          if (flat) {
            repline = repline.replaceAll("/", "_");
          }
          return "docker push ${registry.url}/${prefix.text.isEmpty ? "" : prefix.text + "/"}$repline";
        })
        .where((e) => e.isNotEmpty)
        .join("\n");
    setState(() {
      input2.text = cmd;
      showOriginal = false;
    });
    Clipboard.setData(ClipboardData(text: cmd));
  }

  void handlePullTagPush() {
    if (input.text.isEmpty) {
      showSimpleMessage(context,
          content: "请输入仓库名称, 回车区分", useSnackBar: true, duration: 5000);
      return;
    }
    final pullCmd = input.text
        .split("\n")
        .map((line) {
          if (line.isEmpty) return "";
          return "docker pull ${repoUrl2Normal(line)}";
        })
        .where((e) => e.isNotEmpty)
        .join("\n");
    final tagCmd = input.text
        .split("\n")
        .map((line) {
          if (line.isEmpty) return "";
          var origin = repoUrl2Normal(line);
          var repline = origin.split("/").skip(1).join("/");
          if (flat) {
            repline = repline.replaceAll("/", "_");
          }
          return "docker tag $origin ${registry.url}/${prefix.text.isEmpty ? "" : prefix.text + "/"}$repline";
        })
        .where((e) => e.isNotEmpty)
        .join("\n");
    final pushCmd = input.text
        .split("\n")
        .map((line) {
          if (line.isEmpty) return "";
          var origin = repoUrl2Normal(line);
          var repline = origin.split("/").skip(1).join("/");
          if (flat) {
            repline = repline.replaceAll("/", "_");
          }
          return "docker push ${registry.url}/${prefix.text.isEmpty ? "" : prefix.text + "/"}$repline";
        })
        .where((e) => e.isNotEmpty)
        .join("\n");
    setState(() {
      input2.text = pullCmd + "\n\n" + tagCmd + "\n\n" + pushCmd;
      showOriginal = false;
    });
  }

  void handleRecord() async {
    if (input.text.isEmpty) {
      showSimpleMessage(context,
          content: "请输入仓库名称, 回车区分", useSnackBar: true, duration: 5000);
      return;
    }
    final n = ref.read(imageDbProvider.notifier);
    String collect = "";
    List<(Container1, Tag)> list = [];
    for (final line in input.text.split("\n")) {
      if (line.isEmpty) continue;
      var origin = repoUrl2Normal(line);
      var repline = origin.split("/").skip(1).join("/");
      if (flat) {
        repline = repline.replaceAll("/", "_");
      }
      String p;
      String l;
      String t;
      if (prefix.text.isNotEmpty) {
        p = prefix.text;
        l = repline.split("/").skip(0).join("/").split(":").first;
        t = repline.split(":").last;
      } else {
        p = repline.split("/").first;
        l = repline.split("/").skip(1).join("/").split(":").first;
        t = repline.split(":").last;
      }
      final time = DateFormat("yyyy-MM-dd").format(DateTime.now());
      final cc = Container1(namespace: p, id: l, note: "Add@$time");
      list.add((cc, Tag(id: t, registry: [registry.id], note: "Add@$time")));
      collect += "\n$p/$l:$t";
    }
    final ok = await showSimpleMessage(context, content: "将创建以下记录：$collect");
    if (ok) {
      for (final (cc, tag) in list) {
        await n.editOrAddContainer(cc, skipWhenExist: true);
        await n.editOrAddTag(cc, tag);
      }
      final res = await n.saveToRemote();
      await showSimpleMessage(context, content: res, useSnackBar: true);
    }
  }
}

class RepoAddEditView extends ConsumerStatefulWidget {
  final Registry registry;
  final bool copyFromOld;
  const RepoAddEditView(
      {super.key, required this.registry, this.copyFromOld = false});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _RepoAddEditViewState();
}

class _RepoAddEditViewState extends ConsumerState<RepoAddEditView> {
  late Registry registry = widget.registry;
  late bool isAdd = widget.registry.id.isEmpty;
  final formKey = GlobalKey<FormState>();
  final dateController = TextEditingController();
  @override
  void initState() {
    super.initState();
    dateController.text = registry.expiredAt == 0
        ? "永久有效"
        : DateFormat("yyyy-MM-dd")
            .format(DateTime.fromMillisecondsSinceEpoch(registry.expiredAt));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(isAdd
                ? widget.copyFromOld
                    ? "从模板新建"
                    : "添加仓库"
                : "编辑仓库")),
        body: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: Column(children: [
                  TextFormField(
                      decoration: const InputDecoration(labelText: "标记"),
                      initialValue: registry.id,
                      readOnly: !isAdd,
                      validator: (v) => v?.isNotEmpty == true ? null : "不能为空",
                      onSaved: (e) =>
                          registry = registry.copyWith(id: e ?? "")),
                  const SizedBox(height: 3),
                  TextFormField(
                      decoration: const InputDecoration(labelText: "优先级"),
                      initialValue: registry.priority.toString(),
                      validator: (v) =>
                          int.tryParse(v ?? "") == null ? "不能为空" : null,
                      onSaved: (e) => registry =
                          registry.copyWith(priority: int.parse(e!))),
                  const SizedBox(height: 3),
                  TextFormField(
                      decoration: const InputDecoration(labelText: "名称"),
                      initialValue: registry.note,
                      validator: (v) => v?.isNotEmpty == true ? null : "不能为空",
                      onSaved: (e) =>
                          registry = registry.copyWith(note: e ?? "")),
                  const SizedBox(height: 3),
                  TextFormField(
                      decoration: const InputDecoration(labelText: "用户名"),
                      initialValue: registry.user,
                      validator: (v) => v?.isNotEmpty == true ? null : "不能为空",
                      onSaved: (e) =>
                          registry = registry.copyWith(user: e ?? "")),
                  const SizedBox(height: 3),
                  TextFormField(
                      decoration: InputDecoration(
                          labelText: "地址",
                          suffix: InkWell(
                              onTap: () {
                                if (registry.url.isNotEmpty) {
                                  launchUrlString("https://" + registry.url);
                                }
                              },
                              child:
                                  const Icon(Icons.open_in_browser, size: 18))),
                      initialValue: registry.url,
                      validator: (v) => v?.isNotEmpty == true ? null : "不能为空",
                      onSaved: (e) =>
                          registry = registry.copyWith(url: e ?? "")),
                  const SizedBox(height: 3),
                  TextFormField(
                      decoration: InputDecoration(
                          labelText: "管理地址",
                          suffix: InkWell(
                              onTap: () {
                                if (registry.manageUrl.startsWith("http")) {
                                  launchUrlString(registry.manageUrl);
                                }
                              },
                              child:
                                  const Icon(Icons.open_in_browser, size: 18))),
                      initialValue: registry.manageUrl,
                      validator: (v) => v?.isNotEmpty == true ? null : "不能为空",
                      onSaved: (e) =>
                          registry = registry.copyWith(manageUrl: e ?? "")),
                  const SizedBox(height: 3),
                  TextFormField(
                      controller: dateController,
                      decoration: InputDecoration(
                          labelText: "到期时间",
                          suffix: InkWell(
                            onTap: () async {
                              final firstDate = DateTime.now();
                              final lastDate =
                                  firstDate.add(const Duration(days: 365 * 2));
                              final date = await showDatePicker(
                                  context: context,
                                  firstDate: firstDate,
                                  lastDate: lastDate);
                              if (date != null) {
                                registry = registry.copyWith(
                                    expiredAt: date.millisecondsSinceEpoch);
                                dateController.text =
                                    DateFormat("yyyy-MM-dd").format(date);
                              }
                            },
                            child: const Icon(Icons.calendar_today, size: 16),
                          )),
                      readOnly: true,
                      validator: (v) => null,
                      onSaved: (e) => {}),
                  const SizedBox(height: 3),
                  TextButton(
                      onPressed: () async {
                        if (formKey.currentState?.validate() ?? false) {
                          formKey.currentState?.save();
                          await ref
                              .read(imageDbProvider.notifier)
                              .editOrAddRegistry(registry);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("确定"))
                ]))));
  }
}
