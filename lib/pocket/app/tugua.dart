import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher_string.dart';

class TuguaView extends StatefulWidget {
  const TuguaView({super.key});

  @override
  State<TuguaView> createState() => _TuguaViewState();
}

class _TuguaViewState extends State<TuguaView> {
  bool get support => Platform.isIOS || Platform.isAndroid;
  final url = "https://go.mazhangjing.com/news";

  @override
  void initState() {
    super.initState();
    if (!support) {
      launchUrlString(url).then((value) => Navigator.of(context).pop());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: support
            ? InAppWebView(initialUrlRequest: URLRequest(url: Uri.parse(url)))
            : Center(
                child: TextButton(
                    child: const Text("Open In Web Browser"),
                    onPressed: () => Navigator.of(context).pop())));
  }
}
