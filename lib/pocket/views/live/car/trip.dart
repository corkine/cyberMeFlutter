import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../main.dart';
import '../../../viewmodels/car.dart';
import '../../util.dart';

class TripListView extends ConsumerStatefulWidget {
  final List<CarTripItem> items;
  const TripListView(this.items, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TripListViewState();
}

class _TripListViewState extends ConsumerState<TripListView> {
  late DateTime weekDayOne;
  late DateTime lastWeekDayOne;
  late DateTime today;
  late List<CarTripItem> items;

  @override
  void initState() {
    super.initState();
    items = widget.items.reversed.toList();
    final now = DateTime.now();
    today = DateTime(now.year, now.month, now.day);
    weekDayOne = getThisWeekMonday();
    lastWeekDayOne = weekDayOne.subtract(const Duration(days: 7));
  }

  @override
  Widget build(BuildContext context) {
    final notesDb = ref.watch(getTripNotesProvider);
    return Theme(
        data: appThemeData,
        child: Scaffold(
            appBar: AppBar(
                title: const Text("行程信息"),
                actions: const [SizedBox(width: 10)]),
            body: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final trip = items[index];
                  final notes = buildTripNotes(notesDb, trip);
                  return ExpansionTile(
                      dense: true,
                      children: notes,
                      trailing: InkResponse(
                          radius: 20,
                          onTap: () =>
                              showNoteAddOrEditNoteDialog(trip, TripNote()),
                          child: notes.isEmpty
                              ? const Icon(Icons.add, color: Colors.white54)
                              : const Icon(Icons.notes)),
                      title: Row(children: [
                        Text(trip.mileage.toStringAsFixed(0) + " km"),
                        Container(
                            height: 10,
                            color: Colors.white54,
                            margin: const EdgeInsets.only(left: 5, right: 5),
                            width: 2),
                        Text(trip.traveltime.toStringAsFixed(0) + " min"),
                        Container(
                            height: 10,
                            color: Colors.white54,
                            margin: const EdgeInsets.only(left: 5, right: 5),
                            width: 2),
                        Text(trip.averageSpeed.toStringAsFixed(0) + "km/h")
                      ]),
                      subtitle: buildRichDate(
                          DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z")
                              .parse(trip.timestamp)
                              .add(const Duration(hours: 8)),
                          dateFormat: "yyyy-MM-dd HH:mm",
                          today: today,
                          weekDayOne: weekDayOne,
                          lastWeekDayOne: lastWeekDayOne),
                      leading: Container(
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6)),
                          padding: const EdgeInsets.only(left: 5, right: 5),
                          width: 43,
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                buildFuleWidget(trip.averageFuelConsumption),
                                const Text("L/100km",
                                    style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 7,
                                        fontFamily: "PingFangSC-Regular"))
                              ])));
                })));
  }

  buildFuleWidget(double value) {
    return Text((value / 10).toStringAsFixed(1),
        style: TextStyle(
            color: value > 120
                ? Colors.red
                : value > 90
                    ? Colors.orange
                    : Colors.green,
            fontSize: 16));
  }

  List<Widget> buildTripNotes(
      Map<int, List<TripNote>> notesDb, CarTripItem trip) {
    return (notesDb[trip.tripID] ?? []).map((note) {
      return Dismissible(
          key: ValueKey(note.id),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              final res =
                  await ref.read(carLifeDbProvider.notifier).delete(note.id);
              showSimpleMessage(context, content: res, useSnackBar: true);
              return true;
            } else {
              await showNoteAddOrEditNoteDialog(trip, note);
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
              child: const Icon(Icons.delete, color: Colors.white)),
          child: ListTile(title: Text(note.note, maxLines: 1), dense: true));
    }).toList(growable: false);
  }

  showNoteAddOrEditNoteDialog(CarTripItem trip, TripNote tripNote) async {
    final isNew = tripNote.id.isEmpty;
    final note = TextEditingController(text: tripNote.note);
    final noteRes = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return Theme(
              data: appThemeData,
              child: AlertDialog(
                  title: Text(isNew ? "添加笔记" : "编辑笔记"),
                  content: TextField(
                      autofocus: true,
                      controller: note,
                      maxLines: 5,
                      decoration: const InputDecoration(hintText: "请输入内容")),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, null),
                        child: const Text("取消")),
                    TextButton(
                        onPressed: () {
                          if (note.text.isNotEmpty) {
                            Navigator.pop(context, note.text);
                          }
                        },
                        child: const Text("确定"))
                  ]));
        });
    if (noteRes != null) {
      final res = await ref.read(carLifeDbProvider.notifier).addOrUpdate(
          tripNote.copyWith(
              note: noteRes,
              id: tripNote.id.isEmpty ? const Uuid().v4() : tripNote.id,
              tripID: trip.tripID));
      showSimpleMessage(context, content: res, useSnackBar: true);
    }
  }
}
