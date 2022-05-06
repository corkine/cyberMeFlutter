import 'package:flutter/material.dart';
import '/pocket/config.dart';
import '/pocket/models/day.dart';
import 'package:provider/provider.dart';
import 'package:clipboard/clipboard.dart';

class DayInfo {
  static String title = Dashboard.todayShort();
  static const Widget titleWidget = Text("我的一天");

  static List<Widget> menuActions(BuildContext context, Config config) => [
        PopupMenuButton(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (e) {},
            itemBuilder: (c) {
              return [
                PopupMenuItem(
                    child: const Text("获取最后一条笔记"),
                    onTap: () async {
                      var message = await Dashboard.fetchLastNote(config);
                      if (message[1] != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("内容已拷贝到剪贴板，字数 ${message[0]?.length}"),
                        ));
                        FlutterClipboard.copy(message[1] ?? "未知数据");
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(message[0] ?? "未知错误"),
                        ));
                      }
                    }),
                PopupMenuItem(
                    child: const Text("从剪贴板上传笔记"),
                    onTap: () async {
                      var content = await FlutterClipboard.paste();
                      if (context.toString().isEmpty) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text("剪贴板没有数据！"),
                        ));
                      }
                      var message =
                          await Dashboard.uploadOneNote(config, content);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(message),
                      ));
                    })
              ];
            })
      ];
  static Widget mainWidget = const DayHome();
  static const TextStyle normal = TextStyle(fontSize: 14);
  static const TextStyle noticeStyle =
      TextStyle(color: Colors.white, fontSize: 12);
  static const EdgeInsets noticePadding = EdgeInsets.fromLTRB(10, 3, 10, 3);

  static List background() {
    final normal = BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
          Colors.white.withOpacity(1),
          Colors.white.withOpacity(0.85),
          Colors.white.withOpacity(0.2),
          Colors.white.withOpacity(0)
        ],
            stops: const [
          0,
          0.2,
          0.3,
          1
        ]));
    final now = DateTime.now();
    if (now.hour <= 16 && now.hour >= 5) {
      return ["images/dash/spring.png", normal];
    } else if (now.hour < 20) {
      return ["images/dash/fall.png", normal];
    } else {
      return [
        "images/dash/night.png",
        BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
              Colors.white.withOpacity(1),
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.3),
              Colors.white.withOpacity(0)
            ],
                stops: const [
              0,
              0.3,
              0.6,
              1
            ]))
      ];
    }
  }
}

class DayHome extends StatefulWidget {
  const DayHome({Key? key}) : super(key: key);

  @override
  State<DayHome> createState() => _DayHomeState();
}

class _DayHomeState extends State<DayHome> {
  late Config config;
  late Future<Dashboard?> future;

  @override
  void didChangeDependencies() {
    config = Provider.of<Config>(context, listen: true);
    if (config.user.isEmpty) {
      future = Future.value(null);
    } else {
      future = Dashboard.loadFromApi(config);
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        future = Dashboard.loadFromApi(config);
        await Future.delayed(const Duration(seconds: 1), () => setState(() {}));
      },
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: FutureBuilder(
          future: future,
          builder: (context, future) {
            if (future.hasData && future.data != null) {
              return buildMainPage(future.data as Dashboard);
            }
            if (future.hasError) {
              return SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.height - 100,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset("images/empty.jpg", width: 200),
                      Text("发生了一些错误：${future.error}",
                          textAlign: TextAlign.center)
                    ]),
              );
            }
            return Container(
                alignment: Alignment.center,
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height / 3),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(),
                      Padding(
                          padding: EdgeInsets.all(8.0), child: Text("正在联系服务器"))
                    ]));
          },
        ),
      ),
    );
  }

  Widget buildMainPage(Dashboard dashboard) {
    final bg = DayInfo.background();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      //待办卡片
      Card(child: Todo(config, dashboard), elevation: 0.2),
      //工作日卡片，包含是否打卡，是否下班，工作时长，打卡信息
      SizedBox(
          height: 130,
          child: LayoutBuilder(
              builder: (context, constraints) => Work(dashboard, constraints))),
      //习惯卡片
      SizedBox(
          height: 100,
          child: LayoutBuilder(
              builder: (context, constraints) =>
                  Habit(dashboard, constraints))),
      //日记卡片
      Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Stack(
          children: [
            Image.asset(
              bg[0],
              width: double.infinity,
            ),
            Positioned.fill(child: Container(decoration: bg[1]))
          ],
        ),
      )
    ]);
  }
}

///待办卡片
class Todo extends StatelessWidget {
  final Dashboard dashboard;
  final Config config;

  const Todo(
    this.config,
    this.dashboard, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(13, 10, 13, 15),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Tooltip(
                      message: "双击同步 Graph API",
                      child: GestureDetector(
                        onDoubleTap: () => Dashboard.focusSyncTodo(config).then(
                            (message) => ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(message),
                                ))),
                        child: const Text("我的待办",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    Container(
                        padding: DayInfo.noticePadding,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: dashboard.alertDayWork
                                ? Colors.red[300]
                                : Colors.blue[300]),
                        child: Text(
                          dashboard.dayWorkString,
                          style: DayInfo.noticeStyle,
                        ))
                  ])),
          ...(dashboard.todayTodo
              .map((todo) => ListTile(
                  trailing: todo.isImportant
                      ? const Icon(Icons.star)
                      : const Icon(Icons.star_border),
                  title: Text(todo.title,
                      style: todo.isFinish
                          ? const TextStyle(
                                  decoration: TextDecoration.lineThrough)
                              .merge(DayInfo.normal)
                          : DayInfo.normal),
                  dense: true,
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(todo.list, style: DayInfo.normal),
                  )))
              .toList()),
        ],
      ),
    );
  }
}

///工作卡片
class Work extends StatelessWidget {
  final Dashboard dashboard;
  final BoxConstraints constraints;

  const Work(
    this.dashboard,
    this.constraints, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var config = Provider.of<Config>(context, listen: false);
    return Card(
      child: Stack(children: [
        Positioned(
            left: -10,
            bottom: -10,
            child: dashboard.work.NeedWork
                ? dashboard.work.OffWork
                    ? Image.asset("images/dash/offwork.png",
                        height: constraints.maxHeight)
                    : Image.asset("images/dash/work.png",
                        height: constraints.maxHeight)
                : Image.asset("images/dash/offwork.png",
                    height: constraints.maxHeight)),
        Container(
            color: Colors.transparent,
            width: double.infinity,
            padding: const EdgeInsets.only(right: 20, top: 20),
            child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Tooltip(
                    message: "双击同步 HCM",
                    child: GestureDetector(
                      onDoubleTap: () => Dashboard.checkHCMCard(config).then(
                          (message) => ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(message),
                              ))),
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                          child: Text.rich(TextSpan(children: [
                            const TextSpan(text: "已工作 "),
                            TextSpan(
                                text: "${dashboard.work.WorkHour}",
                                style: const TextStyle(
                                    fontFamily: "consolas", fontSize: 20)),
                            const TextSpan(text: " h")
                          ]))),
                    ),
                  ),
                  dashboard.work.NeedMorningCheck
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                          child: Container(
                              padding: DayInfo.noticePadding,
                              decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Text("记得打卡",
                                  style: DayInfo.noticeStyle)))
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                          child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: (dashboard.work.signData().map((time) =>
                                  Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: Container(
                                          padding: DayInfo.noticePadding,
                                          decoration: BoxDecoration(
                                              color: const Color.fromRGBO(
                                                  47, 46, 65, 1.0),
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          child: Text(time,
                                              style: DayInfo
                                                  .noticeStyle))))).toList()))
                ]))
      ]),
      elevation: 0.2,
    );
  }
}

///习惯卡片
class Habit extends StatelessWidget {
  final Dashboard dashboard;
  final BoxConstraints constraints;

  const Habit(
    this.dashboard,
    this.constraints, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var config = Provider.of<Config>(context);
    return Card(
      child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 20),
          child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Tooltip(
                          message: "双击添加今日记录",
                          child: GestureDetector(
                              onDoubleTap: () => Dashboard.setClean(config)
                                  .then((message) =>
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(message),
                                      ))),
                              child: Row(children: [
                                buildProgressIcon(
                                    dashboard.cleanPercentInRange, "comb"),
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text.rich(TextSpan(children: [
                                        const TextSpan(text: " 已坚持 "),
                                        TextSpan(
                                            text: " ${dashboard.cleanCount} ",
                                            style: const TextStyle(
                                                fontFamily: "consolas",
                                                fontSize: 20)),
                                        const TextSpan(text: "天")
                                      ])),
                                      Text(
                                        " Max ${dashboard.cleanMarvelCount} 天",
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 13),
                                      )
                                    ])
                              ]))),
                      Tooltip(
                          message: "双击记录 Blue 信息",
                          child: GestureDetector(
                              onDoubleTap: () {
                                showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime.now()
                                            .subtract(const Duration(days: 5)),
                                        lastDate: DateTime.now())
                                    .then((date) {
                                  if (date == null) return;
                                  var dateStr = date.toString().split(" ")[0];
                                  Dashboard.setBlue(config, dateStr).then(
                                      (message) => ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            content: Text(message),
                                          )));
                                });
                              },
                              child: Row(children: [
                                buildProgressIcon(
                                    dashboard.noBluePercentInRange, "summer"),
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text.rich(TextSpan(children: [
                                        const TextSpan(text: " 已坚持 "),
                                        TextSpan(
                                            text: " ${dashboard.noBlueCount} ",
                                            style: const TextStyle(
                                                fontFamily: "consolas",
                                                fontSize: 20)),
                                        const TextSpan(text: "天")
                                      ])),
                                      Text(
                                          " Max ${dashboard.noBlueMarvelCount} 天",
                                          style: const TextStyle(
                                              color: Colors.grey, fontSize: 13))
                                    ])
                              ])))
                    ])
              ])),
      elevation: 0.2,
    );
  }

  Widget buildProgressIcon(double progress, String png) {
    return Padding(
        padding: const EdgeInsets.only(right: 2),
        child: progress > 0.3
            ? AnimatedOpacity(
                opacity: progress,
                duration: const Duration(seconds: 1),
                child: Image.asset("images/dash/$png.png", width: 50))
            : ColorFiltered(
                colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.45 - progress),
                    BlendMode.srcATop),
                child: Image.asset("images/dash/$png.png", width: 50)));
  }
}
