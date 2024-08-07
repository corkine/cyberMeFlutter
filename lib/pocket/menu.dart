import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cyberme_flutter/pocket/views/think/note.dart';
import 'package:cyberme_flutter/interface/channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../util.dart';
import 'main.dart';

class MenuView extends StatefulWidget {
  const MenuView({super.key});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  @override
  Widget build(BuildContext context) {
    // final appsGrid = GridView(
    //     gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
    //         maxCrossAxisExtent: 280, childAspectRatio: 3),
    //     children: apps.entries
    //         .where((element) => (element.value["addToMenu"] as bool?) ?? false)
    //         .map((e) => ListTile(
    //             visualDensity: VisualDensity.compact,
    //             onTap: () {
    //               if ((e.value["replace"] as bool?) ?? false) {
    //                 Navigator.of(context).pushReplacementNamed("/app/${e.key}");
    //               } else {
    //                 Navigator.of(context).pushNamed("/app/${e.key}");
    //               }
    //             },
    //             leading: Icon((e.value["icon"] as IconData?) ?? Icons.apps),
    //             title: Text(e.value["name"] as String),
    //             subtitle: Text(e.key)))
    //         .toList(growable: false));
    var actionBar = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      TextButton(
          onPressed: () => showModalBottomSheet(
              context: context, builder: (context) => const NoteView()),
          child: const Text("笔记")),
      TextButton(
          onPressed: () => SystemNavigator.pop(animated: true),
          child: const Text("退出 Flutter")),
      TextButton(onPressed: () => exit(0), child: const Text("退出 App"))
    ]);
    final now = DateTime.now();
    final today = "${now.year}-${now.month}-${now.day}";
    return Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(slivers: [
          SliverAppBar(
              stretch: true,
              title: const Text("Cyber Apps",
                  style: TextStyle(color: Colors.white)),
              flexibleSpace: Container(
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image: //AssetImage("images/app_bg.jpg"),
                              CachedNetworkImageProvider(
                                  "https://go.mazhangjing.com/bing-today-image?normal=true",
                                  cacheKey: "bing-today-image-$today"),
                          fit: BoxFit.cover)))),
          SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 280, childAspectRatio: 3),
              itemBuilder: (context, index) {
                final e = apps.entries
                    .where((element) =>
                        (element.value["addToMenu"] as bool?) ?? false)
                    .elementAt(index);
                return ListTile(
                    visualDensity: VisualDensity.compact,
                    onTap: () {
                      if ((e.value["replace"] as bool?) ?? false) {
                        Navigator.of(context)
                            .pushReplacementNamed("/app/${e.key}");
                      } else {
                        Navigator.of(context).pushNamed("/app/${e.key}");
                      }
                      NativePlatform.setLastUsedAppRoute(
                          e.value["name"] as String, "/app/${e.key}");
                    },
                    leading: Icon((e.value["icon"] as IconData?) ?? Icons.apps),
                    title: Text(e.value["name"] as String),
                    subtitle: Text(e.key));
              },
              itemCount: apps.entries
                  .where((element) =>
                      (element.value["addToMenu"] as bool?) ?? false)
                  .length),
          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
          SliverToBoxAdapter(child: actionBar),
          const SliverPadding(padding: EdgeInsets.only(bottom: 30))
        ]));
  }

  @override
  void initState() {
    super.initState();
    installWindowsRouteStream(context);
  }

  @override
  void dispose() {
    distoryWindowsRouteStream();
    super.dispose();
  }
}
