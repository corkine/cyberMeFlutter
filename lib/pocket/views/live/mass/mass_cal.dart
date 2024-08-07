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
  final Map<String, MassData> _prev = {};
  @override
  void initState() {
    super.initState();
    ref.read(massDbProvider.future).then((v) {
      MassData? prev;
      final r = (v..sort((a, b) => (a.time - b.time).toInt())).map((d) {
        final key = DateFormat.yMd().format(
            DateTime.fromMillisecondsSinceEpoch((d.time * 1000).toInt()));
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
                if (delta < 0) {
                  deltaWidget = Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const TriangleWidget(
                            up: true,
                            size: 7,
                            padding: EdgeInsets.only(right: 3)),
                        Text((delta < 0 ? -delta : delta).toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.red))
                      ]);
                } else {
                  deltaWidget = Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const TriangleWidget(
                            up: false,
                            size: 7,
                            padding: EdgeInsets.only(right: 3)),
                        Text((delta < 0 ? -delta : delta).toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.green))
                      ]);
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
                      Text(v.kgValue.toStringAsFixed(1),
                          style: const TextStyle(height: 1)),
                      if (deltaWidget != null) deltaWidget
                    ])
              ]);
            })));
  }
}

class TriangleWidget extends StatelessWidget {
  final double size;
  final bool up;
  final EdgeInsetsGeometry padding;

  const TriangleWidget({
    Key? key,
    required this.up,
    this.size = 100,
    this.padding = const EdgeInsets.only(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: padding,
        child: CustomPaint(
            size: Size(size, size), painter: TrianglePainter(direction: up)));
  }
}

class TrianglePainter extends CustomPainter {
  final bool direction;

  TrianglePainter({required this.direction});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    paint.color = direction ? Colors.red : Colors.green;

    var path = Path();
    if (direction) {
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
