import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'main.dart';

class MenuView extends StatefulWidget {
  const MenuView({super.key});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  @override
  Widget build(BuildContext context) {
    final appsGrid = GridView(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 280, childAspectRatio: 3),
        children: apps.entries
            .where((element) => (element.value["addToMenu"] as bool?) ?? false)
            .map((e) => ListTile(
                visualDensity: VisualDensity.compact,
                onTap: () {
                  if ((e.value["replace"] as bool?) ?? false) {
                    Navigator.of(context).pushReplacementNamed("/app/${e.key}");
                  } else {
                    Navigator.of(context).pushNamed("/app/${e.key}");
                  }
                },
                leading: Icon((e.value["icon"] as IconData?) ?? Icons.apps),
                title: Text(e.value["name"] as String),
                subtitle: Text(e.key)))
            .toList(growable: false));
    var actionBar = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      TextButton(
          onPressed: () => SystemNavigator.pop(animated: true),
          child: const Text("退出 Flutter")),
      TextButton(onPressed: () => exit(0), child: const Text("退出 App"))
    ]);
    return Scaffold(
        backgroundColor: Colors.white,
        body: Stack(children: [
          Positioned.fill(
              child: Opacity(
                  opacity: 0.3,
                  child: Image.asset("images/app_bg.jpg", fit: BoxFit.cover))),
          SafeArea(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                Expanded(child: appsGrid),
                Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: actionBar)
              ]))
        ]));
  }
}
