import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../main.dart';
import '../../../viewmodels/track.dart';
import '../../util.dart';
import 'detail.dart';
import 'service.dart';
import 'statistic.dart';

class TrackView extends ConsumerStatefulWidget {
  const TrackView({super.key});

  @override
  ConsumerState<TrackView> createState() => _TrackViewState();
}

class _TrackViewState extends ConsumerState<TrackView> {
  final search = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(trackSettingsProvider.future).then((value) {
      setState(() => search.text = value.lastSearch);
    });
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    ref.read(trackSettingsProvider.notifier).setLastSearch(search.text,
        originData: ref.read(fetchTrackProvider).value, withUpload: true);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final setting = ref.watch(trackSettingsProvider).value;
    final data = ref.watch(trackDataProvider.call(search.text));
    final changed = ref.watch(trackSearchChangedProvider);

    final appBar = AppBar(
        centerTitle: false,
        titleSpacing: 0,
        title: const Text("Track!Me"),
        actions: [
          IconButton(
              onPressed: () async {
                ref.read(trackSettingsProvider.notifier).setLastSearch(
                    search.text,
                    originData: ref.read(fetchTrackProvider).value,
                    withUpload: true);
                ref.invalidate(fetchTrackProvider);
              },
              icon: const Icon(Icons.refresh)
                  .animate(key: ValueKey(changed.isEmpty ? "" : changed.first))
                  .fadeIn(duration: const Duration(milliseconds: 500))
                  .rotate(
                      begin: 0,
                      end: 1,
                      duration: const Duration(milliseconds: 300))),
          IconButton(
              onPressed: () =>
                  showModal(context, const ServiceView(useSheet: true)),
              icon: const Icon(Icons.dashboard)),
          IconButton(
              onPressed: () => showModal(context, const StatisticsView()),
              icon: const Icon(Icons.leaderboard)),
          IconButton(
              onPressed: () => ref
                  .read(trackSettingsProvider.notifier)
                  .setTrackSortReversed(),
              icon: Icon(setting?.sortByName ?? true
                  ? Icons.format_list_numbered
                  : Icons.sort_by_alpha)),
          IconButton(
              onPressed: handleAddSearchItem, icon: const Icon(Icons.add))
        ]);

    if (setting == null) {
      return Theme(
          data: appThemeData,
          child: Scaffold(
              appBar: appBar,
              body: const Center(child: CupertinoActivityIndicator())));
    }

    final dataList = ListView.builder(
        itemBuilder: (ctx, idx) {
          final c = data[idx];
          final privCount = setting.lastData[c.$1];
          final deltaCount = privCount == null ? 0 : c.$2 - privCount;
          final deltaStyle = deltaCount > 0
              ? const TextStyle(color: Colors.green, fontSize: 10)
              : const TextStyle(color: Colors.red, fontSize: 10);
          return InkWell(
              child: Padding(
                  padding: const EdgeInsets.only(
                      left: 10, right: 10, top: 8, bottom: 8),
                  child: Row(children: [
                    Expanded(
                        child: Text(c.$1,
                            overflow: TextOverflow.ellipsis, maxLines: 1)),
                    const SizedBox(width: 5),
                    Text(c.$2.toString()),
                    Text(
                        deltaCount == 0
                            ? ""
                            : " ${deltaCount > 0 ? "+" : ""}$deltaCount",
                        style: deltaStyle)
                  ], mainAxisAlignment: MainAxisAlignment.spaceBetween)),
              onLongPress: () => showPopupMenu(data, c),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (ctx) => TrackDetailView(url: c.$1, count: c.$2))));
        },
        itemCount: data.length);

    final searchBar = CupertinoSearchTextField(
        onChanged: (value) => setState(() {}),
        controller: search,
        placeholder: "搜索",
        style: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.only(left: 10, right: 10));

    return Theme(
        data: appThemeData,
        child: Scaffold(
            appBar: appBar,
            body: RefreshIndicator(
                onRefresh: () async => await ref.refresh(fetchTrackProvider),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: AnimatedOpacity(
                              opacity: data.isEmpty ? 0 : 1,
                              duration: const Duration(milliseconds: 500),
                              child: dataList)),
                      Container(
                          height: 45,
                          padding: const EdgeInsets.only(
                              left: 10, right: 10, top: 5, bottom: 10),
                          child: searchBar),
                      Padding(
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: Wrap(
                              spacing: 5,
                              runSpacing: 5,
                              children: setting.searchItems
                                  .map((e) => buildSearchItemChip(
                                      setting, e, changed.contains(e.search)))
                                  .toList(growable: false))),
                      const SizedBox(height: 10)
                    ]))));
  }

  Widget buildSearchItemChip(setting, e, isChange) {
    return GestureDetector(
        onLongPress: () => showDialog(
            context: context,
            builder: (context) => Theme(
                data: appThemeData,
                child: SimpleDialog(children: [
                  SimpleDialogOption(
                      onPressed: () {
                        ref.read(trackSettingsProvider.notifier).setTrack(
                            setting.searchItems
                                .where((element) => element.id != e.id)
                                .toList(growable: false));
                        Navigator.of(context).pop();
                      },
                      child: const Text("删除"))
                ]))),
        child: RawChip(
            label: Text(e.title + (isChange ? "*" : ""),
                style: TextStyle(
                    color: isChange ? Colors.greenAccent : Colors.white)),
            onSelected: (v) {
              search.text = v ? e.search : "";
              setState(() {});
            },
            selected: search.text == e.search,
            labelPadding: const EdgeInsets.only(left: 3, right: 3),
            visualDensity: VisualDensity.compact));
  }

  void showPopupMenu(data, c) => showDialog(
      context: context,
      builder: (context) => SimpleDialog(title: Text(c.$1), children: [
            SimpleDialogOption(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final res =
                      await ref.read(deleteTrackProvider.call([c.$1]).future);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(res)));
                },
                child: const Text("删除当前项")),
            SimpleDialogOption(
                onPressed: () async {
                  final userAnswer = await showDialog<bool>(
                      barrierDismissible: false,
                      context: context,
                      builder: (context) => AlertDialog(
                              title: const Text("确定"),
                              content: const Text("此操作不可撤销，确定执行？"),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text("取消")),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text("确定"))
                              ]));
                  if (userAnswer == true) {
                    Navigator.of(context).pop();
                    final res = await ref.read(deleteTrackProvider
                        .call(data.map((e) => e.$1).toList())
                        .future);
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(res)));
                  }
                },
                child: const Text("删除当前搜索结果所有项"))
          ]));

  void handleAddSearchItem() async {
    var title = "";
    var enableTrack = true;
    var searchC2 = TextEditingController(text: search.text);

    handleAdd() {
      if (title.isNotEmpty && searchC2.text.isNotEmpty) {
        ref.read(trackSettingsProvider.notifier).addTrack(TrackSearchItem(
            title: title,
            search: search.text,
            track: enableTrack,
            id: DateTime.now().millisecondsSinceEpoch.toString()));
        Navigator.of(context).pop();
      } else {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                    title: const Text("警告"),
                    content: const Text("搜索内容和标题均不能为空"),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("确定"))
                    ]));
      }
    }

    await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setState) => Theme(
                  data: appThemeData,
                  child: AlertDialog(
                      title: const Text("添加快捷方式"),
                      content:
                          Column(mainAxisSize: MainAxisSize.min, children: [
                        TextField(
                            controller: searchC2,
                            decoration:
                                const InputDecoration(labelText: "搜索内容")),
                        const SizedBox(height: 10),
                        TextField(
                            autofocus: true,
                            decoration:
                                const InputDecoration(labelText: "快捷方式标题"),
                            onChanged: (value) => title = value),
                        const SizedBox(height: 10),
                        Transform.translate(
                            offset: const Offset(-10, 0),
                            child: Row(children: [
                              Checkbox.adaptive(
                                  visualDensity: VisualDensity.compact,
                                  value: enableTrack,
                                  onChanged: (v) {
                                    setState(() => enableTrack = v!);
                                  }),
                              const SizedBox(width: 10),
                              const Text("追踪变更")
                            ]))
                      ]),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text("取消")),
                        TextButton(
                            onPressed: handleAdd, child: const Text("确定"))
                      ]),
                )));
  }
}
