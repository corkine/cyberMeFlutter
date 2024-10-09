import 'dart:convert';

import 'package:cyberme_flutter/pocket/config.dart';
import 'package:cyberme_flutter/pocket/viewmodels/backup.dart';
import 'package:cyberme_flutter/pocket/views/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../main.dart';

class BackupView extends ConsumerStatefulWidget {
  const BackupView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BackupViewState();
}

class _BackupViewState extends ConsumerState<BackupView> {
  late DateTime weekDayOne;
  late DateTime lastWeekDayOne;
  late DateTime today;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    today = DateTime(now.year, now.month, now.day);
    weekDayOne = getThisWeekMonday();
    lastWeekDayOne = weekDayOne.subtract(const Duration(days: 7));
  }

  String? selectServer;

  List<String> servers = [];
  List<BackupItem> data = [];

  void _showDialog() {
    // Navigator.of(context).push(MaterialPageRoute(
    //     builder: (context) => Scaffold(
    //         appBar: AppBar(title: const Text("View")),
    //         body: const BackupCalView())));
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => SizedBox(
            height: MediaQuery.of(context).size.height / 1.3,
            child: BackupCalView(selectServer)));
  }

  @override
  Widget build(BuildContext context) {
    servers = ["全部", ...ref.watch(backupServerProvider)];
    if (selectServer == null && servers.isNotEmpty) {
      selectServer = servers.first;
    }
    data = ref.watch(backupFilterProvider.call(selectServer ?? ""));
    return Scaffold(
        appBar: AppBar(title: const Text("Backups"), actions: [
          IconButton(
              onPressed: () async {
                final pass = TextEditingController();
                var expiredDay = 10;
                final passUserPassed = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                            title: const Text("Enter password"),
                            content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                      controller: pass,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                          hintText: "Password")),
                                  DropdownButton(
                                      onChanged: (e) {
                                        expiredDay = e!;
                                      },
                                      value: expiredDay,
                                      items: List.generate(
                                              12,
                                              (index) =>
                                                  (index + 1) * expiredDay)
                                          .map((e) => DropdownMenuItem(
                                                value: e,
                                                child: Text(
                                                    e.toString() + " days"),
                                              ))
                                          .toList())
                                ]),
                            actions: [
                              TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(pass.text);
                                  },
                                  child: const Text("OK"))
                            ]));
                if (passUserPassed != null && passUserPassed.isNotEmpty) {
                  final res = encryptPassword(
                      passUserPassed, 60 * 60 * 24 * expiredDay);
                  showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                              title: const Text("密钥已生成"),
                              content: Text("您的密钥已生成，过期时间为" +
                                  expiredDay.toString() +
                                  "天"),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      Clipboard.setData(
                                          ClipboardData(text: res));
                                      showSimpleMessage(context,
                                          content: "密钥已拷贝", useSnackBar: true);
                                    },
                                    child: const Text("拷贝密钥")),
                                TextButton(
                                    onPressed: () {
                                      final newCode = base64Encode(
                                          utf8.encode("corkine:$res"));
                                      Clipboard.setData(
                                          ClipboardData(text: newCode));
                                      showSimpleMessage(context,
                                          content: "密钥已拷贝", useSnackBar: true);
                                    },
                                    child: const Text("拷贝 Basic 认证信息")),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text("OK"))
                              ]));
                } else {
                  showSimpleMessage(context,
                      content: "密码不能为空", useSnackBar: true);
                }
              },
              icon: const Icon(Icons.password)),
          IconButton(
              onPressed: () async =>
                  await ref.read(backupsProvider.notifier).append(),
              icon: const Icon(Icons.add)),
          IconButton(
              onPressed: _showDialog,
              icon: const Icon(Icons.calendar_today, size: 18)),
          const SizedBox(width: 7),
          DropdownButton(
              focusColor: Colors.transparent,
              onChanged: (_) {},
              value: selectServer,
              icon: const Icon(Icons.arrow_drop_down),
              items: servers
                  .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e),
                      onTap: () => setState(() => selectServer = e)))
                  .toList()),
          const SizedBox(width: 7)
        ]),
        body: Column(children: [
          Expanded(
              child: ListView.builder(
                  itemBuilder: (context, index) {
                    final item = data[index];
                    final start =
                        DateTime.fromMillisecondsSinceEpoch(item.start);
                    final cost = (item.cost / 60.0).toStringAsFixed(2);
                    return Dismissible(
                        key: ValueKey(item.id),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.endToStart) {
                            ref.read(backupsProvider.notifier).delete(item.id);
                            return true;
                          } else {
                            return false;
                          }
                        },
                        background: Container(color: Colors.amber),
                        secondaryBackground: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child:
                                const Icon(Icons.delete, color: Colors.white)),
                        child: ListTile(
                            dense: true,
                            title: Text(item.from),
                            onTap: () async {
                              await showSimpleMessage(context,
                                  content:
                                      "[Message]\n${item.message}\n\n[Log]\n${item.log}");
                            },
                            subtitle: Row(children: [
                              buildRichDate(start,
                                  today: today,
                                  weekDayOne: weekDayOne,
                                  lastWeekDayOne: lastWeekDayOne),
                              const SizedBox(width: 4),
                              Text("耗时 $cost 分钟")
                            ]),
                            trailing: item.result == "success"
                                ? const Icon(Icons.check, color: Colors.green)
                                : const Icon(Icons.error, color: Colors.red)));
                  },
                  itemCount: data.length))
        ]));
  }
}

class BackupCalView extends ConsumerStatefulWidget {
  final String? nowSelect;
  const BackupCalView(this.nowSelect, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BlueCalViewState();
}

class _BlueCalViewState extends ConsumerState<BackupCalView> {
  DateTime now = DateTime.now();
  final Map<String, Set<String>> _map = {};
  Set<String> selectNames = {};
  List<String> names = [];
  List<Color> colors = [
    Colors.red,
    Colors.orange,
    Colors.green,
    Colors.blueGrey,
    Colors.purple,
    Colors.pink,
    Colors.brown,
    Colors.indigo,
    Colors.teal
  ];
  @override
  void initState() {
    super.initState();
    ref.read(backupsProvider.future).then((v) {
      for (final item in v) {
        final date = DateTime.fromMillisecondsSinceEpoch(item.start);
        final dateStr = DateFormat.yMd().format(date);
        if (!_map.containsKey(dateStr)) {
          _map[dateStr] = {};
        }
        _map[dateStr]!.add(item.name);
        if (!names.contains(item.name)) {
          names.add(item.name);
        }
      }
      if (widget.nowSelect != null && widget.nowSelect != "全部") {
        selectNames = {widget.nowSelect!};
      } else {
        selectNames = names.toSet();
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(left: 8, right: 8, top: 10),
        child: Column(children: [
          TableCalendar(
              daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle:
                      TextStyle(color: appThemeData.colorScheme.onPrimary)),
              locale: 'zh_CN',
              firstDay: now.subtract(const Duration(days: 30)),
              lastDay: now.add(const Duration(days: 30)),
              focusedDay: now,
              calendarFormat: CalendarFormat.month,
              headerVisible: true,
              daysOfWeekHeight: 22,
              startingDayOfWeek: StartingDayOfWeek.monday,
              selectedDayPredicate: (d) => d == now,
              headerStyle: const HeaderStyle(
                  titleCentered: true, formatButtonVisible: false),
              calendarBuilders:
                  CalendarBuilders(markerBuilder: (context, date, events) {
                final key = DateFormat.yMd().format(date);
                if (!_map.containsKey(key)) return null;
                final s = _map[key] ?? {};
                return Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: s
                            .map((e) => Container(
                                margin: const EdgeInsets.only(right: 2),
                                decoration: BoxDecoration(
                                    color: selectNames.contains(e)
                                        ? colors[names.indexOf(e)]
                                        : colors[names.indexOf(e)]
                                            .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10)),
                                width: 8,
                                height: 8))
                            .toList()));
              })),
          Padding(
              padding: const EdgeInsets.only(left: 10, top: 20),
              child: Wrap(
                  spacing: 3,
                  runSpacing: 10,
                  children: names.map((n) {
                    final selected = selectNames.contains(n);
                    return InkWell(
                        onTap: () {
                          if (!selectNames.contains(n)) {
                            selectNames.add(n);
                          } else {
                            selectNames.remove(n);
                          }
                          setState(() {});
                        },
                        child: Padding(
                            padding: const EdgeInsets.only(left: 3, right: 3),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                      margin: const EdgeInsets.only(
                                          right: 2, top: 3),
                                      decoration: BoxDecoration(
                                          color: selected
                                              ? colors[names.indexOf(n)]
                                              : colors[names.indexOf(n)]
                                                  .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      width: 13,
                                      height: 13),
                                  Text(n,
                                      style: TextStyle(
                                          color: selected
                                              ? Colors.black
                                              : Colors.grey))
                                ])));
                  }).toList()))
        ]));
  }
}
