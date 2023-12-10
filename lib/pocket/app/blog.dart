import 'package:cyberme_flutter/api/blog.dart';
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
  @override
  Widget build(BuildContext context) {
    final blogs = ref.watch(fetchBlogsProvider).value;
    Widget content;
    if (blogs == null) {
      content = const Center(child: CupertinoActivityIndicator());
    } else {
      content = RefreshIndicator(
        onRefresh: () async {
          final _ = await ref.refresh(fetchBlogsProvider.future);
        },
        child: ListView.builder(
            itemCount: blogs.length,
            itemBuilder: (c, i) => ListTile(
                title: Text(blogs[i].title),
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
                onTap: () {
                  launchUrlString(blogs[i].url);
                })),
      );
    }
    return Scaffold(
        appBar: AppBar(
            title: const Column(children: [
          Text('Blogs Feed'),
          Text('blogs.mazhangjing.com',
              style: TextStyle(fontSize: 10, fontFamily: "mono"))
        ])),
        body: content);
  }
}
