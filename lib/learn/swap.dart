import 'dart:math';

import 'package:flutter/material.dart';
import 'package:swipable_stack/swipable_stack.dart';

class Home1 extends StatefulWidget {
  const Home1({Key? key}) : super(key: key);

  @override
  State<Home1> createState() => _Home1State();
}

class _Home1State extends State<Home1> {
  List<String> images = ["images/dash/lol.png", "images/dash/comb.png", "images/dash/mirror-ball.png"];
  late final SwipableStackController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SwipableStackController();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        color: Colors.white,
        padding: const EdgeInsets.only(top: 100),
        child: Container(
          width: 200,
          child: SwipableStack(
            controller: _controller,
            stackClipBehaviour: Clip.none,
            allowVerticalSwipe: true,
            builder: (context, properties) {
              print("prop: ${properties.index}, images is ${images[properties.index % 3]}");
              return Container(
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const[BoxShadow(blurRadius: 10, spreadRadius: 0.1,
                        color: Colors.black26)]
                ),
                padding: const EdgeInsets.only(top: 20, bottom: 20, left: 10, right: 10),
                child: Image.asset(images[properties.index % 3]),
              );
            },
            onSwipeCompleted: (index, direction) {
              print('$index, $direction');
            },
            overlayBuilder: (context, properties) {
              final opacity = min(properties.swipeProgress, 1.0);
              final isRight = properties.direction == SwipeDirection.right;
              return Opacity(
                opacity: isRight ? opacity : 0,
                child: const Text("Hello"),
              );
            },
            swipeAssistDuration: const Duration(milliseconds: 100),
          ),
        ),
      ),
    );
  }
}
