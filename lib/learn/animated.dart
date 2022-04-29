import 'package:flutter/material.dart';

class LearnAnimation extends StatelessWidget {
  const LearnAnimation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyAni(),
    );
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
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                        gradient: RadialGradient(colors: [
                          Colors.blue[600]!,
                          Colors.blue[100]!
                        ], stops: /*controller.value <= 0.2
                                ? [a1.value, a1.value + 0.1]
                                : [a3.value, a3.value + 0.1]*/
                            [
                          controller.value,
                          controller.value + 0.1
                        ])),
                  );
                }),
          ),
        ),
      ),
    );
  }
}
