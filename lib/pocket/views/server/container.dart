import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/material.dart' as m;
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
              secondaryBackground: m.Container(
                  color: Colors.red,
                  child: const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                          padding: EdgeInsets.only(right: 20),
                          child: Text("删除",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 15))))),
              background: m.Container(
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
                  onTap: () {},
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
    return m.Container(
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
