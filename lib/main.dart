import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'pocket/main.dart';
import 'learn/animated.dart';
import 'health/health_v2.dart';
import 'learn/game.dart';
import 'learn/snh.dart';

import 'learn/data.dart';

void main() {
  //runApp(const SNHApp());
  //runApp(LearnAsync());
  /*var some = Future.delayed(Duration(seconds: 10), () {
    print("HELLO");
    return 10;
  });*/
  //runApp(const MyApp());
  //runApp(const LearnAnimation());
  runApp(CMPocket.call());
  /*runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Home1(),
  ));*/
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget ww = const Scaffold(
    body: Center(
      child: Text(
        "正在加载...",
        style: TextStyle(fontSize: 20),
      ),
    ),
  );

  @override
  void initState() {
    Info.readData().then((value) => {
          setState(() {
            ww = Game(info: value);
            //ww = HealthCard(info: value, scoreEvent: StreamController());
          })
        });
    super.initState();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: ww, //const MyHomePage(title: 'CyberMe'),
    );
  }
}
