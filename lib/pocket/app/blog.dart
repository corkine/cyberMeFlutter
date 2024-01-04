import 'package:cyberme_flutter/api/blog.dart';
import 'package:cyberme_flutter/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

class BlogView extends ConsumerStatefulWidget {
  const BlogView({super.key});

  @override
  ConsumerState<BlogView> createState() => _BlogViewState();
}

class _BlogViewState extends ConsumerState<BlogView> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var blogs = ref.watch(fetchBlogsProvider).value;
    Widget content;
    if (blogs == null) {
      content = const Center(child: CupertinoActivityIndicator());
    } else {
      final searchText = search.text.toUpperCase();
      blogs = blogs.where((e) {
        if (searchText.isEmpty) return true;
        return e.title.toUpperCase().contains(searchText) ||
            e.summary.toUpperCase().contains(searchText);
      }).toList();
      final blogList = AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: blogs.isEmpty ? 0 : 1,
        child: ListView.builder(
            itemCount: blogs.length,
            itemBuilder: (c, i) => ListTile(
                title: Text(blogs![i].title),
                subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(blogs[i].summary,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                          (blogs[i].author?.name ?? "") +
                              " @ " +
                              blogs[i].date_modified.substring(0, 10),
                          style: const TextStyle(fontSize: 12))
                    ]),
                onTap: () => launchUrlString(blogs![i].url))),
      );
      content = SafeArea(
          child: Column(children: [
        Expanded(
            child: RefreshIndicator(
                onRefresh: () async =>
                    await ref.refresh(fetchBlogsProvider.future),
                child: blogList)),
        Padding(
            padding: const EdgeInsets.all(8.0),
            child: CupertinoSearchTextField(
                style: const TextStyle(color: Colors.white),
                controller: search,
                onChanged: (value) => setState(() {}),
                onSuffixTap: () => setState(() => search.clear())))
      ]));
    }
    return Theme(
        data: appThemeData,
        child: Scaffold(
            appBar: AppBar(
                title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(search.text == "案例" ? '案例' : '博客'),
                      Text(
                          search.text == "案例"
                              ? 'www.mazhangjing.com/cases'
                              : 'www.mazhangjing.com/blog',
                          style:
                              const TextStyle(fontSize: 10, fontFamily: "mono"))
                    ]),
                actions: [
                  IconButton(
                      icon: Icon(search.text == "案例"
                          ? Icons.bookmark
                          : Icons.bookmark_border),
                      onPressed: () {
                        if (search.text == "案例") {
                          search.text = "";
                        } else {
                          search.text = "案例";
                        }
                        setState(() {});
                      }),
                  IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () =>
                          launchUrlString("https://www.mazhangjing.com/blogs"))
                ]),
            body: content));
  }
}
