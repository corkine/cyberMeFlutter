import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TestApp extends StatelessWidget {
  const TestApp({Key? key}) : super(key: key);

  Widget Function(BuildContext) page(String info) =>
      (BuildContext context) => Scaffold(
          body:
              Center(child: Text(info, style: const TextStyle(fontSize: 30))));

  TextButton goto(BuildContext context, String routeName) => TextButton(
      onPressed: () {
        Navigator.of(context).pushNamed(routeName);
      },
      child: Text("Goto $routeName"));

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: Container(
                    width: double.infinity,
                    color: Colors.pink[100],
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          goto(context, "/a"),
                          goto(context, "/b"),
                          goto(context, "/page"),
                          goto(context, "/page/c"),
                          goto(context, "/d"),
                          goto(context, "/pop")
                        ])))),
        routes: <String, WidgetBuilder>{
          "/a": page("/a"),
          "/b": page("/b"),
          "/page/c": page("/page/c"),
          "/pop": (context) => Scaffold(
                body: Center(
                  child: WillPopScope(
                      onWillPop: () async {
                        return await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("是否要关闭页面？"),
                                content: const Text("很危险的操作！！！"),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text("取消")),
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text("确定"))
                                ],
                              ),
                            ) ??
                            false;
                      },
                      child: TextButton(
                          child: const Text("Pop!"),
                          onPressed: () => Navigator.of(context).pop())),
                ),
              )
        },
        onGenerateRoute: (RouteSettings settings) {
          if (settings.name == "/user") {
            return MaterialPageRoute(builder: page("/user"));
          }
          return null;
        },
        onUnknownRoute: (RouteSettings settings) {
          return MaterialPageRoute(builder: page("404"));
        });
  }
}

class Test2 extends StatefulWidget {
  const Test2({Key? key}) : super(key: key);

  @override
  State<Test2> createState() => _Test2State();
}

class _Test2State extends State<Test2> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DraggableScrollableSheet(builder: (context, scrollController) {
        return Container(
          color: Colors.grey,
          child: ListView(
            controller: scrollController,
            children:
                List.generate(100, (index) => const FlutterLogo(size: 70)),
          ),
        );
      }),
    );
  }
}

class Test extends StatefulWidget {
  const Test({Key? key}) : super(key: key);

  @override
  State<Test> createState() => _TestState();
}

class _TestState extends State<Test> {
  final link = LayerLink();

  @override
  void initState() {
    entry = OverlayEntry(builder: (context) {
      return Center(
        child: CompositedTransformFollower(
          link: link,
          showWhenUnlinked: false,
          offset: const Offset(10, 10),
          child: Container(
            width: 100,
            height: 100,
            color: Colors.brown,
          ),
        ),
      );
    });
    super.initState();
  }

  @override
  void dispose() {
    entry.dispose();
    super.dispose();
  }

  late OverlayEntry entry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hello"),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Image.network(
                  "https://mazhangjing.com/static/cover-leaf.jpg",
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const CupertinoActivityIndicator(
                      animating: true,
                      radius: 20,
                      color: Colors.red,
                    );
                  },
                ),
              ),
              // CompositedTransformTarget(
              //     link: link,
              //     child: const Icon(
              //       Icons.star,
              //       size: 40,
              //     )),
              /*Row(
                children: [
                  CupertinoButton(
                      child: const Text("Show"),
                      onPressed: () {
                        Overlay.of(context)!.insert(entry);
                      }),
                  CupertinoButton(
                      child: const Text("Hide"),
                      onPressed: () {
                        entry.remove();
                      })
                ],
              ),*/
              const Padding(
                padding: EdgeInsets.all(18.0),
                child: CupertinoTextField(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Colors.lightGreen, Colors.white]),
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  padding: EdgeInsets.all(10),
                  prefix: Padding(
                      padding: EdgeInsets.only(left: 10, right: 0),
                      child: Text("https://")),
                  suffix: Icon(
                    CupertinoIcons.star,
                    size: 20,
                  ),
                ),
              ),
              const CupertinoButton(
                  child: Text("Hello World"), onPressed: null),
              CupertinoButton(
                  child: const Text("Hello World"), onPressed: () {}),
              CupertinoButton.filled(
                  child: const Text("Show Dialog"),
                  onPressed: () async {
                    Widget Function(BuildContext) page(String info) =>
                        (BuildContext context) => Scaffold(
                            body: Center(
                                child: Text(info,
                                    style: const TextStyle(fontSize: 30))));
                    TextButton goto(BuildContext context, String routeName) =>
                        TextButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed(routeName);
                            },
                            child: Text("Goto $routeName"));
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => MaterialApp(
                            home: Scaffold(
                                body: Container(
                              width: double.infinity,
                              color: Colors.grey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  goto(context, "/a"),
                                  goto(context, "/b"),
                                  goto(context, "/page"),
                                  goto(context, "/page/c"),
                                  goto(context, "/d")
                                ],
                              ),
                            )),
                            routes: <String, WidgetBuilder>{
                              "/a": page("/a"),
                              "/b": page("/b"),
                              "/page/c": page("/page/c"),
                            },
                            onGenerateRoute: (RouteSettings settings) {
                              if (settings.name == "/user") {
                                return MaterialPageRoute(
                                    builder: page("/user"));
                              }
                              return null;
                            },
                            onUnknownRoute: (RouteSettings settings) {
                              return MaterialPageRoute(builder: page("404"));
                            })));
                    return;
                    Builder(
                      builder: (context) => const Text("Hello World"),
                    );
                    StatefulBuilder(
                      builder: (context, setState) => TextButton(
                        onPressed: () => setState(() => {}),
                        child: const Text("Hello"),
                      ),
                    );
                    final result = await showCupertinoModalPopup(
                        context: context,
                        builder: (context) => CupertinoActionSheet(
                              title: const Text("选择一项"),
                              message: const Text("你听/用过如下的 JVM 语言吗？"),
                              actions: [
                                CupertinoActionSheetAction(
                                    isDefaultAction: true,
                                    onPressed: () {},
                                    child: const Text("Java")),
                                CupertinoActionSheetAction(
                                    onPressed: () {},
                                    child: const Text("Scala")),
                                CupertinoActionSheetAction(
                                    onPressed: () {},
                                    child: const Text("Clojure"))
                              ],
                              cancelButton: CupertinoActionSheetAction(
                                isDestructiveAction: true,
                                onPressed: () =>
                                    Navigator.of(context).pop(null),
                                child: const Text("都没听过"),
                              ),
                            ));
                    print(result);
                  }),
            ],
          ),
        ),
      ),
    );
  }
}

class MyInfo extends InheritedWidget {
  final Color color;

  const MyInfo({Key? key, required this.color, required Widget child})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant MyInfo oldWidget) =>
      oldWidget.color != color;

  static MyInfo? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MyInfo>();
}

class MyTriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(50, 50)
    ..lineTo(50, 10)
    ..lineTo(100, 50)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}
