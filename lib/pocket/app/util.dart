import 'package:cyberme_flutter/main.dart';
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

showWaitingBar(BuildContext context,
    {String text = "正在刷新", Future Function()? func}) async {
  ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
      content: Row(children: [
        const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator.adaptive(strokeWidth: 2)),
        const SizedBox(width: 10),
        Text(text)
      ]),
      actions: const [SizedBox()]));
  if (func != null) {
    try {
      await func();
    } catch (_) {}
    ScaffoldMessenger.of(context).clearMaterialBanners();
  }
}

Future<bool> showSimpleMessage(BuildContext context,
    {String? title, required String content, bool withPopFirst = false}) async {
  if (withPopFirst) {
    Navigator.of(context).pop();
  }
  return await showDialog<bool>(
          context: context,
          builder: (context) => Theme(
                data: appThemeData,
                child: AlertDialog(
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
                ),
              )) ??
      false;
}
