import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clipboard/clipboard.dart';
import 'package:cyberme_flutter/pocket/viewmodels/tray.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';
import 'package:system_tray/system_tray.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:http/http.dart' as http;
import 'package:pasteboard/pasteboard.dart' as pb;
import 'package:window_manager/window_manager.dart';

import 'pocket/main.dart';

class Util {
  /// 返回常用的时间信息
  static String clock(
      {bool justDate = false,
      bool justSeconds = false,
      bool justBeforeSeconds = false}) {
    var now = DateTime.now().toLocal();
    if (justDate) {
      return sprintf("%04d-%02d-%02d", [now.year, now.month, now.day]);
    } else if (justSeconds) {
      return sprintf("%02d", [now.second]);
    } else if (justBeforeSeconds) {
      return sprintf("%02d-%02d-%02d %02d:%02d:",
          [now.year, now.month, now.day, now.hour, now.minute]);
    } else {
      return sprintf("%02d-%02d-%02d %02d:%02d",
          [now.year, now.month, now.day, now.hour, now.minute]);
    }
  }

  /// 采样时间为上午，则不显示采样信息，采样时间为下午才显示采样信息
  static String? pickTime() {
    var now = DateTime.now().toLocal();

    /// 暂时不显示 核酸已采样 字样
    // ignore: dead_code
    if (false && now.hour >= 12) {
      return clock(justDate: true);
    } else {
      return null;
    }
  }

  static Widget waiting = const Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
        CircularProgressIndicator(),
        Padding(
          padding: EdgeInsets.all(18.0),
          child: Text('正在检索数据'),
        )
      ]));

  static const pt10 = Padding(padding: EdgeInsets.only(top: 10));
  static const pt20 = Padding(padding: EdgeInsets.only(top: 20));
  static const pt30 = Padding(padding: EdgeInsets.only(top: 30));
  static const pl10 = Padding(padding: EdgeInsets.only(left: 10));
  static const Padding pl20 = Padding(padding: EdgeInsets.only(left: 20));
  static const pl30 = Padding(padding: EdgeInsets.only(left: 30));
  static const Padding pa10 = Padding(padding: EdgeInsets.all(10));
  static const pa20 = Padding(padding: EdgeInsets.all(20));
  static const Padding pa30 = Padding(padding: EdgeInsets.all(30));
}

late AppWindow appWindow;
bool appHide = false;
bool dockedOnWindows = true;
final SystemTray systemTray = SystemTray();
StreamController<String>? routeStream;

String icoPath = Platform.isWindows
    ? 'images/tray/app_icon.ico'
    : 'images/tray/app_icon.png';

String checkPath = Platform.isWindows
    ? 'images/tray/app_icon_check.ico'
    : 'images/tray/app_icon_check.png';

Future<void> initSystemTray() async {
  appWindow = AppWindow();

  await systemTray.initSystemTray(iconPath: icoPath);

  final customItems = await TraySettings.readTraySettings();

  final Menu menu = Menu();
  await menu.buildFrom([
    ...apps.entries
        .where((element) => (element.value["addToContext"] as bool?) ?? true)
        .map((e) {
      final url = "/app/${e.key}";
      final name = e.value["name"] as String;
      return MenuItemLabel(
          label: name,
          onClicked: (_) {
            if (appHide) {
              appHide = false;
              appWindow.show();
            }
            routeStream?.sink.add(url);
          });
    }),
    MenuSeparator(),
    MenuItemLabel(
        label: '剪贴板图片上传',
        onClicked: (menuItem) => readClipboardAndUploadImage()),
    ...customItems
        .map((item) => MenuItemLabel(
            label: item.name,
            onClicked: (menuItem) {
              if (item.isSink) {
                if (appHide) {
                  appHide = false;
                  appWindow.show();
                }
                routeStream?.sink.add(item.url);
              } else {
                launchUrlString(item.url);
              }
            }))
        .toList(),
    MenuSeparator(),
    MenuItemLabel(
        label: '更改点按动作',
        onClicked: (a) {
          final nextAction =
              (clickAction.index + 1) % ClickAction.values.length;
          registerClickAction(ClickAction.values[nextAction]);
        }),
    MenuItemLabel(
        label: '显示',
        onClicked: (_) {
          appHide = false;
          appWindow.show();
        }),
    MenuItemLabel(
        label: '隐藏',
        onClicked: (_) {
          appHide = true;
          appWindow.hide();
        }),
    MenuItemLabel(label: '退出', onClicked: (_) => windowManager.close())
  ]);

  // set context menu
  await systemTray.setContextMenu(menu);

  // handle system tray event
  registerClickAction(ClickAction.showHideApp);

  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
      WindowOptions(
          size: dockedOnWindows ? const Size(350, 600) : const Size(400, 700)),
      () async {
    if (dockedOnWindows) {
      //await windowManager.setAsFrameless();
      await windowManager.setAlignment(
          Platform.isWindows ? Alignment.bottomLeft : Alignment.topLeft);
    }
    await windowManager.show();
    await windowManager.focus();
    windowManager.addListener(MinListener());
  });
}

enum ClickAction {
  showHideApp(desc: "显示/隐藏应用程序"),
  copyPasteWord(desc: "复制剪贴板内容并格式化"),
  uploadImage(desc: "上传剪贴板图片到图床");

  const ClickAction({required this.desc});

  final String desc;
}

var clickAction = ClickAction.showHideApp;

void registerClickAction(ClickAction action) {
  debugPrint("register click action: $action");
  clickAction = action;
  systemTray.setToolTip("点按${action.desc}");
  systemTray.registerSystemTrayEventHandler((eventName) {
    if (eventName == kSystemTrayEventClick) {
      switch (action) {
        case ClickAction.showHideApp:
          if (appHide) {
            appHide = false;
            appWindow.show();
          } else {
            appHide = true;
            appWindow.hide();
          }
          break;
        case ClickAction.copyPasteWord:
          debugPrint("copy paste word");
          replaceCopyFormat();
          break;
        case ClickAction.uploadImage:
          debugPrint("upload image action call");
          readClipboardAndUploadImage();
          break;
      }
    } else if (eventName == kSystemTrayEventRightClick) {
      systemTray.popUpContextMenu();
    }
  });
}

void runScript(String scriptPath) async {
  var s = scriptPath.split(Platform.pathSeparator);
  s.removeLast();
  Process.run("cmd", ["/c", "start", "cmd.exe", "/k", scriptPath],
      environment: {}, workingDirectory: s.join(Platform.pathSeparator));
}

Future<void> flashIcon() async {
  systemTray.setImage(checkPath);
  await Future.delayed(const Duration(milliseconds: 1000));
  systemTray.setImage(icoPath);
}

void replaceCopyFormat() async {
  var words = await pb.Pasteboard.text;
  if (words != null && words.isNotEmpty) {
    final n = words.replaceAll("\r", "").replaceAll("\n", "");
    final res = await FlutterClipboard.controlC(n);
    if (res) {
      await flashIcon();
    }
  }
}

void readClipboardAndUploadImage() async {
  //read clipboard's image
  var files = await pb.Pasteboard.files();
  if (files.isNotEmpty &&
      (files.first.endsWith(".png") ||
          files.first.endsWith(".jpg") ||
          files.first.endsWith(".bmp") ||
          files.first.endsWith(".jpeg") ||
          files.first.endsWith(".gif"))) {
    debugPrint("handling image... ${files.first}");
    var uri = Uri.parse(
        "https://cyber.mazhangjing.com/api/files/upload?secret=i_am_cool");
    var req = http.MultipartRequest('POST', uri);
    req.files.add(await http.MultipartFile.fromPath('file', files.first));
    var response = await http.Response.fromStream(await req.send());
    var body = jsonDecode(response.body);
    debugPrint(body.toString());
    var url = body["data"] as String;
    FlutterClipboard.copy(url);
    await flashIcon();
  }
}

class MinListener extends WindowListener {
  @override
  void onWindowMinimize() {
    appHide = true;
    appWindow.hide();
  }
}

void installWindowsRouteStream(BuildContext context) {
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS)) {
    if (routeStream == null) {
      routeStream = StreamController();
      routeStream?.stream.listen((event) {
        final uri = Uri.parse(event);
        final path = uri.path;
        final queryParams = uri.queryParameters;

        debugPrint("Go to $path with params: $queryParams");

        Navigator.of(context).popUntil(ModalRoute.withName('/menu'));
        Navigator.of(context).pushNamed(
          path,
          arguments: queryParams.isNotEmpty ? queryParams : null,
        );
      });
    }
  }
}

void distoryWindowsRouteStream() {
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS)) {
    debugPrint("Disposing Windows routeStream");
    routeStream?.close();
    routeStream = null;
  }
}
