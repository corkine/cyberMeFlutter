import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../viewmodels/image.dart';
import '../../util.dart';

class BarView extends ConsumerWidget {
  final Registry registry;
  final Container1 container;
  final Tag tag;
  const BarView(this.container, this.tag, {super.key, required this.registry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color =
        Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4);
    return DefaultTextStyle(
        style: const TextStyle(color: Colors.black, fontSize: 11),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: InkWell(
                child: Container(
                    color: Theme.of(context).colorScheme.primary,
                    height: 25,
                    alignment: Alignment.center,
                    child: Text(registry.id.toUpperCase(),
                        style: const TextStyle(color: Colors.white))),
                onTap: () => launchUrlString(registry.manageUrl)),
          ),
          Expanded(
            child: InkWell(
                child: Container(
                    color: color,
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    alignment: Alignment.center,
                    child: const Text("LOGIN")),
                onTap: () {
                  String cmd =
                      "docker login --username ${registry.user} ${registry.url}";
                  Clipboard.setData(ClipboardData(text: cmd));
                  showSimpleMessage(context,
                      content: "已拷贝到剪贴板", useSnackBar: true);
                }),
          ),
          Expanded(
              child: InkWell(
                  child: Container(
                      color: color,
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      alignment: Alignment.center,
                      child: const Text("PULL")),
                  onTap: () {
                    String cmd =
                        "docker pull ${registry.url}/${container.namespace}/${container.id}:${tag.id}";
                    Clipboard.setData(ClipboardData(text: cmd));
                    showSimpleMessage(context,
                        content: "已拷贝到剪贴板", useSnackBar: true);
                  })),
          Expanded(
              child: InkWell(
                  child: Container(
                      color: color,
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      alignment: Alignment.center,
                      child: const Text("COPY")),
                  onTap: () {
                    Clipboard.setData(ClipboardData(
                        text:
                            "${registry.url}/${container.namespace}/${container.id}:${tag.id}"));
                    showSimpleMessage(context,
                        content: "已拷贝到剪贴板", useSnackBar: true);
                  })),
          Expanded(
              child: InkWell(
                  child: Container(
                      color: Theme.of(context)
                          .colorScheme
                          .errorContainer
                          .withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      alignment: Alignment.center,
                      child: const Text("DELETE")),
                  onTap: () {
                    deleteTagRegistry(
                        ref, context, container, tag, registry.id);
                  }))
        ]));
  }

  deleteTagRegistry(WidgetRef ref, BuildContext context, Container1 container,
      Tag tag, String eid) async {
    if (tag.registry.contains(eid)) {
      final reg = [...tag.registry];
      reg.remove(eid);
      tag = tag.copyWith(registry: reg);
    }
    final res =
        await ref.read(imageDbProvider.notifier).editOrAddTag(container, tag);
    showSimpleMessage(context, content: res, useSnackBar: true);
  }
}
