import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'pocket/config.dart';
import 'pocket/main.dart';
import 'pocket/menu.dart';

final appThemeData = ThemeData(useMaterial3: true, brightness: Brightness.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  config = await Config().init();
  debugPrint("now config is ${config.password}");
  runApp(ProviderScope(
      child: MaterialApp(
          title: 'CyberMe',
          debugShowCheckedModeBanner: true,
          theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
          initialRoute: "/",
          routes: (apps.map((key, value) => MapEntry("/app/$key", (c) {
                final f = value["view"] as Widget Function(BuildContext);
                //return Theme(data: appThemeData, child: f(c));
                return f(c);
              })))
            ..addAll({
              "/": (c) => const PocketHome(),
              "/menu": (c) => const MenuView(),
              //Theme(data: appThemeData, child: const MenuView())
            }))));
}
