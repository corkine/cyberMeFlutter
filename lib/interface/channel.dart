import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class NativePlatform {
  static const String _channelName = 'flutter/nativeSimpleChannel';
  static const MethodChannel _channel = MethodChannel(_channelName);

  static Future<String?> getPlatformVersion() async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static void setLastUsedAppRoute(String appName, String appRoute) {
    if (Platform.isIOS) {
      _channel.invokeMethod('setLastUsedAppRoute',
          <String, String>{"name": appName, "route": appRoute});
    }
  }
}
