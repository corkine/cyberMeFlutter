import 'package:cyberme_flutter/pocket/viewmodels/psych.dart';
import 'package:cyberme_flutter/pocket/views/util.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PsychRecentView extends ConsumerStatefulWidget {
  const PsychRecentView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PsychRecentViewState();
}

class _PsychRecentViewState extends ConsumerState<PsychRecentView> {
  late DateTime weekDayOne;
  late DateTime lastWeekDayOne;
  late int weekDayOneMs;
  late DateTime today;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    today = DateTime(now.year, now.month, now.day);
    weekDayOne = getThisWeekMonday();
    lastWeekDayOne = weekDayOne.subtract(const Duration(days: 7));
  }

  search() async {
    final input = TextEditingController();
    final res = await showDialog<int>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("搜索"),
              actions: [
                TextButton(
                    onPressed: () =>
                        Navigator.pop(context, int.tryParse(input.text)),
                    child: const Text("确定"))
              ],
              content: TextField(
                  controller: input,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: "输入要搜索的 Id")),
            ));
    if (res != null) {
      final out = await ref.read(psychDbProvider.notifier).fetchOne(res);
      await showDialog(
          context: context,
          builder: (context) => AlertDialog(
              title: const Text("结果"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("确定"))
              ],
              content: buildItem(out)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = ref.watch(fetchPsychItemsProvider);
    return Scaffold(
        appBar: AppBar(title: const Text("Psych Cases"), actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: search),
          IconButton(
              icon: const Icon(Icons.playlist_add),
              onPressed: () async {
                final res = await ref.read(psychDbProvider.notifier).next();
                showSimpleMessage(context, content: res, useSnackBar: true);
              }),
          const SizedBox(width: 10)
        ]),
        body: ListView.builder(
            itemBuilder: (context, index) {
              final item = res[index];
              return buildItem(item);
            },
            itemCount: res.length));
  }

  addNote(PsychItem item) async {
    final input = TextEditingController(text: item.note);
    final res = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              actions: [
                TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final a = await ref
                          .read(psychNoteDbProvider.notifier)
                          .delNote(item.id);
                      showSimpleMessage(context, content: a, useSnackBar: true);
                    },
                    child: const Text("删除")),
                TextButton(
                    onPressed: () => Navigator.pop(context, input.text),
                    child: const Text("确定"))
              ],
              content: TextField(
                  controller: input,
                  maxLines: 10,
                  decoration: const InputDecoration(hintText: "输入备注")),
            ));
    if (res != null && res.isNotEmpty) {
      final result =
          await ref.read(psychNoteDbProvider.notifier).addNote(item.id, res);
      showSimpleMessage(context, content: result, useSnackBar: true);
    }
  }

  ListTile buildItem(PsychItem item) {
    return ListTile(
        dense: true,
        title: Row(children: [
          Text(item.kind, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 5),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(item.note,
                overflow: TextOverflow.fade,
                style: const TextStyle(
                    height: 1, fontSize: 11, color: Colors.grey)),
          ))
        ]),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
              onPressed: () => addNote(item),
              icon: Icon(item.note.isNotEmpty ? Icons.edit : Icons.note_add))
        ]),
        subtitle: Row(children: [
          Text(item.id.toString()),
          const SizedBox(width: 7),
          buildRichDate(
              DateFormat("yyyy-MM-ddTH:mm:ss.SSS").parse(item.createAt),
              today: today,
              weekDayOne: weekDayOne,
              lastWeekDayOne: lastWeekDayOne)
        ]),
        onTap: () async {
          if (item.info.isEmpty) {
            final itemNew = await fetchContent(item);
            showSimpleMessage(context,
                content: itemNew.copyWith(note: item.note).toString());
          } else {
            showSimpleMessage(context, content: item.toString());
          }
        },
        onLongPress: () {
          if (item.url.isNotEmpty) {
            launchUrlString(item.url);
            return;
          }
        });
  }

  Future<PsychItem> fetchContent(PsychItem item) async {
    final newItem = await ref.read(psychDbProvider.notifier).fetchOne(item.id);
    await showSimpleMessage(context, content: "已获取内容", useSnackBar: true);
    return newItem;
  }
}
