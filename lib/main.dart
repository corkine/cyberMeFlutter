import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pocket/config.dart';
import 'pocket/main.dart';
import 'pocket/menu.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await Config().init();
  runApp(ChangeNotifierProvider(
      create: (c) => config,
      child: MaterialApp(
          title: 'CyberMe',
          debugShowCheckedModeBanner: true,
          theme: ThemeData(useMaterial3: true),
          initialRoute: "/",
          routes: (apps.map((key, value) => MapEntry(
              "/app/$key", value["view"] as Widget Function(BuildContext))))
            ..addAll({
              "/": (c) => const PocketHome(),
              "/menu": (c) => const MenuView()
            }))));
}
