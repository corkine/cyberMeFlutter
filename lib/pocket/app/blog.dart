import 'package:cyberme_flutter/api/blog.dart';
import 'package:cyberme_flutter/pocket/app/statistics.dart';
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
      final blogList = ListView.builder(
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
              onTap: () => launchUrlString(blogs![i].url)));
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
                onChanged: (value) {
                  setState(() {});
                },
                onSuffixTap: () {
                  search.clear();
                  setState(() {});
                }))
      ]));
    }
    return Theme(
      data: themeData,
      child: Scaffold(
          appBar: AppBar(
              title: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Blogs Feed'),
                    Text('www.mazhangjing.com/blog',
                        style: TextStyle(fontSize: 10, fontFamily: "mono"))
                  ]),
              actions: [
                IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () =>
                        launchUrlString("https://www.mazhangjing.com/blogs"))
              ]),
          body: content),
    );
  }
}
