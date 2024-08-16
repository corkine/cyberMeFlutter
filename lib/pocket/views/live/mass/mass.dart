import 'dart:io';

import 'package:flutter/foundation.dart' as f;
import 'package:flutter/material.dart';
import 'package:health_kit_reporter/health_kit_reporter.dart';
import 'package:health_kit_reporter/model/predicate.dart';
import 'package:health_kit_reporter/model/type/quantity_type.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:sticky_grouped_list/sticky_grouped_list.dart';
import '../../../viewmodels/mass.dart';
import '../../util.dart';
import '../health.dart';
import 'add.dart';
import 'cal.dart';
import 'edit.dart';
import 'group.dart';

class MassActivityView extends ConsumerStatefulWidget {
  const MassActivityView({super.key});

  @override
  _MassActivityViewState createState() => _MassActivityViewState();
}

class _MassActivityViewState extends ConsumerState<MassActivityView> {
  late DateTime weekDayOne;
  late DateTime lastWeekDayOne;
  late int weekDayOneMs;
  late DateTime today;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    today = DateTime(now.year, now.month, now.day);
    weekDayOne = getThisWeekMonday();
    weekDayOneMs = weekDayOne.millisecondsSinceEpoch;
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
      final now = DateTime.now().add(const Duration(hours: 1));
      final threeMonthsAgo = now.subtract(const Duration(days: 90));
      final activities = await HealthKitReporter.quantityQuery(
          QuantityType.bodyMass, "kg", Predicate(threeMonthsAgo, now));
      final healthKitMiss =
          await ref.read(massDbProvider.notifier).sync(activities);
      if (healthKitMiss.isNotEmpty) {
        debugPrint('kit missed: ${healthKitMiss.length}');
        for (var e in healthKitMiss) {
          addBodyMassRecord(
              DateTime.fromMillisecondsSinceEpoch((e.time * 1000).toInt()),
              e.kgValue);
        }
      }
    } else {
      await showSimpleMessage(context, content: ok.$2);
    }
  }

  ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
            onPressed: () => showAdaptiveBottomSheet(
                context: context,
                cover: true,
                child: const BodyMassView(standalone: false),
                minusHeight: 200),
            child: const Icon(Icons.add)),
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
            child: Column(children: [buildTopBar(), buildList()])));
  }

  Widget buildList() {
    final data = ref.watch(massDbProvider).value ?? [];
    final plan = ref.watch(massWeekViewProvider);
    return StickyGroupedListView(
        shrinkWrap: true,
        elements: data,
        itemBuilder: (context, element) => buildCard(element, plan),
        groupBy: (element) => element.group,
        groupComparator: (a, b) => b - a,
        groupSeparatorBuilder: (element) {
          final groupInfo = plan[element.group];
          final noInfo = groupNoInfo(groupInfo);
          final lastWeek = element.group >= weekDayOneMs;
          final date = DateTime.fromMillisecondsSinceEpoch(element.group);
          action() => showEditGroupDialog(groupInfo!.copyWith(
              goalKg: groupInfo.goalKg == 0
                  ? element.kgValue - 3
                  : groupInfo.goalKg));
          return Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer),
              padding:
                  const EdgeInsets.only(left: 5, right: 10, top: 3, bottom: 3),
              child: InkWell(
                  onTap: action,
                  child: Row(children: [
                    noInfo
                        ? const Icon(Icons.report_outlined,
                            color: Color.fromARGB(255, 211, 211, 211))
                        : groupInfo!.satisfied
                            ? const Icon(Icons.verified,
                                color: Colors.green, size: 21)
                            : lastWeek
                                ? const Icon(Icons.watch_later,
                                    color: Colors.orange, size: 21)
                                : const Icon(Icons.report_outlined,
                                    color: Colors.red, size: 22),
                    const SizedBox(width: 5),
                    Transform.translate(
                        offset: const Offset(0, -1),
                        child: buildGroupView(date)),
                    const Spacer(),
                    Icon(Icons.insert_invitation,
                        size: 16, color: noInfo ? Colors.transparent : null),
                    const SizedBox(width: 2),
                    Text(
                        (noInfo
                            ? "--.-kg"
                            : groupInfo!.goalKg.toStringAsFixed(1) + "kg"),
                        style: TextStyle(
                            fontFamily: "consolas",
                            color: noInfo ? Colors.transparent : null)),
                    const SizedBox(width: 10),
                    noInfo || (groupInfo?.reward.isEmpty ?? true)
                        ? const Icon(Icons.more_vert, size: 16)
                        : Icon(Icons.card_giftcard,
                            size: 16,
                            color: groupInfo!.rewardChecked
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.secondary)
                  ])));
        });
  }

  Dismissible buildCard(MassData activity, Map<int, MassGroup> plan) {
    bool? lowerThanPrev = activity.next != null
        ? activity.kgValue < activity.next!.kgValue
        : null;
    return Dismissible(
        key: ValueKey(activity.time),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            if (await showSimpleMessage(context, content: "确定删除此记录吗?")) {
              await ref.read(massDbProvider.notifier).delete(activity.time);
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
                        style: TextStyle(color: Colors.white, fontSize: 15))))),
        background: Container(
            color: Colors.blue,
            child: const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Text("编辑",
                        style: TextStyle(color: Colors.white, fontSize: 15))))),
        child: ListTile(
            contentPadding: const EdgeInsets.only(right: 15, left: 13),
            leading: Container(
                width: 5,
                height: double.infinity,
                color: lowerThanPrev == null
                    ? Colors.orange
                    : lowerThanPrev
                        ? Colors.green
                        : Colors.red),
            minLeadingWidth: 0,
            visualDensity: VisualDensity.compact,
            dense: true,
            title: Text(activity.title.isEmpty ? "--" : activity.title,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => showEditDialog(activity),
            subtitle: buildRichDate(ts2DateTime(activity.time),
                today: today,
                weekDayOne: weekDayOne,
                lastWeekDayOne: lastWeekDayOne,
                fontSize: 12),
            trailing: RichText(
                text: TextSpan(
                    text: activity.kgValue.toStringAsFixed(1),
                    children: const [
                      TextSpan(text: " kg", style: TextStyle(fontSize: 11))
                    ],
                    style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary)))));
  }

  Widget buildTopBar() {
    bool useBody = Platform.isIOS;
    double paddingTop = Platform.isIOS ? 35 : 10;
    return SizedBox(
        height: useBody ? 133 : 183,
        child: Stack(children: [
          Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: Image.network(
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, 1),
                  useBody
                      ? "https://static2.mazhangjing.com/cyber/202408/f32be152_image.png"
                      : "https://static2.mazhangjing.com/cyber/202408/23ce6021_image.png")),
          Positioned(
              top: paddingTop,
              bottom: 0,
              left: 15,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.translate(
                        offset: const Offset(-10, 0),
                        child: const BackButton()),
                    const Spacer(),
                    const Text("Body Mass",
                        style: TextStyle(fontSize: 30, fontFamily: "Sank"))
                  ])),
          Padding(
              padding: EdgeInsets.only(top: paddingTop),
              child: Row(children: [
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.calendar_month, size: 19),
                    onPressed: _showCalDialog),
                const SizedBox(width: 10)
              ]))
        ]));
  }

  void _showCalDialog() {
    showAdaptiveBottomSheet(
        cover: true,
        context: context,
        child: const MassCalView(),
        divideHeight: 1.3);
  }

  void showEditDialog(MassData activity) async {
    final res = await showAdaptiveBottomSheet<MassData>(
        divideHeight: 1.5, context: context, child: MassItemEditView(activity));
    if (res != null) {
      ref.read(massDbProvider.notifier).edit(res);
    }
  }

  void showEditGroupDialog(MassGroup group) async {
    final res = await showAdaptiveBottomSheet<MassGroup>(
        divideHeight: 1.5, context: context, child: MassGroupEditView(group));
    // final res = await Navigator.of(context).push(
    //     MaterialPageRoute(builder: (context) => MassGroupEditView(group)));
    if (res != null) {
      ref.read(massPlanDbProvider.notifier).addOrEdit(res);
    }
  }
}
