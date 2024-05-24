import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomeMe extends StatelessWidget {
  const HomeMe({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 100, bottom: 140),
      child: SingleChildScrollView(
        child: Column(
          children: [
            CupertinoContextMenu(
                actions: [
                  CupertinoContextMenuAction(
                      isDefaultAction: true,
                      child: const Text("Open"),
                      onPressed: () {}),
                  CupertinoContextMenuAction(
                      isDestructiveAction: true,
                      child: const Text("Remove"),
                      onPressed: () {})
                ],
                child: const FlutterLogo(
                  size: 140,
                )),
            const SizedBox(
              height: 100,
            ),
            SizedBox(
              height: 100,
              child: CupertinoDatePicker(
                onDateTimeChanged: (d) {},
                mode: CupertinoDatePickerMode.date,
              ),
            ),
            const SizedBox(
              height: 100,
            ),
            ClipPath(
              clipper: MyClipper(),
              child: Padding(
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
            ),
            Opacity(
              opacity: 0.7,
              child: ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (Rect b) => const RadialGradient(colors: [
                  Colors.indigo,
                  Colors.blue,
                  Colors.green,
                  Colors.yellow,
                  Colors.orange,
                  Colors.red
                ], radius: 0.7, center: Alignment(0.2, 0.7))
                    .createShader(b),
                child: const FlutterLogo(
                  size: 128,
                ),
              ),
            ),
            SizedBox(
              height: 100,
              child: CupertinoPicker(
                itemExtent: 25,
                children: List.generate(20, (index) => Text("第 $index 项")),
                onSelectedItemChanged: (v) {},
              ),
            ),
            CupertinoSlider(value: 0.3, onChanged: (v) {}),
            CupertinoSwitch(value: true, onChanged: (v) {}),
            CupertinoSwitch(value: false, onChanged: (v) {}),
            CupertinoSlidingSegmentedControl(
                groupValue: "wifi",
                padding: const EdgeInsets.all(10),
                children: const {
                  "1": Text("No.1"),
                  "wifi": Icon(Icons.wifi),
                  "blueTooth": Icon(Icons.bluetooth)
                },
                onValueChanged: (v) {})
          ],
        ),
      ),
    );
  }
}

class MyClipper extends CustomClipper<Path> {
  @override
  ui.Path getClip(Size size) => Path()
    ..lineTo(0, size.height) //左上角到左下角
    ..quadraticBezierTo(
        size.width / 8, size.height / 4, size.width, size.height)
    ..lineTo(size.width, 0) //右下角到右上角
    ..close();
  //for debug
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

class TestApp extends StatelessWidget {
  TestApp({Key? key}) : super(key: key);

  Widget Function(BuildContext) page(String info) =>
      (BuildContext context) => Scaffold(
          body:
              Center(child: Text(info, style: const TextStyle(fontSize: 30))));

  TextButton goto(BuildContext context, String routeName) => TextButton(
      onPressed: () {
        Navigator.of(context).pushNamed(routeName);
      },
      child: Text("Goto $routeName"));

  String value = "java";

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      home: CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          items: const [
            BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.phone), label: "Calls"),
            BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.mail), label: "Mail"),
            BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.calendar), label: "Calendar"),
          ],
        ),
        tabBuilder: (context, index) => CupertinoTabView(
          builder: (context) => const CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Text("Hello World"),
            ),
            child: HomeMe(),
          ),
        ),
      ),
    );
/*
    return MaterialApp(
      home: Builder(
        builder: (context) =>
            Scaffold(
              appBar: AppBar(),
              body: Center(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Stepper(
                        currentStep: 2,
                        steps: const [
                          Step(title: Text("步骤1"), content: Text("内容1")),
                          Step(title: Text("步骤2"), content: Text("内容2")),
                          Step(title: Text("步骤3"), content: Text("内容3")),
                          Step(title: Text("步骤4"), content: Text("内容4"))
                        ],
                      ),
                      Card(
                        elevation: 3,
                        color: Colors.pink[100],
                        shadowColor: Colors.blue[100],
                        shape: const StadiumBorder(),
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 15, right: 15, top: 5, bottom: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text("新加坡总理李显龙今日访华"),
                              Text("2022 年 10 月 1 日")
                            ],
                          ),
                        ),
                      ),
                      Checkbox(value: true, onChanged: (e) {}),
                      Checkbox(value: false, onChanged: (e) {}),
                      Checkbox(
                        value: null,
                        onChanged: (e) {},
                        tristate: true,
                      ),
                      DataTable(
                        columns: [
                          DataColumn(
                              label: const Text("姓名"),
                              tooltip: "HELLO",
                              numeric: false,
                              onSort: (e, o) {}),
                          const DataColumn(label: Text("单位")),
                          const DataColumn(label: Text("邮箱"))
                        ],
                        rows: [
                          DataRow(
                              cells: [
                                const DataCell(Text("Corkine"),
                                    showEditIcon: true),
                                const DataCell(Text("Inspur Cisco"),
                                    placeholder: true),
                                DataCell(const Text("corkine@inspur.com"),
                                    onTap: () {})
                              ],
                              selected: true,
                              onSelectChanged: (b) {},
                              color: MaterialStateProperty.all(Colors.red)),
                          const DataRow(cells: [
                            DataCell(Text("Corkine")),
                            DataCell(Text("Inspur Cisco")),
                            DataCell(Text("corkine@inspur.com"))
                          ])
                        ],
                        headingTextStyle: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      TextButton(
                          child: const Text("showDataPicker"),
                          onPressed: () async {
                            final res = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate:
                                DateTime.now().add(const Duration(days: 0)),
                                lastDate:
                                DateTime.now().add(const Duration(days: 10)));
                            print("Choose $res");
                            return;
                          }),
                      DropdownButton(
                        items: const [
                          DropdownMenuItem(
                            child: Text("中文"),
                            value: "zh",
                          ),
                          DropdownMenuItem(
                            child: Text("英文"),
                            value: "us",
                          ),
                          DropdownMenuItem(
                            child: Text("法语"),
                            value: "fa",
                          )
                        ],
                        onChanged: (v) {},
                        hint: const Text("选择语言"),
                        value: "zh",
                      ),
                      ExpandIcon(
                        onPressed: (e) {},
                        isExpanded: true,
                        size: 30,
                        padding: const EdgeInsets.all(10),
                        color: Colors.red,
                        disabledColor: Colors.pink,
                        expandedColor: Colors.blue,
                      ),
                      Slider(
                          value: 2,
                          onChanged: (v) {},
                          min: 0,
                          max: 10,
                          divisions: 10,
                          label: "标签1"),
                      TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content:
                                const Text("Hello World"),
                                  action: SnackBarAction(
                                    label: "OK",
                                    onPressed: () {},
                                    textColor: Colors.white,
                                  ),)
                            );
                          }, child: const Text("Show SnackBar")),
                      RangeSlider(
                          values: const RangeValues(0.2, 0.8),
                          onChanged: (value) {}),
                      Ink(
                        decoration: const ShapeDecoration(
                            color: Colors.pink, shape: CircleBorder()),
                        child: IconButton(
                            icon: const Icon(
                                Icons.refresh, color: Colors.white),
                            onPressed: () {}),
                      ),
                      Tooltip(
                          message: "这里是一些说明文字",
                          //richMessage: const TextSpan(text: "RichText 支持"),
                          padding: const EdgeInsets.all(3),
                          margin: const EdgeInsets.all(3),
                          preferBelow: true,
                          height: 40,
                          waitDuration: const Duration(seconds: 2),
                          showDuration: const Duration(seconds: 2),
                          enableFeedback: true,
                          child: Switch(value: false, onChanged: (v) {})),
                      Switch(value: true, onChanged: (v) {}),
                      CupertinoSwitch(value: true, onChanged: (v) {}),
                      Switch.adaptive(value: false, onChanged: (v) {}),
                      StatefulBuilder(
                          builder: (context, setState) =>
                              Row(
                                children: [
                                  Radio(
                                      value: "java",
                                      groupValue: value,
                                      onChanged: (v) =>
                                          setState(() {
                                            value = v as String;
                                          })),
                                  const Text("Java"),
                                  Radio(
                                      value: "clojure",
                                      groupValue: value,
                                      onChanged: (v) =>
                                          setState(() {
                                            value = v as String;
                                          })),
                                  const Text("Clojure"),
                                ],
                              )),
                      ToggleButtons(
                        children: const [
                          Icon(Icons.add),
                          Icon(Icons.remove),
                          Icon(Icons.delete),
                          Icon(Icons.star)
                        ],
                        isSelected: const [true, false, true, true],
                        selectedColor: Colors.blue,
                        onPressed: (v) {},
                      ),
                      const ExpansionTile(
                        title: Text("看我有什么？"),
                        children: [
                          FlutterLogo(size: 30),
                          FlutterLogo(size: 30)
                        ],
                      ),
                      CheckboxListTile(
                        value: true,
                        onChanged: (v) {},
                        title: const Text("选择我"),
                        subtitle: const Text("我是 xxx"),
                      ),
                      OutlinedButton(
                          onPressed: () {}, child: const Text("Hello")),
                      OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.star),
                          label: const Text("Hello"))
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
*/
/*
    return MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(automaticallyImplyLeading: false,),
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
*/
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
