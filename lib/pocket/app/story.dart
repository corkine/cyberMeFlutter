import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import '../config.dart';

class StoryView extends StatefulWidget {
  const StoryView({super.key});

  @override
  State<StoryView> createState() => _StoryViewState();
}

class _StoryViewState extends State<StoryView> {
  late Config config;

  List<(String, List<String>)> model = [];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      config = Provider.of<Config>(context, listen: false);
      handleLoadBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("故事社"), centerTitle: true),
        body: RefreshIndicator(
            onRefresh: () async => await handleLoadBooks(),
            child: ListView.builder(
                itemBuilder: (c, i) {
                  final s = model[i];
                  return ListTile(
                      title: Text(s.$1),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (c) => BookStoryView(
                              bookName: s.$1, storyNames: s.$2))));
                },
                itemCount: model.length)));
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
        appBar: AppBar(title: Text(widget.bookName), centerTitle: true),
        body: ListView.builder(
            itemBuilder: (c, i) {
              final s = widget.storyNames[i];
              return ListTile(
                  title: Text(s),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (c) => StoryReadView(
                          bookName: widget.bookName, storyName: s))));
            },
            itemCount: widget.storyNames.length));
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
  late Config config;

  List<String> content = [];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      config = Provider.of<Config>(context, listen: false);
      handleLoadStory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(widget.storyName), centerTitle: true),
        body: ListView.builder(
            itemBuilder: (c, i) {
              final s = content[i];
              return Padding(
                  padding:
                      const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                  child: Text("       " + s,
                      style: const TextStyle(fontSize: 15)));
            },
            itemCount: content.length));
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
    content = ((d["content"] as String?) ?? "没有内容").split("\n");
    setState(() {});
  }
}
