import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../viewmodels/mass.dart';

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
  final note = TextEditingController();
  @override
  void initState() {
    super.initState();
    title.text = data.title;
    note.text = data.note;
  }

  @override
  void dispose() {
    title.dispose();
    note.dispose();
    super.dispose();
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
                  decoration: const InputDecoration(label: Text("标题"))),
              TextField(
                  onTapOutside: (e) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  controller: note,
                  maxLines: null,
                  decoration: const InputDecoration(label: Text("描述"))),
              const Spacer(),
              SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop(
                            data.copyWith(title: title.text, note: note.text));
                      },
                      child: const Text("确定")))
            ])));
  }
}
