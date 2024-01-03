import 'package:flutter/material.dart';

showDebugBar(BuildContext context, dynamic e, {bool withPop = false}) {
  if (withPop) {
    Navigator.of(context).pop();
  }
  final sm = ScaffoldMessenger.of(context);
  sm.showMaterialBanner(MaterialBanner(
      content: GestureDetector(
          onTap: () => sm.clearMaterialBanners(),
          child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: Text(e.toString()))),
      actions: const [SizedBox()]));
}

showSimpleMessage(BuildContext context,
    {String? title, required String content, bool withPopFirst = false}) async {
  if (withPopFirst) {
    Navigator.of(context).pop();
  }
  await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
            title: Text(title ?? "提示"),
            content: Text(content),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("取消")),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("确定"))
            ],
          ));
}
