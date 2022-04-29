import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:rive/rive.dart';

class LearnAnimation extends StatelessWidget {
  const LearnAnimation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HelloRive(),
    );
  }
}

class HelloRive extends StatefulWidget {
  const HelloRive({Key? key}) : super(key: key);

  @override
  State<HelloRive> createState() => _HelloRiveState();
}

class _HelloRiveState extends State<HelloRive> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: const Center(
          child: RiveAnimation.asset("images/bird.riv",
          animations: ['idle'],
          ),
        ),
      ),
    );
  }
}


class HelloTicker extends StatefulWidget {
  const HelloTicker({Key? key}) : super(key: key);

  @override
  State<HelloTicker> createState() => _HelloTickerState();
}

class _HelloTickerState extends State<HelloTicker>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  List<Snowflake> snowList = List.generate(100, (index) => Snowflake());

  @override
  void initState() {
    controller =
        AnimationController(duration: const Duration(seconds: 4), vsync: this)
          ..repeat();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          decoration: const BoxDecoration(
            color: Colors.blue,
            /*gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue, Colors.blueAccent, Colors.white],
              stops: [0, 0.8, 0.95]
            )*/
          ),
          height: double.infinity,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              for (var element in snowList) {
                element.fall();
              }
              return CustomPaint(
                painter: MyPainter(snowList),
              );
            },
          )),
    );
  }
}

class MyPainter extends CustomPainter {
  final List<Snowflake> snowList;

  MyPainter(this.snowList);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    canvas.drawOval(
        Rect.fromCenter(
            center: size.center(const Offset(0, 210)), width: 90, height: 90),
        paint);
    canvas.drawOval(
        Rect.fromCenter(
            center: size.center(const Offset(0, 340)), width: 150, height: 200),
        paint);
    for (var s in snowList) {
      canvas.drawCircle(Offset(s.x, s.y), s.r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class Snowflake {
  double x = Random().nextDouble() * 400;
  double y = Random().nextDouble() * 600;
  double r = Random().nextInt(3) + 1;
  double v = Random().nextDouble() * 4 + 2;

  fall() {
    y += v;
    if (y > 800) {
      y = 0;
      x = Random().nextDouble() * 400;
      r = Random().nextInt(4) + 1;
      v = Random().nextDouble() * 4 + 2;
    }
  }
}

class MyAni extends StatefulWidget {
  const MyAni({Key? key}) : super(key: key);

  @override
  State<MyAni> createState() => _MyAniState();
}

class _MyAniState extends State<MyAni> with TickerProviderStateMixin {
  late AnimationController controller, opController;

  late Animation a1, a2, a3;

  @override
  void initState() {
    controller =
        AnimationController(duration: const Duration(seconds: 4), vsync: this);
    opController =
        AnimationController(duration: const Duration(seconds: 4), vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    opController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    a1 = Tween(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: const Interval(0.0, 0.2)))
        .animate(controller);
    a2 = Tween(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: const Interval(0.2, 0.4)))
        .animate(controller);
    a3 = Tween(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: const Interval(0.4, 0.95)))
        .animate(controller);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
          onPressed: () async {
            controller.duration = const Duration(seconds: 4);
            controller.forward();
            await Future.delayed(const Duration(seconds: 4));

            opController.duration = const Duration(milliseconds: 1000);
            opController.repeat(reverse: true);
            await Future.delayed(const Duration(seconds: 7));
            opController.reset();

            controller.duration = const Duration(seconds: 8);
            controller.reverse();
          },
          child: const Icon(Icons.add)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: FadeTransition(
            opacity: Tween(begin: 1.0, end: 0.5).animate(opController),
            child: AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  return Container(
                    width: 300,
                    height: 300,
                    /*decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                        gradient: RadialGradient(colors: [
                          Colors.blue[600]!,
                          Colors.blue[100]!
                        ], stops: *//*controller.value <= 0.2
                                ? [a1.value, a1.value + 0.1]
                                : [a3.value, a3.value + 0.1]*//*
                            [
                          controller.value,
                          controller.value + 0.1
                        ])),*/
                  );
                }),
          ),
        ),
      ),
    );
  }
}
