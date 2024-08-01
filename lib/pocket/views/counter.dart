import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../viewmodels/counter.dart';

class FuckCounterView extends ConsumerStatefulWidget {
  const FuckCounterView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _FuckCounterViewState();
}

class _FuckCounterViewState extends ConsumerState<FuckCounterView> {
  @override
  Widget build(BuildContext context) {
    final d = ref.watch(countersProvider).value ?? [];
    return Scaffold(
        appBar: AppBar(title: const Text("Counter")),
        body: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton(
                onPressed: () => handleAdd(mark: CounterX.OUT),
                onLongPress: () => handleAdd(mark: CounterX.OUT, quick: true),
                child: const Text("Add Out")),
            TextButton(
                onPressed: () => handleAdd(mark: CounterX.IN),
                onLongPress: () => handleAdd(mark: CounterX.IN, quick: true),
                child: const Text("Add In"))
          ]),
          Expanded(
              child: ListView.builder(
                  itemBuilder: (c, i) {
                    final co = d[i];
                    final color = co.isOut ? Colors.red : Colors.green;
                    final first = i == 0;
                    final icon = co.isOut
                        ? Icon(Icons.arrow_downward, color: color)
                        : Icon(Icons.arrow_back, color: color);
                    return Dismissible(
                        key: ValueKey(co.time),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.endToStart) {
                            await handleRemove(co.id);
                            return true;
                          } else {
                            await edit(co);
                            return false;
                          }
                        },
                        background: Container(
                          color: Colors.amber,
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: ListTile(
                                dense: true,
                                title: Text(co.note.isEmpty ? "无备注" : co.note,
                                    style: TextStyle(color: color)),
                                subtitle: Text(
                                    DateTime.fromMillisecondsSinceEpoch(co.time)
                                        .toString(),
                                    style: TextStyle(color: color)),
                                trailing: first
                                    ? icon.animate().shake(
                                        rotation: 0.2, duration: 1.seconds)
                                    : icon)
                            .animate()
                            .moveY(begin: 50, end: 0, duration: 0.3.seconds)
                            .fadeIn());
                  },
                  itemCount: d.length)),
          Text(ref.watch(counterInfoProvider)),
          const SizedBox(height: 10)
        ]));
  }

  Future<String> collectNote() async {
    final e = TextEditingController();
    final note = await showDialog<String>(
            context: context,
            builder: (c) => AlertDialog(
                    title: const Text("备注"),
                    content: TextField(
                        autofocus: true,
                        decoration: const InputDecoration(hintText: "备注"),
                        controller: e),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(null),
                          child: const Text("取消")),
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(e.text),
                          child: const Text("确定"))
                    ])) ??
        "";
    return note;
  }

  Future<void> edit(Counter counter) async {
    var out = counter.isOut;
    final note = TextEditingController(text: counter.note);
    var dateTime = DateTime.fromMillisecondsSinceEpoch(counter.time);
    final ok = await showDialog<bool>(
            context: context,
            builder: (context) => StatefulBuilder(
                builder: (context, setState) => AlertDialog(
                        title: const Text("编辑"),
                        content: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                  controller: note,
                                  decoration:
                                      const InputDecoration(hintText: "备注")),
                              const Padding(
                                  padding: EdgeInsets.only(top: 10),
                                  child: Text("OUT?")),
                              Switch.adaptive(
                                  value: out,
                                  onChanged: (v) => setState(() => out = !out)),
                              const Padding(
                                  padding: EdgeInsets.only(top: 10),
                                  child: Text("TIME")),
                              InkWell(
                                  onTap: () async {
                                    final time = await showTimePicker(
                                        context: context,
                                        initialTime:
                                            TimeOfDay.fromDateTime(dateTime));
                                    if (time != null) {
                                      dateTime = DateTime(
                                          dateTime.year,
                                          dateTime.month,
                                          dateTime.day,
                                          time.hour,
                                          time.minute);
                                      setState(() {});
                                    }
                                  },
                                  child: Text(dateTime.toString()))
                            ]),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(null),
                              child: const Text("取消")),
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text("确定"))
                        ]))) ??
        false;
    if (ok) {
      await ref.read(countersProvider.notifier).modify(counter.copyWith(
          mark: out ? CounterX.OUT : CounterX.IN,
          note: note.text,
          time: dateTime.millisecondsSinceEpoch));
    }
  }

  void handleAdd({bool quick = false, required String mark}) async {
    await ref.read(countersProvider.notifier).add(Counter(
        id: const Uuid().v4(),
        mark: mark,
        note: quick ? "" : await collectNote(),
        time: DateTime.now().millisecondsSinceEpoch));
  }

  Future<void> handleRemove(String id) async {
    await ref.read(countersProvider.notifier).remove(id);
  }
}
