import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:health/health.dart';

class BodyMassView extends StatefulWidget {
  const BodyMassView({super.key});

  @override
  State<BodyMassView> createState() => _BodyMassViewState();
}

class _BodyMassViewState extends State<BodyMassView> {
  List<double> recentBodyMass = [];

  @override
  void initState() {
    super.initState();
    handleReadBodyMassRecent();
  }

  bool get nonAvailableData => recentBodyMass.length <= 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Body Mass"), centerTitle: true),
        body: Column(children: [
          const SizedBox(height: 10),
          Row(children: [
            const SizedBox(width: 16),
            Text("近期体重趋势", style: Theme.of(context).textTheme.bodyLarge)
          ]),
          const SizedBox(height: 10),
          SizedBox(
              width: MediaQuery.of(context).size.width - 30,
              height: MediaQuery.of(context).size.height / 3.5,
              child: CustomPaint(
                  painter: ViewPainter(recentBodyMass),
                  child: nonAvailableData
                      ? const Center(child: Text("数据不足，再收集些数据后再来吧"))
                      : null)),
          const Spacer(),
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
                          decoration: BoxDecoration(
                              color: const Color.fromARGB(40, 17, 126, 13),
                              borderRadius: BorderRadius.circular(3)),
                          autocorrect: false,
                          autofocus: true,
                          showCursor: true,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          suffix: const Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Text("kg",
                                  style: TextStyle(fontFamily: "consolas"))),
                        ))
                  ]),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.black45),
                      borderRadius: BorderRadius.circular(30)))),
          const SizedBox(height: 100)
        ]));
  }

  handleReadBodyMassRecent() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final health = HealthFactory(useHealthConnectIfAvailable: false);
      var types = [HealthDataType.WEIGHT];
      var permissions = [HealthDataAccess.READ_WRITE];
      bool req =
      await health.requestAuthorization(types, permissions: permissions);
      if (req) {
        final now = DateTime.now();
        final start = now.subtract(const Duration(days: 30));
        final data = await health.getHealthDataFromTypes(start, now, types);
        final takeData = data.getRange(
            data.length - 7 >= 0 ? data.length - 7 : 0, data.length);
        recentBodyMass = [];
        for (final d in takeData) {
          final v = (d.value as NumericHealthValue?)?.numericValue;
          debugPrint(
              "date: ${d.dateFrom}, value: ${v.toString()}, unit: ${d.unit.name}");
          if (v != null) {
            recentBodyMass.add(v as double);
          }
        }
        setState(() {});
      } else {
        recentBodyMass = [];
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("没有 HealthKit 读取权限，请检查后再试！")));
      }
    }
  }

  handleWriteBodyMass(double value) async {
    if (Platform.isIOS || Platform.isAndroid) {
      final health = HealthFactory(useHealthConnectIfAvailable: false);
      var types = [HealthDataType.WEIGHT];
      var permissions = [HealthDataAccess.READ_WRITE];
      bool req =
          await health.requestAuthorization(types, permissions: permissions);
      if (req) {
        final now = DateTime.now();
        bool success = await health.writeHealthData(
            value, HealthDataType.WEIGHT, now, now);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("更新数据 ${value.toStringAsFixed(1)} 结果：$success。")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("没有 HealthKit 写入权限，请检查后再试！")));
      }
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
            ..color = i == 0 || i == lastIdx ? Colors.red : Colors.grey);
      if (i == 0) {
        final p = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 13))
          ..pushStyle(ui.TextStyle(color: Colors.grey))
          ..addText((bodyMass[i]).toStringAsFixed(1));
        canvas.drawParagraph(
            p.build()..layout(const ui.ParagraphConstraints(width: 30)),
            Offset(dx + radius + 3, dy - radius + 6));
      } else if (i == lastIdx) {
        final p = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 13))
          ..pushStyle(ui.TextStyle(color: Colors.grey))
          ..addText((bodyMass[i] - bodyMass[0]).toStringAsFixed(1));
        canvas.drawParagraph(
            p.build()..layout(const ui.ParagraphConstraints(width: 30)),
            Offset(dx + radius + 3, dy - radius + 6));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
