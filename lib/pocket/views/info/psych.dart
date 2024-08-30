import 'package:cyberme_flutter/pocket/viewmodels/psych.dart';
import 'package:cyberme_flutter/pocket/views/util.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PsychRecentView extends ConsumerStatefulWidget {
  const PsychRecentView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PsychRecentViewState();
}

class _PsychRecentViewState extends ConsumerState<PsychRecentView> {
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
    lastWeekDayOne = weekDayOne.subtract(const Duration(days: 7));
  }

  @override
  Widget build(BuildContext context) {
    final res = ref.watch(psychDbProvider).value?.items ?? [];
    return Scaffold(
        appBar: AppBar(title: const Text("Psych Cases"), actions: [
          IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () async {
                final res = await ref.read(psychDbProvider.notifier).next();
                showSimpleMessage(context, content: res, useSnackBar: true);
              }),
          const SizedBox(width: 10)
        ]),
        body: ListView.builder(
            itemBuilder: (context, index) {
              final item = res[index];
              return ListTile(
                  dense: true,
                  title: Text(item.kind, style: const TextStyle(fontSize: 16)),
                  trailing: Text(item.id.toString()),
                  subtitle: buildRichDate(
                      DateFormat("yyyy-MM-ddTH:mm:ss.SSS").parse(item.createAt),
                      today: today,
                      weekDayOne: weekDayOne,
                      lastWeekDayOne: lastWeekDayOne),
                  onTap: () =>
                      showSimpleMessage(context, content: item.toString()),
                  onLongPress: () => launchUrlString(item.url));
            },
            itemCount: res.length));
  }
}
