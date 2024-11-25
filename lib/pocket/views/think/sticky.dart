import 'package:cyberme_flutter/pocket/viewmodels/sticky.dart';
import 'package:cyberme_flutter/pocket/views/server/service/common.dart';
import 'package:cyberme_flutter/pocket/views/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:html/dom_parsing.dart';
import 'package:html/dom.dart' as dom;
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html/parser.dart';

class StickyNoteView extends ConsumerStatefulWidget {
  const StickyNoteView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _StickyNoteViewState();
}

class _StickyNoteViewState extends ConsumerState<StickyNoteView> {
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(stickyNotesProvider).value ?? [];
    return Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(slivers: [
          SliverAppBar(
              stretch: true,
              expandedHeight: 180,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.fadeTitle,
                    StretchMode.zoomBackground
                  ],
                  collapseMode: CollapseMode.parallax,
                  centerTitle: false,
                  title: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      onLongPress: () async {
                        await showWaitingBar(context, func: () async {
                          final res = await ref
                              .read(stickyNotesProvider.notifier)
                              .forceUpdate();
                          await showSimpleMessage(context,
                              content: res, useSnackBar: true);
                        });
                      },
                      child: const Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: Text("Sticky Note",
                              style: TextStyle(color: Colors.white)))),
                  background:
                      Image.asset("images/wood.jpg", fit: BoxFit.cover))),
          SliverList.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                return Dismissible(
                    key: ValueKey(item.id),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        if (await confirm(context, "确定删除此条笔记吗?")) {
                          final data = await ref
                              .read(stickyNotesProvider.notifier)
                              .delete(item.id);
                          showSimpleMessage(context, content: data.$2);
                          return data.$1;
                        } else {
                          return false;
                        }
                      } else {
                        return false;
                      }
                    },
                    background: Container(color: Colors.amber),
                    secondaryBackground: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white)),
                    child: ListTile(
                        title: Text(item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black)),
                        subtitle: Text(item.update,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                        onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => SizedBox(
                                height:
                                    MediaQuery.maybeSizeOf(context)!.height -
                                        200,
                                child: NoteView(item))),
                        onLongPress: () => launchUrlString(item.url)));
              })
        ]));
  }
}

class NoteView extends ConsumerWidget {
  final StickyNoteItem item;
  const NoteView(this.item, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        appBar: AppBar(
            title:
                const Text("笔记详情", style: TextStyle(fontSize: 20), maxLines: 2),
            actions: [
              IconButton(
                  onPressed: () {
                    final doc = parse(item.body);
                    final String plainText = doc.body!.textPretty;
                    Clipboard.setData(ClipboardData(text: plainText));
                    showSimpleMessage(context,
                        content: "已拷贝", useSnackBar: true);
                  },
                  icon: const Icon(Icons.copy)),
              const SizedBox(width: 10)
            ]),
        body: SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 30),
                child: HtmlWidget(item.body))));
  }
}

class ConcatTextVisitor extends TreeVisitor {
  final _str = StringBuffer();

  @override
  String toString() => _str.toString();

  @override
  void visitText(dom.Text node) {
    final n = node.data;
    if (n.trim().isEmpty) return;
    _str.write(node.data + "\n");
  }
}

extension on dom.Element {
  String get textPretty => (ConcatTextVisitor()..visit(this)).toString();
}
