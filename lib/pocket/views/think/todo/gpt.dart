import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GPTWeekPlanView extends ConsumerStatefulWidget {
  final String answer;
  const GPTWeekPlanView(this.answer, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _GPTWeekPlanViewState();
}

class _GPTWeekPlanViewState extends ConsumerState<GPTWeekPlanView> {
  final controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    controller.text = widget.answer;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, top: 20),
            child: Column(children: [
              TextField(maxLines: 9, controller: controller),
              OverflowBar(alignment: MainAxisAlignment.center, children: [
                TextButton(
                    onPressed: () {
                      controller.text = controller.text.replaceAll("*", "");
                    },
                    child: const Text("移星号")),
                TextButton(
                    onPressed: () {
                      controller.text = controller.text.replaceAll("*", "-");
                    },
                    child: const Text("星改杠")),
                TextButton(
                    onPressed: () {
                      FlutterClipboard.copy(controller.text);
                      setState(() => copyText = "已复制");
                      Future.delayed(const Duration(seconds: 1))
                          .then((value) => setState(() => copyText = "复制"));
                    },
                    child: Text(copyText)),
                TextButton(onPressed: () {}, child: const Text("确定"))
              ])
            ])));
  }

  String copyText = "复制";
}
