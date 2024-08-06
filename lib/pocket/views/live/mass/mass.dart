import 'dart:io';

import 'package:cyberme_flutter/pocket/viewmodels/mass.dart';
import 'package:cyberme_flutter/pocket/views/live/mass/mass_add.dart';
import 'package:cyberme_flutter/pocket/views/util.dart';
import 'package:flutter/foundation.dart' as f;
import 'package:flutter/material.dart';
import 'package:health_kit_reporter/health_kit_reporter.dart';
import 'package:health_kit_reporter/model/predicate.dart';
import 'package:health_kit_reporter/model/type/category_type.dart';
import 'package:health_kit_reporter/model/type/quantity_type.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../health.dart';
import 'mass_cal.dart';

class MassActivityView extends ConsumerStatefulWidget {
  const MassActivityView({super.key});

  @override
  _MassActivityViewState createState() => _MassActivityViewState();
}

class _MassActivityViewState extends ConsumerState<MassActivityView> {
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
    doSync();
  }

  doSync() async {
    if (f.kIsWeb || !Platform.isIOS) return;
    await ref.read(massDbProvider.future);
    final ok = await requestAuthorization(
        readTypes: [QuantityType.bodyMass.identifier],
        writeTypes: [QuantityType.bodyMass.identifier]);
    if (ok.$1) {
      final now = DateTime.now();
      final threeMonthsAgo = now.subtract(const Duration(days: 90));
      final activities = await HealthKitReporter.quantityQuery(
          QuantityType.bodyMass, "kg", Predicate(threeMonthsAgo, now));
      final healthKitMiss =
          await ref.read(massDbProvider.notifier).sync(activities);
      if (healthKitMiss.isNotEmpty) {
        debugPrint('kit missed: ${healthKitMiss.length}');
        for (var e in healthKitMiss) {
          addBodyMassRecord(
              DateTime.fromMillisecondsSinceEpoch(e.time * 1000), e.kgValue);
        }
      }
    } else {
      await showSimpleMessage(context, content: ok.$2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(massDbProvider).value ?? [];
    return Scaffold(
        floatingActionButton: FloatingActionButton(
            onPressed: () {
              showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => const SizedBox(
                      height: 400, child: BodyMassView(standalone: false)));
            },
            child: const Icon(Icons.add)),
        backgroundColor: Colors.white,
        body: CustomScrollView(slivers: [
          SliverAppBar(
              expandedHeight: 130,
              flexibleSpace: FlexibleSpaceBar(
                  title: const Text("Body Mass",
                      style: TextStyle(fontSize: 24, fontFamily: "Sank")),
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 10),
                  background: Image.network(
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                      "https://static2.mazhangjing.com/cyber/202408/f32be152_image.png")),
              actions: [
                IconButton(
                    icon: const Icon(Icons.calendar_month, size: 19),
                    onPressed: _showDialog),
                const SizedBox(width: 10)
              ]),
          SliverFillRemaining(child: buildList(data))
        ]));
  }

  ListView buildList(List<MassData> data) {
    return ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          final activity = data[index];
          return Dismissible(
              key: ValueKey(activity.time),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.endToStart) {
                  if (await showSimpleMessage(context, content: "确定删除此记录吗?")) {
                    await ref
                        .read(massDbProvider.notifier)
                        .delete(activity.time);
                    await deleteSample(
                        QuantityType.bodyMass.identifier, activity.time);
                    return true;
                  }
                } else {
                  showEditDialog(activity);
                  return false;
                }
                return false;
              },
              secondaryBackground: Container(
                  color: Colors.red,
                  child: const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                          padding: EdgeInsets.only(right: 20),
                          child: Text("删除",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 15))))),
              background: Container(
                  color: Colors.blue,
                  child: const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: Text("编辑",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 15))))),
              child: ListTile(
                  title: Text(activity.title.isEmpty ? "--" : activity.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return SizedBox(
                              width: double.infinity,
                              child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 10, right: 10, top: 20),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(activity.title,
                                            style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold)),
                                        Text(activity.description)
                                      ])));
                        });
                  },
                  subtitle: buildRichDate(ts2DateTime(activity.time),
                      today: today,
                      weekDayOne: weekDayOne,
                      lastWeekDayOne: lastWeekDayOne,
                      fontSize: 12),
                  trailing: RichText(
                      text: TextSpan(
                          text: activity.kgValue.toStringAsFixed(1),
                          children: const [
                            TextSpan(
                                text: " kg", style: TextStyle(fontSize: 11))
                          ],
                          style: TextStyle(
                              fontSize: 16,
                              //fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary)))));
        });
  }

  void _showDialog() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => SizedBox(
            height: MediaQuery.of(context).size.height / 1.3,
            child: const MassCalView()));
  }

  void showEditDialog(MassData activity) async {
    final res = await showModalBottomSheet<MassData>(
        context: context, builder: (context) => MassItemEditView(activity));
    if (res != null) {
      ref.read(massDbProvider.notifier).edit(res);
    }
  }
}

class MassItemEditView extends ConsumerStatefulWidget {
  final MassData data;
  const MassItemEditView(this.data, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MassItemEditViewState();
}

class _MassItemEditViewState extends ConsumerState<MassItemEditView> {
  late final MassData data = widget.data;
  final title = TextEditingController();
  final description = TextEditingController();
  @override
  void initState() {
    super.initState();
    title.text = data.title;
    description.text = data.description;
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
        child: Column(children: [
          RichText(
              text: TextSpan(
                  text: data.kgValue.toStringAsFixed(1),
                  children: const [
                    TextSpan(text: "  kg", style: TextStyle(fontSize: 30))
                  ],
                  style: TextStyle(
                      fontSize: 70,
                      fontFamily: "Sank",
                      color: Theme.of(context).colorScheme.primary))),
          TextField(
            controller: title,
            decoration: const InputDecoration(label: Text("标题")),
          ),
          TextField(
              controller: description,
              maxLines: null,
              decoration: const InputDecoration(label: Text("描述"))),
          const Spacer(),
          SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop(data.copyWith(
                        title: title.text, description: description.text));
                  },
                  child: const Text("确定"))),
          const SizedBox(height: 10)
        ]));
  }
}
