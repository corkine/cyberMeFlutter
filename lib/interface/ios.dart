import 'package:flutter/material.dart';
import 'package:cyberme_flutter/pocket/main.dart';

/// use flutterEngine.run(withEntrypoint: "iosEntryPoint",
///   libraryURI: "interface/ios.dart",
///   initialRoute: "/xxx") to use this entryPoint, default is FlutterDefaultDartEntrypoint
/// initialRoute can also define with FlutterViewController
/// FlutterViewController(project: nil, initialRoute: "/xxx", engine: xx, nibName: nil, bundle: nil)
/// call FlutterViewController#pop/pushRoute to routing
/// call SystemNavigator.pop() but not exit() to exit dart vm
@pragma("vm:entry-point")
void iosEntryPoint() {
  runApp(CMPocket.call());
}