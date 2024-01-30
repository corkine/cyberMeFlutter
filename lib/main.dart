import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:window_manager/window_manager.dart';
import 'util.dart';
import 'pocket/config.dart';
import 'pocket/main.dart';
import 'pocket/menu.dart';

final appThemeData = ThemeData(useMaterial3: true, brightness: Brightness.dark);

class MinListener extends WindowListener {
  @override
  void onWindowMinimize() {
    appWindow.hide();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  config = await Config().init();
  await initializeDateFormatting();
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS)) {
    await initSystemTray();
    await windowManager.ensureInitialized();
    windowManager.waitUntilReadyToShow(
        const WindowOptions(size: Size(400, 700)), () async {
      await windowManager.show();
      await windowManager.focus();
    });
    windowManager.addListener(MinListener());
  }
  runApp(ProviderScope(
      child: MaterialApp(
          title: 'CyberMe',
          debugShowCheckedModeBanner: Platform.isWindows ? false : true,
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
