import 'dart:io';
import 'dart:ui' as ui;

import 'package:cyberme_flutter/pocket/viewmodels/mass.dart';
import 'package:cyberme_flutter/pocket/views/live/health.dart';
import 'package:cyberme_flutter/pocket/views/util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

class BodyMassView extends ConsumerStatefulWidget {
  final bool standalone;
  const BodyMassView({super.key, this.standalone = true});

  @override
  ConsumerState<BodyMassView> createState() => _BodyMassViewState();
}

class _BodyMassViewState extends ConsumerState<BodyMassView> {
  List<double> recentBodyMass = [];
  String value = "";

  @override
  void initState() {
    super.initState();
    handleReadBodyMassRecent();
  }

  bool get nonAvailableData => recentBodyMass.length <= 1;

  @override
  Widget build(BuildContext context) {
    final body = Column(children: [
      const SizedBox(height: 10),
      if (widget.standalone)
        Row(children: [
          const SizedBox(width: 16),
          Text("近期体重趋势", style: Theme.of(context).textTheme.bodyLarge)
        ]),
      const SizedBox(height: 10),
      SizedBox(
          width: MediaQuery.of(context).size.width - 30,
          height: MediaQuery.of(context).size.height / 4.5,
          child: CustomPaint(
              painter: ViewPainter(recentBodyMass),
              child: nonAvailableData
                  ? const Center(child: Text("数据不足，收集些数据后再来吧"))
                  : null)),
      const SizedBox(height: 30),
      Center(
          child: Container(
              height: 150,
              width: 150,
              child: Stack(children: [
                Positioned(
                    left: 20,
                    right: 20,
                    top: 20,
                    child: CupertinoTextField(
                      onSubmitted: (v) async {
                        try {
                          final vv = double.parse(v);
                          await handleWriteBodyMass(vv);
                          setState(() {
                            recentBodyMass.add(vv);
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())));
                        }
                      },
                      onChanged: (e) => value = e,
                      decoration: BoxDecoration(
                          color: const Color.fromARGB(40, 17, 126, 13),
                          borderRadius: BorderRadius.circular(3)),
                      autocorrect: false,
                      autofocus: true,
                      showCursor: true,
                      textAlign: TextAlign.center,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      suffix: const Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: Text("kg",
                              style: TextStyle(fontFamily: "consolas"))),
                    )),
                TapRegion(
                    onTapInside: (_) {
                      final v = double.tryParse(value);
                      if (v != null) {
                        handleWriteBodyMass(v);
                        setState(() {
                          recentBodyMass.add(v);
                        });
                      }
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Center(
                            child: Container(
                                child: const Padding(
                                    padding: EdgeInsets.only(
                                        left: 4, right: 4, top: 2, bottom: 2),
                                    child: Text("记录")),
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(3))))))
              ]),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.black45),
                  borderRadius: BorderRadius.circular(30)))),
      const Spacer()
    ]);
    if (!widget.standalone) return body;
    return Scaffold(
        appBar: AppBar(title: const Text("Body Mass"), centerTitle: true),
        body: body);
  }

  handleReadBodyMassRecent() async {
    // if (Platform.isAndroid || Platform.isIOS) {
    //   final health = HealthFactory(useHealthConnectIfAvailable: false);
    //   var types = [HealthDataType.WEIGHT];
    //   var permissions = [HealthDataAccess.READ_WRITE];
    //   var take = 7;
    //   bool req =
    //       await health.requestAuthorization(types, permissions: permissions);
    //   if (req) {
    //     final now = DateTime.now();
    //     final start = now.subtract(const Duration(days: 50));
    //     final data = await health.getHealthDataFromTypes(start, now, types);
    //     data.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
    //     final takeData = data
    //         .getRange(
    //             data.length - take >= 0 ? data.length - take : 0, data.length)
    //         .toList(growable: false);
    //     recentBodyMass = [];
    //     for (final d in takeData) {
    //       final v = (d.value as NumericHealthValue?)?.numericValue;
    //       debugPrint(
    //           "date: ${d.dateFrom}, value: ${v.toString()}, unit: ${d.unit.name}");
    //       if (v != null) {
    //         recentBodyMass.add(v as double);
    //       }
    //     }
    //     setState(() {});
    //   } else {
    //     recentBodyMass = [];
    //     ScaffoldMessenger.of(context).showSnackBar(
    //         const SnackBar(content: Text("没有 HealthKit 读取权限，请检查后再试！")));
    //   }
    // }
    final d = await ref.read(massDbProvider.future);
    recentBodyMass.addAll(d.map((e) => e.kgValue).take(7));
    setState(() {});
  }

  handleWriteBodyMass(double value) async {
    // if (Platform.isIOS || Platform.isAndroid) {
    //   final health = HealthFactory(useHealthConnectIfAvailable: false);
    //   var types = [HealthDataType.WEIGHT];
    //   var permissions = [HealthDataAccess.READ_WRITE];
    //   bool req =
    //       await health.requestAuthorization(types, permissions: permissions);
    //   if (req) {
    //     final now = DateTime.now();
    //     bool success = await health.writeHealthData(
    //         value, HealthDataType.WEIGHT, now, now);
    //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //         content: Text("更新数据 ${value.toStringAsFixed(1)} 结果：$success。")));
    //   } else {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //         const SnackBar(content: Text("没有 HealthKit 写入权限，请检查后再试！")));
    //   }
    // }
    final time = DateTime.now();
    await ref.read(massDbProvider.notifier).add(MassData(
        time: time.millisecondsSinceEpoch / 1000,
        kgValue: value,
        title: DateFormat("yyyy-MM-dd HH:mm").format(time) + " 添加"));
    if (!kIsWeb && Platform.isIOS) {
      final (ok, msg) = await addBodyMassRecord(time, value);
      await showSimpleMessage(context,
          content: ok ? "记录成功！" : msg, useSnackBar: true);
    }
  }
}

class ViewPainter extends CustomPainter {
  final List<double> bodyMass;

  ViewPainter(this.bodyMass);

  @override
  void paint(Canvas canvas, Size size) {
    if (bodyMass.isEmpty || bodyMass.length == 1) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromPoints(
                  const Offset(0, 0), Offset(size.width, size.height)),
              const Radius.circular(20)),
          Paint()..color = Colors.black.withOpacity(0.02));
      return;
    }
    final s = bodyMass.map((e) => e).toList(growable: false);
    s.sort();
    final min = s.first;
    final max = s.last;
    const radius = 15.0;
    final avaHeight = size.height;
    final avaWidth = size.width - 20;
    var eachPointHeight = (avaHeight - radius * 4) / (max - min);
    if (eachPointHeight.isInfinite) {
      eachPointHeight = avaHeight / 2;
    }
    final eachPointWidth = (avaWidth - radius * 4) / (bodyMass.length - 1);
    final normalizedY = bodyMass.map((e) => (e - min) * eachPointHeight);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromPoints(
                const Offset(0, 0), Offset(size.width, size.height)),
            const Radius.circular(20)),
        Paint()..color = Colors.black.withOpacity(0.02));
    canvas.drawLine(
        Offset(radius * 2, avaHeight - normalizedY.first - radius * 2),
        Offset(size.width, avaHeight - normalizedY.first - radius * 2),
        Paint()
          ..color = Colors.grey
          ..strokeWidth = 0.3);
    int lastIdx = normalizedY.length - 1;
    for (final (i, y) in normalizedY.indexed) {
      final dx = i * eachPointWidth + radius * 2;
      final dy = avaHeight - (y + radius * 2);
      canvas.drawCircle(
          Offset(dx, dy),
          radius,
          Paint()
            ..strokeWidth = 3.0
            ..color = i == 0 || i == lastIdx
                ? Colors.red
                : Colors.grey.withOpacity(0.2));
      if (i == 0) {
        final p = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 13))
          ..pushStyle(ui.TextStyle(color: Colors.grey))
          ..addText((bodyMass[i]).toStringAsFixed(1) + "kg");
        canvas.drawParagraph(
            p.build()..layout(const ui.ParagraphConstraints(width: 50)),
            Offset(dx + radius + 3, dy - radius + 7));
      } else if (i == lastIdx) {
        final delta = bodyMass[i] - bodyMass[0];
        final p = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 13))
          ..pushStyle(ui.TextStyle(color: Colors.grey))
          ..addText((delta > 0 ? "+" : "") + delta.toStringAsFixed(1));
        canvas.drawParagraph(
            p.build()..layout(const ui.ParagraphConstraints(width: 30)),
            Offset(dx + radius + 3, dy - radius + 7));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
