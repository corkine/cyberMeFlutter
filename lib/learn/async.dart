import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class LearnAsync extends StatefulWidget {
  const LearnAsync({Key? key}) : super(key: key);

  @override
  State<LearnAsync> createState() => _LearnAsyncState();
}

class _LearnAsyncState extends State<LearnAsync> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      backgroundColor: Colors.brown,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.security_outlined),
      ),
      body: Me(),
    ));
  }
}

class Me extends StatefulWidget {
  Me({Key? key}) : super(key: key);

  @override
  State<Me> createState() => _MeState();
}

class _MeState extends State<Me> {
  StreamController controller = StreamController.broadcast();

  Stream<int> genId(int end) async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      yield Random().nextInt(end);
    }
  }

  @override
  void initState() {
    controller.stream.listen((event) {
      print("Listen $event");
    });
    genId(100).listen((event) {
      print("Gen $event");
    });
    super.initState();
  }

  @override
  void dispose() {
    controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 100),
      child: DefaultTextStyle(
        style: Theme.of(context).primaryTextTheme.headline1!,
        child: Center(
          child: Column(
            children: [
              StreamBuilder(
                stream:
                controller.stream.transform(MyST()),
                /*controller.stream
                .where((event) => event % 2 == 0)
                .map((event) => event * 10)
                .distinct()*/
                builder: (context, snap) {
                  switch (snap.connectionState) {
                    case ConnectionState.none:
                      return const Text("No stream");
                    case ConnectionState.waiting:
                      return const Text("Waiting stream");
                    case ConnectionState.active:
                      if (snap.hasError) {
                        return Text("Stream Error ${snap.error}");
                      } else {
                        return Text("${snap.data}");
                      }
                    case ConnectionState.done:
                      return const Text("Stream done");
                  }
                },
              ),
              const SizedBox(height: 100,),
              TextButton(
                  onPressed: () {
                    controller.sink.add(Random().nextInt(100));
                  },
                  child: const Text("写入数据")),
              TextButton(
                  onPressed: () {
                    controller.sink.addError(Exception("Oops!"));
                  },
                  child: const Text("写入错误")),
              TextButton(
                  onPressed: () {
                    controller.sink.close();
                  },
                  child: const Text("关闭写入"))
            ],
          ),
        ),
      ),
    );
  }
}

class MyST extends StreamTransformerBase {

  int sum = 0;
  StreamController controller = StreamController();
  @override
  Stream bind(Stream stream) {
    stream.listen((event) {
      sum += event as int;
      controller.add(sum);
    });
    return controller.stream;
  }

  @override
  StreamTransformer<RS, RT> cast<RS, RT>() =>
      StreamTransformer.castFrom(this);

}

class MyST2 extends StreamTransformerBase {
  StreamController controller = StreamController();
  late int lastNum;
  @override
  Stream bind(Stream stream) {
    stream.listen((event) {
      /*controller.stream
          .where((event) => event % 2 == 0)
          .map((event) => event * 10)
          .distinct()*/
      if (event is int && event != lastNum && event % 2 == 0) {
        controller.add(event * 10);
      }
      lastNum = event;
    });
    return controller.stream;
  }
  @override
  StreamTransformer<RS, RT> cast<RS, RT>() =>
      StreamTransformer.castFrom(this);

}
