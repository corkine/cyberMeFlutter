import 'package:cyberme_flutter/pocket/viewmodels/basic.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'backup.freezed.dart';
part 'backup.g.dart';

@freezed
class BackupItem with _$BackupItem {
  factory BackupItem({
    @Default("") String name,
    @Default(0) int start,
    @Default(0) int end,
    @Default(0) double cost,
    @Default("") String host,
    @Default("") String result,
    @Default("") String from,
    @Default("") String id,
    @Default("") String log,
    @Default("") String message,
  }) = _BackupItem;

  factory BackupItem.fromJson(Map<String, dynamic> json) =>
      _$BackupItemFromJson(json);
}

@riverpod
List<BackupItem> backupFilter(BackupFilterRef ref, String server) {
  final backups = ref.watch(backupsProvider).value ?? [];
  if (server == "全部") return backups;
  return backups.where((b) => b.name == server).toList();
}

@riverpod
List<String> backupServer(BackupServerRef ref) {
  final backups = ref.watch(backupsProvider).value ?? [];
  return backups.map((b) => b.name).toSet().toList();
}

@riverpod
class Backups extends _$Backups {
  @override
  FutureOr<List<BackupItem>> build() async {
    final res = await requestFromList("/cyber/service/backup",
        (l) => l.map((e) => BackupItem.fromJson(e)).toList());
    if (res.$2.isNotEmpty) {
      debugPrint(res.$2);
    }
    return (res.$1 ?? [])..sort((b, a) => a.start.compareTo(b.start));
  }

  Future<String> delete(String id) async {
    final res = await deleteFrom("/cyber/service/backup", {"id": id});
    ref.invalidateSelf();
    return res.$2;
  }

  Future<String> append() async {
    final res = await postFrom("/cyber/service/backup", {
      "name": "test",
      "start": DateTime.now().millisecondsSinceEpoch,
      "end": DateTime.now()
          .add(const Duration(seconds: 102))
          .millisecondsSinceEpoch,
      "cost": 102.0,
      "result": "success",
      "message": "This is test message",
      "log": "This is test log",
      "host": "192.168.0.1",
      "from": "test.chchma.com"
    });
    debugPrint(res.toString());
    ref.invalidateSelf();
    return res.$2;
  }
}
