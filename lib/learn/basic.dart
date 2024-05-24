// ignore_for_file: unused_local_variable

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class Demo2 extends StatefulWidget {
  const Demo2({Key? key}) : super(key: key);

  @override
  State<Demo2> createState() => _Demo2State();
}

class _Demo2State extends State<Demo2> {
  @override
  Widget build(BuildContext context) {
    const g1 = SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, childAspectRatio: 16 / 9);
    final gc1 = GridView.builder(
        itemCount: 200,
        gridDelegate: g1,
        itemBuilder: (_, i) => Container(
              color: Colors.orange[i % 8 * 100],
            ));
    const g2 = SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 80, //交叉轴每个元素最大宽度
        childAspectRatio: 16 / 9);
    //等价于 GridView.extent, 不过其不支持动态加载了
    final gc2 = GridView.extent(
      maxCrossAxisExtent: 80,
      children: List.generate(
          200, (i) => Container(color: Colors.orange[i % 8 * 100])),
    );
    //此外还有 GridView.count, 等价于 g1 的语法糖
    final gc3 = GridView.count(
      crossAxisCount: 4,
      childAspectRatio: 1 / 1,
      mainAxisSpacing: 2.0,
      crossAxisSpacing: 4.0,
      children: [
        Icons.title,
        Icons.person,
        Icons.print,
        Icons.phone,
        Icons.sms,
        Icons.build
      ]
          .map((e) => Container(
                child: Icon(
                  e,
                  color: Colors.white,
                ),
                color: Colors.blue,
              ))
          .toList(),
    );
    var ls = ListWheelScrollView(
        overAndUnderCenterOpacity: 0.5,
        //其他透明效果
        magnification: 1.5,
        //当前放大效果
        useMagnifier: true,
        //使用放大效果
        itemExtent: 100,
        //物理效果，用于精确停留在某个元素上
        physics: const FixedExtentScrollPhysics(),
        //选择某个项目的回调
        onSelectedItemChanged: (index) => print("Now select $index"),
        children: List.generate(
            30,
            (index) => Container(
                  color: Colors.blue,
                  alignment: Alignment.center,
                  child: Center(
                      child: Text(
                    "Hello $index",
                    style: Theme.of(context).primaryTextTheme.headlineSmall,
                  )),
                )).toList());
    //可以将其文字和列表转动
    var ls2 = RotatedBox(
      quarterTurns: 1,
      child: ListWheelScrollView(
        physics: const FixedExtentScrollPhysics(),
        itemExtent: 100,
        children: List.generate(
            10,
            (index) => RotatedBox(
                  quarterTurns: -1,
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      "$index",
                      style: const TextStyle(fontSize: 72),
                    ),
                  ),
                )).toList(),
      ),
    );
    var pv = PageView(
      scrollDirection: Axis.vertical, //滚动方向
      pageSnapping: true, //半页自动滚动
      onPageChanged: (index) => print("Now is $index"),
      children: List.generate(
          4,
          (index) => Container(
                color: Colors.primaries[index][100],
                child: Center(
                  child: Text(
                    "$index",
                    style: Theme.of(context).primaryTextTheme.headlineMedium,
                  ),
                ),
              )),
    );
    var rl = ReorderableListView(
        header: const Text(
          "Something HERE",
          style: TextStyle(color: Colors.red),
        ),
        children: List.generate(
            100,
            (index) => Container(
                  key: UniqueKey(),
                  height: 100,
                  color: Colors.blue[index % 8 * 100],
                )),
        onReorder: (o, n) {});
    //SingleChildScrollView 用于避免意外布局不足需要滚动的情况
    //其不同于 ListView，后者哪怕元素不足滚动也支持拖拽，而 SCSV
    //则仅限于超出屏幕宽度的滚动。
    var cs = const SingleChildScrollView(
      child: Column(
        children: <Widget>[
          FlutterLogo(
            size: 400,
          ),
          FlutterLogo(
            size: 400,
          )
        ],
      ),
    );
    return Scaffold(
      body: cs,
    );
  }
}

class Demo extends StatefulWidget {
  const Demo({Key? key}) : super(key: key);

  @override
  State<Demo> createState() => _DemoState();
}

class Website {
  String name;
  String websiteUrl;
  String? websiteNote;
  int websiteId;
  int healthy;
  int activityCount;
  String from;
  String end;

  Website(this.name, this.websiteUrl, this.websiteNote, this.websiteId,
      this.healthy, this.activityCount, this.from, this.end);

  Website.of(j)
      : this(j["name"], j["websiteUrl"], j["websiteNote"], j["websiteId"],
            j["healthy"], j["activityCount"], j["from"], j["end"]);

  @override
  String toString() {
    return 'Website{name: $name, websiteUrl: $websiteUrl, websiteNote: $websiteNote, websiteId: $websiteId, healthy: $healthy, activityCount: $activityCount, from: $from, end: $end}';
  }
}

class _DemoState extends State<Demo> {
  final List<Website> _data = [];

  Future fetch() async {
    final res =
        await http.get(Uri.parse("https://status.mazhangjing.com/status"));
    if (res.statusCode == 200) {
      print(res.body);
      final data = (jsonDecode(res.body) as List).map((e) => Website.of(e));
      print(data);
      setState(() {
        _data.clear();
        _data.addAll(data);
      });
    }
  }

  @override
  void initState() {
    fetch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hello World"),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.ac_unit),
        onPressed: fetch,
      ),
      body: RefreshIndicator(
        onRefresh: fetch,
        child: Scrollbar(
          child: ListView(
            children: _data
                .map<Widget>((e) => Dismissible(
                      key: ValueKey(e.websiteId),
                      onDismissed: (d) {
                        setState(() {
                          _data.removeWhere(
                              (element) => element.websiteId == e.websiteId);
                        });
                      },
                      confirmDismiss: (_) async {
                        return showDialog(
                            context: context,
                            builder: (_) {
                              return AlertDialog(
                                title: const Text("确定删除吗？"),
                                content: const Text("真的吗？"),
                                actions: [
                                  TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(true);
                                      },
                                      child: const Text("确定")),
                                  TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(false);
                                      },
                                      child: const Text("取消"))
                                ],
                              );
                            });
                      },
                      child: ListTile(
                        leading: Image.network(
                          "https://mazhangjing.com/static/favicon.ico",
                          width: 40,
                        ),
                        title: Text(e.websiteUrl),
                        subtitle: Text(e.from),
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class LearnLayout extends StatelessWidget {
  const LearnLayout({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          color: Colors.brown,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: <Widget>[
              FlutterLogo(
                size: 200,
              ),
              Text(
                "Text",
                style: TextStyle(fontSize: 40),
              ),
              Text(
                "0",
                style: TextStyle(fontSize: 80, fontWeight: FontWeight.w100),
              ),
              Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    height: 50,
                    width: 50,
                    color: Colors.red,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Colors.black26,
        titleTextStyle: const TextStyle(
            fontSize: 20, color: Colors.black54, fontWeight: FontWeight.bold),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text('你已经点击了 $_counter 次',
                  style: const TextStyle(fontSize: 20, color: Colors.black87)),
              Padding(
                padding: const EdgeInsets.only(top: 80),
                child: SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                      onPressed: _incrementCounter, child: const Text("递增")),
                ),
              )
            ],
          ),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
