import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../viewmodels/image.dart';
import '../../util.dart';
import 'tag.dart';

class ContainerView extends ConsumerStatefulWidget {
  const ContainerView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ContainerViewState();
}

class _ContainerViewState extends ConsumerState<ContainerView> {
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(getContainerProvider).value ?? [];
    return ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];
          return Dismissible(
              key: ValueKey(item.id),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.endToStart) {
                  if (await showSimpleMessage(context, content: "确定删除此镜像吗?")) {
                    final res = await ref
                        .read(imageDbProvider.notifier)
                        .deleteContainer(item);
                    await showSimpleMessage(context,
                        content: res, useSnackBar: true);
                    return true;
                  }
                } else {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ContainerAddEditView(item)));
                  return false;
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
                                  color: Colors.white, fontSize: 15))))),
              background: Container(
                  color: Colors.blue,
                  child: const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: Text("编辑",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 15))))),
              child: ListTile(
                  title: Row(children: [
                    Text(item.namespace),
                    const Text(" / "),
                    Text(item.id, style: const TextStyle(fontSize: 14))
                  ]),
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (c) => TagView(item))),
                  onLongPress: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ContainerAddEditView(
                            item.copyWith(id: "", tags: {}),
                            copyFromOld: true)));
                  },
                  dense: true,
                  subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.note.isEmpty ? "无备注信息" : item.note),
                        const SizedBox(height: 3),
                        Wrap(
                            children: item.tags.entries
                                .map((e) => buildContainer(e.key))
                                .toList())
                      ])));
        });
  }

  Widget buildContainer(String reg) {
    return Container(
        padding: const EdgeInsets.only(
          left: 4,
          right: 4,
        ),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Theme.of(context).primaryColor.withOpacity(0.2)),
        child: Text(reg,
            style: const TextStyle(fontSize: 12, fontFamily: "Consolas")));
  }
}

class ContainerAddEditView extends ConsumerStatefulWidget {
  final Container1 item;
  final bool copyFromOld;
  const ContainerAddEditView(this.item, {super.key, this.copyFromOld = false});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ContainerAddEditViewState();
}

class _ContainerAddEditViewState extends ConsumerState<ContainerAddEditView> {
  late Container1 item = widget.item;
  late bool isEdit = item.id.isNotEmpty;
  final key = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: item.id.isEmpty
                ? widget.copyFromOld
                    ? const Text("从模板新建镜像")
                    : const Text("新建镜像")
                : const Text("修改镜像")),
        body: Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: Form(
                key: key,
                child: Column(children: [
                  TextFormField(
                    readOnly: isEdit,
                    onSaved: (v) => item = item.copyWith(namespace: v ?? ""),
                    validator: (value) =>
                        value?.isEmpty ?? true ? "请输入名称" : null,
                    initialValue: item.namespace,
                    decoration: const InputDecoration(labelText: "命名空间"),
                  ),
                  const SizedBox(height: 3),
                  TextFormField(
                    readOnly: isEdit,
                    onSaved: (v) => item = item.copyWith(id: v ?? ""),
                    validator: (value) =>
                        value?.isEmpty ?? true ? "请输入名称" : null,
                    initialValue: item.id,
                    decoration: const InputDecoration(labelText: "名称"),
                  ),
                  const SizedBox(height: 3),
                  TextFormField(
                    onSaved: (v) => item = item.copyWith(note: v ?? ""),
                    validator: (value) => null,
                    initialValue: item.note,
                    decoration: const InputDecoration(labelText: "备注信息"),
                  ),
                  const SizedBox(height: 13),
                  ElevatedButton(
                      onPressed: () async {
                        if (key.currentState!.validate()) {
                          key.currentState!.save();
                          await ref
                              .read(imageDbProvider.notifier)
                              .editOrAddContainer(item);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("保存"))
                ]))));
  }
}
