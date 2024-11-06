import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../viewmodels/image.dart';
import '../util.dart';

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
                  //showEditDialog(activity);
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
                  title: Row(
                    children: [
                      Text(item.namespace),
                      const Text(" / "),
                      Text(item.id, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (c) => TagView(item)));
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
    return Scaffold(
        appBar: AppBar(
          title: DefaultTextStyle(
            style: const TextStyle(fontSize: 18, color: Colors.black),
            child: Row(
              children: [
                Text(item.namespace),
                const Text(" / "),
                Text(item.id)
              ],
            ),
          ),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
            const SizedBox(width: 5)
          ],
        ),
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
                          const Icon(Icons.tag_outlined, size: 17),
                          Text(tag.id),
                          const Spacer(),
                          InkResponse(
                              onTap: () {},
                              child: Container(
                                  margin: const EdgeInsets.only(
                                      left: 3, right: 3, bottom: 3),
                                  child: const Text("+")))
                        ])),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tag.note,
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.secondary),
                        ),
                        const SizedBox(height: 3),
                        ...tag.registry.map((e) => ListTile(
                            title: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(e.toUpperCase(),
                                    style: const TextStyle(
                                        fontFamily: "Consolas"))),
                            contentPadding: const EdgeInsets.only(left: 0),
                            subtitle: Wrap(
                              spacing: 3,
                              runSpacing: 3,
                              children: [
                                OutlinedButton(
                                    onPressed: () {},
                                    child: const Text("docker login")),
                                OutlinedButton(
                                    onPressed: () {},
                                    child: const Text("docker pull")),
                                OutlinedButton(
                                    onPressed: () {},
                                    child: const Text("docker tag")),
                                OutlinedButton(
                                    onPressed: () {},
                                    child: const Text("docker push"))
                              ],
                            ),
                            dense: true))
                      ],
                    ),
                  );
                },
                itemCount: tags.length),
          )
        ]));
  }
}
