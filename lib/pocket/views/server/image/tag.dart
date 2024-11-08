import 'package:cyberme_flutter/pocket/views/util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../viewmodels/image.dart';
import 'bar.dart';

class TagView extends ConsumerStatefulWidget {
  final Container1 item;
  const TagView(this.item, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TagViewState();
}

class _TagViewState extends ConsumerState<TagView> {
  late Container1 item = widget.item;
  late List<Tag> tags =
      item.tags.entries.map((e) => e.value.copyWith(id: e.key)).toList();

  @override
  Widget build(BuildContext context) {
    final regMap = Map.fromEntries((ref.watch(getRegistryProvider).value ?? [])
        .map((e) => MapEntry<String, Registry>(e.id, e)));
    ref.listen(imageDbProvider.select((p) {
      final v = p.value ?? Images();
      final itemNew = v.images[item.namespace]?[item.id];
      return itemNew;
    }), (o, n) {
      setState(() {
        item = n!;
        tags =
            item.tags.entries.map((e) => e.value.copyWith(id: e.key)).toList();
      });
    });
    return Scaffold(
        appBar: AppBar(
            title: DefaultTextStyle(
                style: const TextStyle(fontSize: 18, color: Colors.black),
                child: Row(children: [
                  Text(item.namespace),
                  const Text(" / "),
                  Text(item.id)
                ])),
            actions: [
              IconButton(
                  onPressed: () => showAddOrEditTag(item, Tag(), false),
                  icon: const Icon(Icons.add)),
              const SizedBox(width: 5)
            ]),
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (item.note.isNotEmpty)
            Container(
                width: double.infinity,
                margin: const EdgeInsets.only(left: 8, right: 8, top: 3),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(5)),
                padding: const EdgeInsets.only(left: 15, bottom: 10, top: 10),
                child: Text(item.note,
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer))),
          Expanded(
              child: ListView.builder(
                  itemBuilder: (context, idx) {
                    final tag = tags[idx];
                    return ListTile(
                        title: Transform.translate(
                            offset: const Offset(-3, 0),
                            child: Row(children: [
                              Transform.translate(
                                  offset: const Offset(0, 2),
                                  child:
                                      const Icon(Icons.tag_outlined, size: 17)),
                              Text(tag.id),
                              const Spacer(),
                              InkWell(
                                  onTap: () => showAddOrEditTag(
                                      item, tag.copyWith(id: ""), true),
                                  child: Container(
                                      margin: const EdgeInsets.only(
                                          left: 4, right: 4, bottom: 0),
                                      child: const Text("🖨",
                                          style: TextStyle(fontSize: 10)))),
                              InkWell(
                                  onTap: () =>
                                      showAddOrEditTag(item, tag, true),
                                  child: Container(
                                      margin: const EdgeInsets.only(
                                          left: 4, right: 4, bottom: 0),
                                      child: const Text("✏",
                                          style: TextStyle(fontSize: 10)))),
                              InkWell(
                                  onTap: () => addTagRegistry(item, tag),
                                  child: Container(
                                      margin: const EdgeInsets.only(
                                          left: 4, right: 4, bottom: 0),
                                      child: const Text("➕",
                                          style: TextStyle(fontSize: 10)))),
                              InkWell(
                                  onTap: () => deleteTag(item, tag),
                                  child: Container(
                                      margin: const EdgeInsets.only(
                                          left: 3, right: 3, bottom: 0),
                                      child: const Text("❌",
                                          style: TextStyle(fontSize: 10))))
                            ])),
                        subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tag.note,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary)),
                              const SizedBox(height: 9),
                              ...tag.registry
                                  .where((e) => regMap.containsKey(e))
                                  .map((e) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 3),
                                        child: BarView(item, tag,
                                            registry: regMap[e]!),
                                      ))
                            ]));
                  },
                  itemCount: tags.length))
        ]));
  }

  showAddOrEditTag(Container1 container, Tag? tag, bool isEdit) {
    // Navigator.of(context).push(MaterialPageRoute(
    //     builder: (context) =>
    //         TagAddEditView(tag: tag ?? Tag(), copyFromOld: isEdit)));
    showSheet(
        context: context,
        builder: (context) => TagAddEditView(
            container1: container, tag: tag ?? Tag(), copyFromOld: isEdit));
  }

  deleteTag(Container1 container, Tag tag) async {
    await ref.read(imageDbProvider.notifier).deleteTag(container, tag);
  }

  addTagRegistry(Container1 container, Tag tag) async {
    final r = await ref.read(getRegistryProvider.future);
    showDialog(
        context: context,
        builder: (context) => SimpleDialog(
            title: const Text("标记存储到仓库", style: TextStyle(fontSize: 19)),
            children: r.map((e) {
              return SimpleDialogOption(
                  onPressed: () async {
                    if (!tag.registry.contains(e.id)) {
                      tag = tag.copyWith(registry: [...tag.registry, e.id]);
                    }
                    final res = await ref
                        .read(imageDbProvider.notifier)
                        .editOrAddTag(container, tag);
                    showSimpleMessage(context, content: res, useSnackBar: true);
                    Navigator.pop(context);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.id.toUpperCase() + " " + e.note),
                      Text(e.url, style: const TextStyle(fontSize: 10))
                    ],
                  ));
            }).toList()));
  }
}

class TagAddEditView extends ConsumerStatefulWidget {
  final Container1 container1;
  final Tag tag;
  final bool copyFromOld;
  const TagAddEditView(
      {super.key,
      required this.container1,
      required this.tag,
      this.copyFromOld = false});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TagAddEditViewState();
}

class _TagAddEditViewState extends ConsumerState<TagAddEditView> {
  late Tag tag = widget.tag;
  late bool isEdit = tag.id.isNotEmpty;
  late TextEditingController tagName = TextEditingController(text: tag.id);
  late TextEditingController tagNote = TextEditingController(text: tag.note);

  @override
  void dispose() {
    tagName.dispose();
    tagNote.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.only(top: 15, left: 10, right: 10),
              child: Column(children: [
                Text(
                    isEdit
                        ? "编辑 Tag"
                        : widget.copyFromOld
                            ? "从其他 Tag 新建"
                            : "添加 Tag",
                    style: const TextStyle(fontSize: 17)),
                TextField(
                    controller: tagName,
                    decoration: const InputDecoration(labelText: "Tag ID")),
                const SizedBox(height: 10),
                TextField(
                  controller: tagNote,
                  maxLines: 5,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(labelText: "Note"),
                ),
                const SizedBox(height: 20),
                TextButton(
                    onPressed: () async {
                      if (tagName.text.isEmpty) {
                        showSimpleMessage(context,
                            content: "请输入 Tag ID", useSnackBar: true);
                        return;
                      }
                      tag = tag.copyWith(id: tagName.text, note: tagNote.text);
                      await ref
                          .read(imageDbProvider.notifier)
                          .editOrAddTag(widget.container1, tag);
                      Navigator.of(context).pop();
                    },
                    child: const Text("确定")),
                const SizedBox(height: 10)
              ])),
        ));
  }
}
