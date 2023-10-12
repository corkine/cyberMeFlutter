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
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("Flutter Apps"),
        ),
        body: SafeArea(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
              Expanded(
                child: SingleChildScrollView(
                    child: Column(
                        children: apps.entries
                            .where((element) =>
                                (element.value["addToMenu"] as bool?) ?? false)
                            .map((e) => ListTile(
                                visualDensity: VisualDensity.compact,
                                onTap: () {
                                  if ((e.value["replace"] as bool?) ?? false) {
                                    Navigator.of(context)
                                        .pushReplacementNamed("/app/${e.key}");
                                  } else {
                                    Navigator.of(context)
                                        .pushNamed("/app/${e.key}");
                                  }
                                },
                                leading: Icon((e.value["icon"] as IconData?) ??
                                    Icons.apps),
                                title: Text(e.value["name"] as String),
                                subtitle: Text(e.key)))
                            .toList(growable: false))),
              ),
              Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                            onPressed: () =>
                                SystemNavigator.pop(animated: true),
                            child: const Text("退出 Flutter")),
                        TextButton(
                            onPressed: () => exit(0),
                            child: const Text("退出 App"))
                      ]))
            ])));
  }
}
