import 'package:cyberme_flutter/pocket/util.dart';
import 'package:cyberme_flutter/pocket/viewmodels/blocks.dart';
import 'package:cyberme_flutter/pocket/views/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class BlocksView extends ConsumerStatefulWidget {
  const BlocksView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BlocksViewState();
}

String urlOfDate(DateTime date) {
  return animalBgs[(date.day).floor() % animalBgs.length];
}

class _BlocksViewState extends ConsumerState<BlocksView> {
  final Set<String> _selectTags = {};

  handleAdd() {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => BlockDetailView(BlockItem())));
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(getBlocksListProvider(_selectTags));
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        // floatingActionButton: FloatingActionButton(
        //     onPressed: handleAdd, child: const Icon(Icons.add)),
        body: CustomScrollView(slivers: <Widget>[
          SliverAppBar(
              //title: const Text('Blocks', style: TextStyle(color: Colors.white)),
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.blueGrey,
              leading: const BackButton(color: Colors.white),
              actions: [
                IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    onPressed: handleFilter),
                IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: handleAdd),
                const SizedBox(width: 5)
              ],
              flexibleSpace: FlexibleSpaceBar(
                  title: const Text('Blocks',
                      style: TextStyle(color: Colors.white)),
                  centerTitle: false,
                  background: Image.network(
                      'https://static2.mazhangjing.com/cyber/202408/900c30de_Snipaste_2024-08-02_14-01-13.jpg',
                      fit: BoxFit.cover))),
          const SliverToBoxAdapter(child: SizedBox(height: 2)),
          SliverList(
              delegate: SliverChildBuilderDelegate(
                  (context, index) => buildCard(context, data[index]),
                  childCount: data.length)),
          const SliverToBoxAdapter(child: SizedBox(height: 3))
        ]));
  }

  Widget buildCard(BuildContext context, BlockItem item) {
    const height = 70.0;
    final createDate = DateTime.fromMillisecondsSinceEpoch(item.createDate);
    return Card(
        elevation: 1,
        margin: const EdgeInsets.only(bottom: 2, top: 2, left: 4, right: 4),
        child: InkWell(
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => BlockDetailView(item))),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Stack(children: [
                  Opacity(
                      opacity: 0.9,
                      child: Image.network(urlOfDate(createDate),
                          width: double.infinity,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0.5, -0.5),
                          height: height)),
                  Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: height,
                      child: Container(
                          color: Colors.black.withOpacity(0.2),
                          child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 10, right: 10),
                              child: DefaultTextStyle(
                                  style: const TextStyle(color: Colors.white),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(children: [
                                          Text(item.title,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15)),
                                          const Spacer(),
                                          Icon(Icons.format_quote,
                                              size: 17,
                                              color: item.isReference
                                                  ? Colors.white
                                                  : Colors.transparent)
                                        ]),
                                        const SizedBox(height: 5),
                                        Row(children: [
                                          Expanded(
                                            child: DefaultTextStyle(
                                                style: const TextStyle(
                                                    fontSize: 13),
                                                child: Wrap(
                                                    spacing: 6,
                                                    children: item.tags
                                                        .map((e) => Text("#$e"))
                                                        .toList())),
                                          ),
                                          Text(DateFormat.yMd("zh_Hans")
                                              .format(createDate)
                                              .toString())
                                        ])
                                      ])))))
                ]))));
  }

  handleFilter() async {
    final tags = ref.watch(getBlockTagsProvider);
    final _tags = <String>{..._selectTags};
    await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setState) => SimpleDialog(
                title: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text("选择标签"),
                      const Spacer(),
                      InkWell(
                          onTap: () => setState(() {
                                if (_tags.isEmpty) {
                                  _tags.addAll(tags);
                                } else {
                                  _tags.clear();
                                }
                              }),
                          child: Text(_tags.isEmpty ? "全选" : "清空",
                              style: const TextStyle(fontSize: 14)))
                    ]),
                children: (tags.toList()..sort())
                    .map((tag) => SimpleDialogOption(
                        onPressed: () {
                          setState(() {
                            if (_tags.contains(tag)) {
                              _tags.remove(tag);
                            } else {
                              _tags.add(tag);
                            }
                          });
                        },
                        child: Row(children: [
                          _tags.contains(tag)
                              ? const Icon(Icons.check, color: Colors.green)
                              : Icon(Icons.check,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer),
                          const SizedBox(width: 10),
                          Text(tag)
                        ])))
                    .toList())));
    _selectTags.clear();
    _selectTags.addAll(_tags);
    ref.invalidate(getBlocksListProvider);
  }
}

class BlockDetailView extends ConsumerStatefulWidget {
  final BlockItem item;
  const BlockDetailView(this.item, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _BlockDetailViewState();
}

class _BlockDetailViewState extends ConsumerState<BlockDetailView> {
  late BlockItem item = widget.item;
  final _controller = TextEditingController();
  bool _edit = false;
  bool _preview = false;

  @override
  void initState() {
    super.initState();
    if (item.createDate == 0) {
      _edit = true;
    }
    if (item.id.isEmpty) {
      item = item.copyWith(id: const Uuid().v4());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  BlockItem extractMerge(BlockItem old, String input) {
    List<String> lines = input.split('\n');
    String title = lines.isNotEmpty ? lines[0] : "无标题";
    List<String> tags = extractHashtags(lines);
    return old.copyWith(
        title: title,
        content: input,
        tags: tags,
        lastUpdate: DateTime.now().millisecondsSinceEpoch,
        createDate: old.createDate == 0
            ? DateTime.now().millisecondsSinceEpoch
            : old.createDate);
  }

  List<String> extractHashtags(List<String> lines) {
    List<String> result = [];
    for (int i = 0; i < lines.length && i < 3; i++) {
      RegExp exp = RegExp(r'#([^\s#]+(?:\s+[^\s#]+)*)');
      Iterable<RegExpMatch> matches = exp.allMatches(lines[i]);
      for (RegExpMatch match in matches) {
        if (match.groupCount >= 1) {
          result.add(match.group(1)!);
        }
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final createDate = DateTime.fromMillisecondsSinceEpoch(item.createDate);
    return Scaffold(
        body: CustomScrollView(slivers: <Widget>[
      SliverAppBar(
          expandedHeight: 200.0,
          floating: false,
          pinned: false,
          actions: [
            if (_edit)
              IconButton(
                  onPressed: () {
                    item = item.copyWith(isReference: !item.isReference);
                    setState(() {});
                  },
                  icon: Icon(
                      item.isReference
                          ? Icons.format_quote
                          : Icons.format_quote_outlined,
                      color: Colors.white)),
            if (_edit)
              IconButton(
                  icon: const Icon(Icons.calendar_month, color: Colors.white),
                  onPressed: () async {
                    final createDate = item.createDate == 0
                        ? DateTime.now()
                        : DateTime.fromMillisecondsSinceEpoch(item.createDate);
                    var date = await showDatePicker(
                        context: context,
                        firstDate:
                            createDate.subtract(const Duration(days: 300)),
                        lastDate: createDate.add(const Duration(days: 300)),
                        currentDate: createDate);
                    if (date != null) {
                      final time = await showTimePicker(
                          context: context, initialTime: TimeOfDay.now());
                      if (time != null) {
                        date = date.add(
                            Duration(hours: time.hour, minutes: time.minute));
                      }
                      item = item.copyWith(
                          createDate: date.millisecondsSinceEpoch);
                      setState(() {});
                    }
                  }),
            if (_edit)
              IconButton(
                  icon: Icon(_preview ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white),
                  onPressed: () {
                    item = extractMerge(item, _controller.text);
                    setState(() => _preview = !_preview);
                  }),
            IconButton(
                icon:
                    Icon(_edit ? Icons.save : Icons.edit, color: Colors.white),
                onPressed: () async {
                  if (_edit) {
                    item = extractMerge(item, _controller.text);
                    final res = await ref
                        .read(blocksDbProvider.notifier)
                        .addOrUpdate(item);
                    showSimpleMessage(context, content: res, useSnackBar: true);
                    _preview = false;
                  } else {
                    _controller.text = item.content;
                  }
                  setState(() => _edit = !_edit);
                }),
            IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () async {
                  final _ =
                      await ref.read(blocksDbProvider.notifier).delete(item.id);
                  Navigator.pop(context);
                }),
            const SizedBox(width: 10)
          ],
          backgroundColor: Colors.blueGrey,
          leading: const BackButton(color: Colors.white),
          flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 20, right: 0, bottom: 10),
              title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: const TextStyle(color: Colors.white, shadows: [
                          Shadow(
                              color: Colors.grey,
                              blurRadius: 7,
                              offset: Offset(1, 1))
                        ])),
                    Text(DateFormat("yy/M/d HH:mm").format(createDate),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 9))
                  ]),
              centerTitle: false,
              background:
                  Image.network(urlOfDate(createDate), fit: BoxFit.cover))),
      const SliverToBoxAdapter(child: SizedBox(height: 3)),
      SliverFillRemaining(
          child: _edit && !_preview
              ? Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                  child: TextField(
                    //autofocus: true,
                    expands: true,
                    controller: _controller,
                    decoration: const InputDecoration(border: InputBorder.none),
                    maxLines: null,
                  ))
              : Markdown(selectable: true, data: item.content))
    ]));
  }
}
