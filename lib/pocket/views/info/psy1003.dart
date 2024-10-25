import 'package:cyberme_flutter/pocket/viewmodels/psy1003.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../util.dart';

class Psy1003View extends ConsumerStatefulWidget {
  const Psy1003View({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _Psy1003ViewState();
}

class _Psy1003ViewState extends ConsumerState<Psy1003View> with TimeMixin {
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(getPsySimpleProvider).value ?? [];
    return Scaffold(
        appBar: AppBar(title: const Text("Psy1003"), actions: [
          IconButton(
              onPressed: () {
                ref.invalidate(getPsySimpleProvider);
                showSimpleMessage(context, content: "已重新加载", useSnackBar: true);
              },
              icon: const Icon(Icons.refresh)),
          const SizedBox(width: 10),
        ]),
        body: ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final d = data[index];
              return ListTile(
                  dense: true,
                  subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(d.major,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 5),
                          Text(d.name + ", ${d.age}, ${d.gender}"),
                        ])
                      ]),
                  title: Row(children: [
                    buildRichDate(d.time,
                        today: today,
                        weekDayOne: weekDayOne,
                        lastWeekDayOne: lastWeekDayOne),
                    const Spacer(),
                    Text(d.version),
                    const SizedBox(width: 5),
                    Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: Colors.blue.withOpacity(0.1)),
                        padding: const EdgeInsets.only(left: 5, right: 5),
                        child: Text(d.mark)),
                  ]));
            }));
  }
}
