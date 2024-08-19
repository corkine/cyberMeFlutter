import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../main.dart';
import '../../../viewmodels/statistics.dart';

class StatisticsView extends ConsumerWidget {
  const StatisticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(getStatisticsProvider).value?.$1;
    return Theme(
        data: appThemeData,
        child: Scaffold(
            appBar: AppBar(title: const Text("API Statistics"), actions: [
              IconButton(
                  onPressed: () => ref.refresh(getStatisticsProvider),
                  icon: const Icon(Icons.refresh))
            ]),
            body: s == null
                ? const Center(child: CupertinoActivityIndicator())
                : SingleChildScrollView(
                    child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                            children: [
                          buildOf("Web 主页接口", s.dashboard),
                          buildOf("客户端接口", s.client),
                          buildOf("短链接系统", s.go),
                          buildOf("故事系统", s.story),
                          buildOf("任务系统", s.task),
                          buildOf("问卷系统", s.psych)
                        ].animate().fadeIn().moveY(begin: 30, end: 0))))));
  }

  Widget buildOf(String item, count) {
    return Card(
        elevation: 1,
        child: ListTile(title: Text(item), trailing: Text(count.toString())));
  }
}
