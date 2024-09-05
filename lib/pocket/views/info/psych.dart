import 'package:cyberme_flutter/main.dart';
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
        builder: (context) => Theme(
            data: appThemeData,
            child: AlertDialog(
                title: const Text("搜索"),
                actions: [
                  TextButton(
                      onPressed: () =>
                          Navigator.pop(context, int.tryParse(input.text)),
                      child: const Text("确定"))
                ],
                content: TextField(
                    controller: input,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(hintText: "输入要搜索的 Id")))));
    if (res != null) {
      final out = await ref.read(psychDbProvider.notifier).fetchOne(res);
      if (out.id == 0) {
        showSimpleMessage(context, content: "该 Id 不存在", useSnackBar: true);
        return;
      }
      await showDialog(
          context: context,
          builder: (context) => Theme(
                data: appThemeData,
                child: AlertDialog(
                    contentPadding: const EdgeInsets.only(
                        left: 5, right: 5, top: 15, bottom: 15),
                    content: buildItem(out)),
              ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = ref.watch(fetchPsychItemsProvider);
    return Theme(
      data: appThemeData,
      child: Scaffold(
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
              itemCount: res.length)),
    );
  }

  addNote(PsychItem item) async {
    final input = TextEditingController(text: item.note);
    final res = await showDialog<String>(
        context: context,
        builder: (context) => Theme(
              data: appThemeData,
              child: AlertDialog(
                actions: [
                  TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final a = await ref
                            .read(psychNoteDbProvider.notifier)
                            .delNote(item.id);
                        showSimpleMessage(context,
                            content: a, useSnackBar: true);
                      },
                      child: Text("删除",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error))),
                  TextButton(
                      onPressed: () => Navigator.pop(context, input.text),
                      child: const Text("确定"))
                ],
                content: TextField(
                    controller: input,
                    maxLines: 10,
                    decoration: const InputDecoration(hintText: "输入备注")),
              ),
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
        onTap: () => showDetails(item),
        onLongPress: () {
          if (item.url.isNotEmpty) {
            launchUrlString(item.url);
            return;
          }
        });
  }

  showDetails(PsychItem item) async {
    var itemNeedOpen = item;
    if (item.info.isEmpty) {
      itemNeedOpen = (await fetchContent(item)).copyWith(note: item.note);
    }
    showAdaptiveBottomSheet(
        minusHeight: 130,
        cover: true,
        context: context,
        builder: (context) => Theme(
              data: appThemeData,
              child: Scaffold(
                  appBar: AppBar(actions: [
                    TextButton(
                        onPressed: () => launchUrlString(itemNeedOpen.url),
                        child: const Text("网页打开")),
                    const SizedBox(width: 10)
                  ]),
                  body: SingleChildScrollView(
                      child: Padding(
                          padding: const EdgeInsets.only(
                              left: 18, bottom: 8, right: 18),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("id: " + itemNeedOpen.id.toString()),
                                Text("kind: " + itemNeedOpen.kind),
                                Text("note: " + itemNeedOpen.note),
                                Text("info: " + itemNeedOpen.info.toString())
                              ])))),
            ));
  }

  Future<PsychItem> fetchContent(PsychItem item) async {
    final newItem = await ref.read(psychDbProvider.notifier).fetchOne(item.id);
    return newItem;
  }
}
