import 'package:cyberme_flutter/pocket/viewmodels/mass.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../main.dart';

class MassCalView extends ConsumerStatefulWidget {
  const MassCalView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BodyCalViewState();
}

class _BodyCalViewState extends ConsumerState<MassCalView> {
  DateTime now = DateTime.now();
  Map<String, MassData> _map = {};
  Map<String, MassData> _prev = {};
  @override
  void initState() {
    super.initState();
    ref.read(massDbProvider.future).then((v) {
      MassData? prev;
      final r = (v..sort((a, b) => a.time - b.time)).map((d) {
        final key = DateFormat.yMd()
            .format(DateTime.fromMillisecondsSinceEpoch(d.time * 1000));
        if (prev != null) {
          _prev[key] = prev!;
        }
        prev = d;
        return MapEntry(key, d);
      });
      _map = Map.fromEntries(r);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(left: 8, right: 8, top: 10),
        child: TableCalendar(
            daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle:
                    TextStyle(color: appThemeData.colorScheme.onSurface)),
            locale: 'zh_CN',
            firstDay: now.subtract(const Duration(days: 30)),
            lastDay: now.add(const Duration(days: 30)),
            focusedDay: now,
            calendarFormat: CalendarFormat.month,
            headerVisible: true,
            daysOfWeekHeight: 22,
            startingDayOfWeek: StartingDayOfWeek.monday,
            selectedDayPredicate: (d) => d == now,
            headerStyle: const HeaderStyle(
                titleCentered: true, formatButtonVisible: false),
            calendarBuilders:
                CalendarBuilders(markerBuilder: (context, date, events) {
              final dateFmt = DateFormat.yMd().format(date);
              if (!_map.containsKey(dateFmt)) return null;
              final v = _map[dateFmt]!;
              final prev = _prev[dateFmt];
              Widget? deltaWidget;
              if (prev != null) {
                final delta = prev.kgValue - v.kgValue;
                if (delta > 0) {
                  deltaWidget = Transform.translate(
                      offset: const Offset(-2, 0),
                      child: Row(children: [
                        Transform.translate(
                            offset: const Offset(5, 0),
                            child: const Icon(Icons.arrow_drop_up,
                                color: Colors.red)),
                        Text(delta.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.red))
                      ]));
                } else {
                  deltaWidget = Transform.translate(
                      offset: const Offset(-2, 0),
                      child: Row(children: [
                        Transform.translate(
                            offset: const Offset(5, 0),
                            child: const Icon(Icons.arrow_drop_down,
                                color: Colors.green)),
                        Text((delta * -1).toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.green))
                      ]));
                }
              }
              return Stack(alignment: Alignment.center, children: [
                Container(
                    margin: const EdgeInsets.only(
                        left: 3, right: 3, bottom: 5, top: 5),
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10))),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (deltaWidget != null) const SizedBox(height: 5),
                      Text(v.kgValue.toStringAsFixed(1),
                          style: const TextStyle(height: 1)),
                      if (deltaWidget != null) deltaWidget
                    ])
              ]);
            })));
  }
}
