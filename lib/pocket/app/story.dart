import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
  "阿瑟克拉克科幻小说选": "https://static2.mazhangjing.com/cyber/202310/d4461685_图片.png",
  "银河系边缘的小失常": "https://static2.mazhangjing.com/cyber/202310/dc840e21_图片.png",
  "伟大的短篇小说们": "https://static2.mazhangjing.com/cyber/202310/d6c77430_图片.png"
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
        ),
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

class BookStoryView extends StatefulWidget {
  final String bookName;
  final List<String> storyNames;

  const BookStoryView(
      {super.key, required this.bookName, required this.storyNames});

  @override
  State<BookStoryView> createState() => _BookStoryViewState();
}

class _BookStoryViewState extends State<BookStoryView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          Positioned.fill(
              child: CachedNetworkImage(
                  fit: BoxFit.cover,
                  imageUrl: cover[widget.bookName] ?? defaultCover)),
          Positioned.fill(child: Container(color: Colors.black54)),
          SafeArea(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                  child: ListView.builder(
                      itemBuilder: (c, i) {
                        final s = widget.storyNames[i];
                        return ListTile(
                            title: Text(s,
                                style: const TextStyle(color: Colors.white)),
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (c) => StoryReadView(
                                        bookName: widget.bookName,
                                        storyName: s))));
                      },
                      itemCount: widget.storyNames.length))
            ]),
          )
        ]));
  }
}

class StoryReadView extends StatefulWidget {
  final String bookName;
  final String storyName;

  const StoryReadView(
      {super.key, required this.bookName, required this.storyName});

  @override
  State<StoryReadView> createState() => _StoryReadViewState();
}

class _StoryReadViewState extends State<StoryReadView> {
  List<String> content = [];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      handleLoadStory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: CustomScrollView(slivers: [
          SliverAppBar(
              stretch: true,
              title: Text(widget.storyName),
              leading: const BackButton(color: Colors.white38),
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
              })
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
