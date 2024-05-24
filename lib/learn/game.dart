import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cyberme_flutter/health/data.dart';

import '../health/health_v2.dart';

class Game extends StatefulWidget {
  final Info? info;

  const Game({Key? key, required this.info}) : super(key: key);

  @override
  State<Game> createState() => _GameState();
}

class _GameState extends State<Game> {
  StreamController typedEvent = StreamController.broadcast();
  StreamController scoreEvent = StreamController.broadcast();

  @override
  void dispose() {
    typedEvent.close();
    scoreEvent.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            if (Info.needShow) {
              Info.needShow = false;
              Info.readData().then((value) =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (c) {
                    return HealthCard(info: value, scoreEvent: scoreEvent);
                  })));
            }
          },
          child: StreamBuilder(
            stream: scoreEvent.stream.transform(ReduceAdd()),
            builder: (c, s) {
              if (s.connectionState == ConnectionState.active) {
                if (s.data != null && s.data as num > 30 && !Info.needShow) {
                  Info.needShow = true;
                  print("reset needShow to ${Info.needShow}");
                }
                return Text("Score: ${s.data}");
              }
              return const Text("Type to Play!");
            },
          ),
        ),
      ),
      body: Stack(
        children: [
          ...List.generate(
              10,
              (index) => Puzzle(
                    typedEvent: typedEvent,
                    scoreEvent: scoreEvent,
                  )),
          Container(
            alignment: Alignment.bottomCenter,
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              shrinkWrap: true,
              childAspectRatio: 2,
              children: List.generate(
                  9,
                  (index) => Container(
                        color: Colors.primaries[Random().nextInt(18)][200],
                        child: TextButton(
                            onPressed: () {
                              typedEvent.sink.add(index + 1);
                              scoreEvent.sink.add(-2); //防止乱按
                            },
                            child: Text(
                              "${index + 1}",
                              style: const TextStyle(
                                  fontSize: 24, color: Colors.white),
                            )),
                      )),
            ),
          )
        ],
      ),
    );
  }
}

// ignore: must_be_immutable
class Puzzle extends StatefulWidget {
  StreamController typedEvent;
  StreamController scoreEvent;

  Puzzle({Key? key, required this.typedEvent, required this.scoreEvent})
      : super(key: key);

  @override
  State<Puzzle> createState() => _PuzzleState();
}

class _PuzzleState extends State<Puzzle>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late int a, b;
  late double x;
  late Color color;

  late AnimationController controller;

  reset() {
    a = Random().nextInt(5) + 1;
    b = Random().nextInt(5);
    x = Random().nextDouble() * 300;
    color = Colors.primaries[Random().nextInt(18)][200]!;
    controller.duration = Duration(milliseconds: Random().nextInt(5000) + 5000);
  }

  @override
  void initState() {
    //用于控制 AnimatedBuilder 实现位置移动
    controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    reset();
    controller.forward(from: Random().nextDouble());
    //当动画完毕后，重新 forward 到顶部
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        reset();
        controller.forward(from: 0.0);
      }
    });
    widget.typedEvent.stream.listen((event) {
      if (event == a + b) {
        reset();
        controller.forward(from: 0.0);
        widget.scoreEvent.sink.add(10);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnimatedBuilder(
        animation: controller,
        builder: (c, child) => Positioned(
              left: x,
              top: 800 * controller.value - 100,
              child: Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.5),
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(8),
                child: Text(
                  "$a + $b",
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ));
  }

  @override
  bool get wantKeepAlive => false;
}

class ReduceAdd extends StreamTransformerBase {
  int sum = 0;
  StreamController controller = StreamController();

  @override
  Stream bind(Stream stream) {
    stream.listen((event) {
      if (event == "reset!") {
        sum = 0;
        controller.add(sum);
      }
      if (event is int) {
        sum += event;
        controller.add(sum);
      }
    });
    return controller.stream;
  }

  @override
  StreamTransformer<RS, RT> cast<RS, RT>() => StreamTransformer.castFrom(this);
}
