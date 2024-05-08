import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cyberme_flutter/api/story.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart';
import '../config.dart';

Map<String, String> cover = {
  "格林童话": "https://static2.mazhangjing.com/cyber/202310/753d1738_图片.png",
  "伊索寓言": "https://static2.mazhangjing.com/cyber/202310/51472203_图片.png",
  "一千零一夜": "https://static2.mazhangjing.com/cyber/202310/4ab8d597_图片.png",
  "黑塞童话": "https://static2.mazhangjing.com/cyber/202310/f31ac1f5_图片.png",
  "王尔德童话": "https://static2.mazhangjing.com/cyber/202310/627f2f86_图片.png",
  "笨狼的故事": "https://static2.mazhangjing.com/cyber/202310/efde917f_图片.png",
  "安徒生童话": "https://static2.mazhangjing.com/cyber/202310/efbd86c8_图片.png",
  "佩罗童话": "https://static2.mazhangjing.com/cyber/202405/6c3de10b_image.png",
  "恰佩克童话": "https://static2.mazhangjing.com/cyber/202405/1ab939ee_image.png",
  "罗尔德童话": "https://static2.mazhangjing.com/cyber/202405/b081a67c_image.png",
  "欧亨利短篇小说选": "https://static2.mazhangjing.com/cyber/202405/cf9d091c_image.png",
  "阿瑟克拉克科幻小说选": "https://static2.mazhangjing.com/cyber/202310/d4461685_图片.png",
  "银河系边缘的小失常": "https://static2.mazhangjing.com/cyber/202310/dc840e21_图片.png",
  "伟大的短篇小说们": "https://static2.mazhangjing.com/cyber/202310/d6c77430_图片.png",
  "日本民间童话故事": "https://static2.mazhangjing.com/cyber/202405/f8ef4c95_image.png"
};

String defaultCover =
    "https://static2.mazhangjing.com/cyber/202310/70b6426c_图片.png";

class StoryView extends StatefulWidget {
  const StoryView({super.key});

  @override
  State<StoryView> createState() => _StoryViewState();
}

class _StoryViewState extends State<StoryView> {
  List<(String, List<String>)> model = [];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      handleLoadBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
            title: const Text("故事社"),
            centerTitle: true,
            foregroundColor: Colors.white,
            backgroundColor: Colors.black12,
            actions: [
              Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: IconButton(
                      onPressed: () => showSearch(
                          context: context, delegate: StorySearchDelegate()),
                      icon: const Icon(Icons.search)))
            ]),
        body: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: RefreshIndicator(
              onRefresh: () async => await handleLoadBooks(),
              child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 180, childAspectRatio: 0.7),
                  itemBuilder: (c, i) {
                    final s = model[i];
                    return InkWell(
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (c) => BookStoryView(
                                    bookName: s.$1, storyNames: s.$2))),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: SizedBox(
                                      width: 100,
                                      height: 150,
                                      child: CachedNetworkImage(
                                          imageUrl: cover[s.$1] ?? defaultCover,
                                          fit: BoxFit.cover))),
                              const SizedBox(height: 5),
                              Text(s.$1,
                                  overflow: TextOverflow.fade, softWrap: false)
                            ]));
                  },
                  itemCount: model.length)),
        ));
  }

  ListView buildBookList(BuildContext context) {
    return ListView.builder(
        itemBuilder: (c, i) {
          final s = model[i];
          return ListTile(
              title: Text(s.$1),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (c) =>
                      BookStoryView(bookName: s.$1, storyNames: s.$2))));
        },
        itemCount: model.length);
  }

  Future handleLoadBooks() async {
    final r = await get(Uri.parse(Config.storyListUrl),
        headers: config.cyberBase64Header);
    final j = jsonDecode(r.body);
    final s = (j["status"] as int?) ?? -1;
    final m = j["message"] ?? "没有返回消息";
    final d = (j["data"] as List?) ?? [];
    if (s <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
      return;
    }
    model = d
        .map((e) => e as Map)
        .map((e) => (
              e["name"] as String,
              (e["stories"] as List)
                  .map((e) => e.toString())
                  .toList(growable: false)
            ))
        .toList(growable: false);
    setState(() {});
  }
}

class BookStoryView extends ConsumerStatefulWidget {
  final String bookName;
  final List<String> storyNames;

  const BookStoryView(
      {super.key, required this.bookName, required this.storyNames});

  @override
  ConsumerState<BookStoryView> createState() => _BookStoryViewState();
}

class _BookStoryViewState extends ConsumerState<BookStoryView> {
  Map<String, int> refer = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final items =
        ref.watch(bookInfosProvider.call(widget.bookName)).value ?? BookItems();
    return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          Positioned.fill(
              child: CachedNetworkImage(
                  fit: BoxFit.cover,
                  imageUrl: cover[widget.bookName] ?? defaultCover)),
          Positioned.fill(child: Container(color: Colors.black54)),
          SafeArea(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                TapRegion(
                    onTapInside: (_) => Navigator.of(context).pop(),
                    child: Padding(
                        padding: const EdgeInsets.only(
                            left: 16, top: 20, bottom: 0, right: 20),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(widget.bookName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(color: Colors.white)),
                                    Text("${widget.storyNames.length} 篇",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.white))
                                  ]),
                              const Spacer(),
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: SizedBox(
                                      width: 50,
                                      child: CachedNetworkImage(
                                          fit: BoxFit.cover,
                                          imageUrl: cover[widget.bookName] ??
                                              defaultCover)))
                            ]))),
                Expanded(
                    child: Material(
                        color: Colors.transparent,
                        child: ListView.builder(
                            itemExtent: 50,
                            itemBuilder: (c, i) => i >= items.items.length
                                ? const SizedBox()
                                : buildStoryItem(items.items[i], context, i),
                            itemCount: items.items.length + 2)))
              ])),
          if (items.lastRead != null)
            Positioned(
                bottom: 5,
                left: 5,
                right: 5,
                child: SafeArea(
                    bottom: true, child: buildReadLastBar(context, items)))
        ]));
  }

  InkWell buildReadLastBar(BuildContext context, BookItems items) {
    final lastReadName = items.lastRead!.name;
    final lastReadIndex = items.lastRead!.index;
    BookItem? lastRead =
        items.items.firstWhere((element) => element.name == lastReadName);
    return InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (c) => StoryReadView(
                bookName: widget.bookName,
                storyName: lastReadName,
                lastReadIndex: lastReadIndex))),
        child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10), color: Colors.black87),
            padding:
                const EdgeInsets.only(left: 15, right: 15, bottom: 10, top: 10),
            child: Row(children: [
              buildAddFavoriateMark(lastRead),
              const SizedBox(width: 5),
              Expanded(
                  child: Text(lastReadName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white))),
              Container(
                  margin: const EdgeInsets.only(left: 5),
                  padding: const EdgeInsets.only(
                      left: 10, right: 10, top: 5, bottom: 5),
                  decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text("继续阅读",
                      style: TextStyle(fontSize: 12, color: Colors.white)))
            ])));
  }

  Widget buildStoryItem(BookItem item, BuildContext context, int i) {
    return InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (c) => StoryReadView(
                bookName: widget.bookName, storyName: item.name))),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FittedBox(
                                child: Text(item.name,
                                    style: const TextStyle(
                                        fontSize: 15, color: Colors.white))),
                            Text(item.count == 0 ? "" : "${item.count} 字",
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 10))
                          ]))),
              Padding(
                  padding: const EdgeInsets.only(left: 3, right: 18),
                  child: buildAddFavoriateMark(item))
            ]));
  }

  InkResponse buildAddFavoriateMark(BookItem item) {
    return InkResponse(
        onTap: () async => await ref
            .read(storyConfigsProvider.notifier)
            .setWillRead(widget.bookName, item.name, !item.willRead),
        child: item.willRead
            ? const Icon(Icons.bookmark, color: Colors.orangeAccent)
            : item.isReaded
                ? const Icon(Icons.bookmark_border, color: Colors.green)
                : const Icon(Icons.bookmark_add_outlined,
                    color: Colors.white24));
  }
}

/// 故事阅读界面，进入时保存最后阅读，退出后保存阅读进度
class StoryReadView extends ConsumerStatefulWidget {
  final String bookName;
  final String storyName;
  final double lastReadIndex;

  const StoryReadView(
      {super.key,
      required this.bookName,
      required this.storyName,
      this.lastReadIndex = 0});

  @override
  ConsumerState<StoryReadView> createState() => _StoryReadViewState();
}

class _StoryReadViewState extends ConsumerState<StoryReadView> {
  List<String> content = [];
  int enterTime = 0;
  final controller = ScrollController();
  late StoryConfigs storyConfig;
  double offset = 0;
  bool isReaded = false;

  @override
  void initState() {
    super.initState();
    enterTime = DateTime.now().millisecondsSinceEpoch;
    Future.delayed(Duration.zero, () async {
      await handleLoadStory();
      storyConfig = ref.read(storyConfigsProvider.notifier);
      controller.animateTo(widget.lastReadIndex,
          duration: const Duration(milliseconds: 500), curve: Curves.ease);
      controller.addListener(() => offset = controller.offset);
    });
  }

  @override
  void dispose() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final data = LastReadStory(
        enter: enterTime, exit: now, name: widget.storyName, index: offset);
    if (!isReaded) {
      storyConfig.setLastRead(widget.bookName, data);
    } else {
      storyConfig.removeLastRead(widget.bookName);
    }
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sc = ref.watch(storyConfigsProvider).value ?? StoryConfig();
    final willRead = StoryConfigs.isWillRead(
        sc.willReadStory, widget.bookName, widget.storyName);
    isReaded = sc.readedStory
        .contains(StoryConfigs.readKey(widget.bookName, widget.storyName));
    return Scaffold(
        backgroundColor: Colors.black,
        body: CustomScrollView(controller: controller, slivers: [
          SliverAppBar(
              stretch: true,
              title: Text(widget.storyName),
              leading: const BackButton(color: Colors.white38),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: IconButton(
                      icon: willRead
                          ? const Icon(Icons.bookmark,
                              color: Colors.orangeAccent)
                          : const Icon(Icons.bookmark_add_outlined,
                              color: Colors.white30),
                      onPressed: () async => await storyConfig.setWillRead(
                          widget.bookName, widget.storyName, !willRead)),
                )
              ],
              expandedHeight: 350,
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: true,
              flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(bottom: 15),
                  background:
                      Image.asset("images/app_bg.jpg", fit: BoxFit.cover))),
          const SliverPadding(padding: EdgeInsets.only(top: 15)),
          SliverList.builder(
              itemCount: content.length,
              itemBuilder: (c, i) {
                return Padding(
                    padding:
                        const EdgeInsets.only(left: 15, right: 5, bottom: 10),
                    child: Text(content[i],
                        style: const TextStyle(
                            fontSize: 16,
                            letterSpacing: 1,
                            color: Colors.white70)));
              }),
          if (content.isNotEmpty)
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextButton(
                        style: ButtonStyle(backgroundColor:
                            MaterialStateProperty.resolveWith((states) {
                          if (states.contains(MaterialState.pressed)) {
                            return const Color.fromARGB(62, 76, 175, 79);
                          } else if (states.contains(MaterialState.hovered)) {
                            return const Color.fromARGB(24, 76, 175, 79);
                          } else {
                            return Colors.transparent;
                          }
                        })),
                        onPressed: () async => await ref
                            .read(storyConfigsProvider.notifier)
                            .setReaded(widget.bookName, widget.storyName,
                                read: !isReaded),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              isReaded
                                  ? const Icon(Icons.done_all,
                                      color: Colors.green)
                                  : const Icon(Icons.done,
                                      color: Color.fromARGB(166, 76, 175, 79)),
                              const SizedBox(width: 8),
                              Text(isReaded ? "故事已读" : "标记为已读",
                                  style: const TextStyle(color: Colors.green))
                            ])))),
          const SliverPadding(padding: EdgeInsets.only(bottom: 15))
        ]));
  }

  Future handleLoadStory() async {
    final r = await get(
        Uri.parse(Config.storyReadUrl(widget.bookName, widget.storyName)),
        headers: config.cyberBase64Header);
    final j = jsonDecode(r.body);
    final s = (j["status"] as int?) ?? -1;
    final m = j["message"] ?? "没有返回消息";
    final d = (j["data"] as Map?) ?? {};
    if (s <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
      return;
    }
    content = ((d["content"] as String?) ?? "没有内容")
        .replaceAll("\r", "")
        .split("\n")
        .where((element) => element.isNotEmpty)
        .toList(growable: false);
    setState(() {});
  }
}

class StorySearchDelegate extends SearchDelegate<String> {
  StorySearchDelegate()
      : super(
            searchFieldLabel: "搜索故事或内容",
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.search);

  @override
  Widget buildLeading(BuildContext context) => const BackButton();

  @override
  Widget buildSuggestions(BuildContext context) => const SizedBox();

  @override
  Widget buildResults(BuildContext context) => StorySearchResultView(query);

  @override
  List<Widget> buildActions(BuildContext context) => <Widget>[
        Padding(
            padding: const EdgeInsets.only(right: 0),
            child: IconButton(
                onPressed: () => query = "", icon: const Icon(Icons.clear))),
        Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
                onPressed: () => showResults(context),
                icon: const Icon(Icons.search)))
      ];
}

class StorySearchResultView extends ConsumerStatefulWidget {
  final String query;
  const StorySearchResultView(this.query, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _StorySearchResultViewState();
}

class _StorySearchResultViewState extends ConsumerState<StorySearchResultView> {
  @override
  Widget build(BuildContext context) {
    final res = ref.watch(searchStoryProvider.call(widget.query)).value;
    if (res == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
        color: Colors.white,
        child: ListView.builder(
            itemCount: res.result.length,
            itemBuilder: (c, i) {
              final item = res.result[i];
              return ListTile(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => StoryReadView(
                            bookName: item.book, storyName: item.story)));
                  },
                  title: Text("${item.book} / ${item.story}"),
                  subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: item.content
                          .map((e) => Text(e,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)))
                          .toList()));
            }));
  }
}
