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
        backgroundColor:
            MediaQuery.of(context).platformBrightness == Brightness.dark
                ? const Color(0xff2c2c2c)
                : const Color(0xffffffff),
        body: support
            ? Stack(children: [
                SafeArea(
                  top: true,
                  bottom: false,
                  child: InAppWebView(
                      initialUrlRequest: URLRequest(url: Uri.parse(url))),
                ),
                Positioned(
                    right: 10,
                    top: 50,
                    child: IconButton(
                        color: MediaQuery.of(context).platformBrightness ==
                                Brightness.dark
                            ? Colors.white.withOpacity(0.3)
                            : Colors.black26,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close)))
              ])
            : Center(
                child: TextButton(
                    child: const Text("Open In Web Browser"),
                    onPressed: () => Navigator.of(context).pop())));
  }
}
