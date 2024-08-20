import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../viewmodels/mass.dart';

class MassGroupEditView extends ConsumerStatefulWidget {
  final MassGroup group;
  const MassGroupEditView(this.group, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MassGroupEditViewState();
}

class _MassGroupEditViewState extends ConsumerState<MassGroupEditView> {
  late var group = widget.group;
  final plan = TextEditingController();
  final impl = TextEditingController();
  final reward = TextEditingController();
  @override
  void initState() {
    super.initState();
    plan.text = group.note;
    impl.text = group.desc;
    reward.text = group.reward;
  }

  @override
  void dispose() {
    plan.dispose();
    impl.dispose();
    reward.dispose();
    super.dispose();
  }

  static const delta = 0.2;

  minus() {
    setState(() {
      group = group.copyWith(goalKg: group.goalKg - delta);
    });
  }

  add() {
    setState(() {
      group = group.copyWith(goalKg: group.goalKg + delta);
    });
  }

  edit() async {
    final e = TextEditingController(text: group.goalKg.toStringAsFixed(1));
    final res = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
                content: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TextField(
                      controller: e,
                      decoration: const InputDecoration(
                          label: Text("目标体重"), suffixText: "kg"),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onTapOutside: (_) {
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp("[0-9.]"))
                      ]),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(e.text),
                      child: const Text("确定"))
                ]));
    if (res != null && double.tryParse(res) != null) {
      setState(() {
        group = group.copyWith(goalKg: double.parse(res));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
            padding: EdgeInsets.only(
                top: 10,
                left: 10,
                right: 10,
                bottom: Platform.isWindows || Platform.isMacOS ? 10 : 0),
            child: SingleChildScrollView(
                child: Column(children: [
              Row(children: [
                const SizedBox(width: 6),
                const Icon(Icons.insert_invitation, size: 16),
                const SizedBox(width: 3),
                const Text("编辑计划"),
                const Spacer(),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(group.copyWith(
                          note: plan.text,
                          desc: impl.text,
                          reward: reward.text));
                    },
                    child: const Text("确定"))
              ]),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(onPressed: minus, icon: const Icon(Icons.remove)),
                const SizedBox(width: 20),
                InkWell(
                  onTap: edit,
                  child: RichText(
                      text: TextSpan(
                          text: group.goalKg.toStringAsFixed(1),
                          children: const [
                            TextSpan(
                                text: "  kg", style: TextStyle(fontSize: 30))
                          ],
                          style: TextStyle(
                              fontSize: 70,
                              fontFamily: "Sank",
                              color: Theme.of(context).colorScheme.primary))),
                ),
                const SizedBox(width: 20),
                IconButton(onPressed: add, icon: const Icon(Icons.add))
              ]),
              TextField(
                  controller: plan,
                  decoration: const InputDecoration(label: Text("计划"))),
              TextField(
                  onTapOutside: (e) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  controller: impl,
                  maxLines: null,
                  decoration: const InputDecoration(label: Text("实施"))),
              Row(children: [
                Transform.translate(
                    offset: const Offset(0, 5),
                    child: Checkbox(
                        value: group.rewardChecked,
                        onChanged: (v) {
                          setState(() {
                            group = group.copyWith(rewardChecked: v!);
                          });
                        })),
                const SizedBox(width: 10),
                Expanded(
                    child: TextField(
                        onTapOutside: (e) {
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                        controller: reward,
                        decoration: const InputDecoration(label: Text("奖励"))))
              ]),
              const SizedBox(height: 5)
            ]))));
  }
}
