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
  final title = TextEditingController();
  final description = TextEditingController();
  @override
  void initState() {
    super.initState();
    title.text = group.note;
    description.text = group.desc;
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
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
                title: const Text("编辑"),
                content: TextField(
                    controller: e,
                    decoration: const InputDecoration(
                        label: Text("目标体重"), suffixText: "kg"),
                    keyboardType: TextInputType.number,
                    onTapOutside: (_) {
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp("[0-9.]"))
                    ]),
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
    return SafeArea(
        child: Padding(
            padding: EdgeInsets.only(
                top: 10,
                left: 10,
                right: 10,
                bottom: Platform.isWindows || Platform.isMacOS ? 10 : 0),
            child: Column(children: [
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
                  controller: title,
                  decoration: const InputDecoration(label: Text("计划"))),
              TextField(
                  onTapOutside: (e) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  controller: description,
                  maxLines: null,
                  decoration: const InputDecoration(label: Text("事实"))),
              const Spacer(),
              SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop(group.copyWith(
                            note: title.text, desc: description.text));
                      },
                      child: const Text("确定")))
            ])));
  }
}
