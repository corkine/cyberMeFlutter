import 'package:flutter/material.dart';

String expiredAt(int timeSeconds) {
  final _expired = DateTime.fromMillisecondsSinceEpoch(timeSeconds * 1000);
  return '${_expired.year}-${_expired.month.toString().padLeft(2, '0')}-${_expired.day.toString().padLeft(2, '0')}';
}

String expiredFormat(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

DateTime expiredTo(int timeSeconds) =>
    DateTime.fromMillisecondsSinceEpoch(timeSeconds * 1000);

int expiredFrom(DateTime date) => date.millisecondsSinceEpoch ~/ 1000;

Future<bool> confirm(BuildContext context, String note) async {
  final res = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                  title: const Text("警告"),
                  content: Text(note),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text("取消")),
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text("确定"))
                  ])) ??
      false;
  return res;
}
