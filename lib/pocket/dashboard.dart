import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';
import '/pocket/config.dart';
import '/pocket/time.dart';
import '/pocket/util.dart' as util;
import '/pocket/models/day.dart';
import '/pocket/models/diary.dart' as d;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

int dashFetchSeconds = 120;

class DashInfo {
  static TextStyle normal =
      TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9));
  static const TextStyle noticeStyle =
      TextStyle(color: Colors.white, fontSize: 12);
  static const EdgeInsets noticePadding = EdgeInsets.fromLTRB(10, 3, 10, 3);

  static Padding noticeOf(List<String> text,
          {Color color = const Color.fromRGBO(47, 46, 65, 1.0),
          MainAxisAlignment align = MainAxisAlignment.end}) =>
      Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: align,
              children: (text.map((time) => Padding(
                      padding: const EdgeInsets.only(left: 3),
                      child: Container(
                          padding: DashInfo.noticePadding,
                          decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(time, style: DashInfo.noticeStyle)))))
                  .toList()));

  static callAndShow(
          Future Function(Config) f, BuildContext context, Config config) =>
      f(config)
          .then((message) => ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message))))
          .then((value) => config.needRefreshDashboardPage = true);
}

class DashHome extends StatefulWidget {
  const DashHome({Key? key}) : super(key: key);

  @override
  State<DashHome> createState() => _DashHomeState();
}

class _DashHomeState extends State<DashHome> {
  late Config config;
  Future<Dashboard?>? future;
  String time = "00:00";
  StreamController controller = StreamController();
  late StreamSubscription subscription;

  @override
  void initState() {
    controller.sink
        .addStream(Stream.periodic(const Duration(seconds: 5), (index) {
      return index;
    }));
    subscription = controller.stream.listen((event) {
      if (event % (dashFetchSeconds / 5) == 0) {
        if (kDebugMode) print("Call API Now at ${TimeUtil.nowLog}");
        future = Dashboard.loadFromApi(config);
      }
      setState(() {
        //print("Setting state at ${TimeUtil.nowLog}");
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    subscription.cancel();
    controller.close();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    //print("Rebuild at ${TimeUtil.nowLog}");
    config = Provider.of<Config>(context, listen: true);
    if (config.isLoadedFromLocal) {
      if (config.needRefreshDashboardPage) {
        future = Dashboard.loadFromApi(config);
        config.needRefreshDashboardPage = false;
      } else {
        future ??= Dashboard.loadFromApi(config);
      }
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: util.commonFutureBuilder<Dashboard>(buildMainPage),
    );
  }

  Widget buildMainPage(Dashboard dashboard) {
    return RefreshIndicator(
        onRefresh: () async {
          future = Dashboard.loadFromApi(config);
          await Future.delayed(
              const Duration(seconds: 1), () => setState(() {}));
        },
        child: MainPage(config: config, dashboard: dashboard, state: this));
  }
}

///所有卡片
class MainPage extends StatelessWidget {
  const MainPage({
    Key? key,
    required this.dashboard,
    required this.config,
    required this.state,
  }) : super(key: key);

  final Config config;
  final Dashboard dashboard;
  final _DashHomeState state;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    var time = sprintf("%02d:%02d", [now.hour, now.minute]);
    return SingleChildScrollView(
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        //待办卡片
        Card(
            child: Todo(config, dashboard),
            elevation: 0.2,
            color: Colors.transparent),
        //工作日卡片，包含是否打卡，是否下班，工作时长，打卡信息
        SizedBox(
            height: 70,
            child: LayoutBuilder(
                builder: (context, constraints) =>
                    Work(dashboard, constraints))),
        /*//习惯卡片
        SizedBox(
            height: 100,
            child: LayoutBuilder(
                builder: (context, constraints) =>
                    Habit(dashboard, constraints))),*/
        Card(
          child: Padding(
            padding: const EdgeInsets.only(left: 25, top: 20),
            child: Text(
              time,
              style: const TextStyle(fontSize: 30, color: Colors.white),
            ),
          ),
          color: Colors.transparent,
        ),
        //空卡片，防止下拉刷新时 ScrollView 卡在背景中
        const SizedBox(height: 200)
      ]),
    );
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
                    Row(mainAxisAlignment: MainAxisAlignment.start, 
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Tooltip(
                        message: "双击同步 Graph API",
                        child: GestureDetector(
                          onDoubleTap: () => Dashboard.focusSyncTodo(config)
                              .then((message) => ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                      SnackBar(content: Text(message)))),
                          child: const Text("我的待办",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white)),
                        ),
                      ),
                      Text(" " + dashboard.plantInfo.weekWaterStr.join(""),
                          style: const TextStyle(color: Colors.white)),
                    ]),
                    DashInfo.noticeOf([dashboard.dayWorkString],
                        color: dashboard.alertMorningDayWork
                            ? Colors.red[400]!
                            : Colors.green)
                  ])),
          ...(dashboard.todayTodo
              .map((todo) => ListTile(
                  trailing: todo.isImportant
                      ? const Icon(Icons.star, color: Colors.grey)
                      : const Icon(Icons.star_border, color: Colors.grey),
                  title: Text(todo.title,
                      style: todo.isFinish
                          ? const TextStyle(
                                  decoration: TextDecoration.lineThrough)
                              .merge(DashInfo.normal)
                          : DashInfo.normal),
                  dense: true,
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(todo.list, style: DashInfo.normal),
                  )))
              .toList()),
        ],
      ),
    );
  }
}

///工作卡片
class Work extends StatefulWidget {
  final Dashboard dashboard;
  final BoxConstraints constraints;

  const Work(
    this.dashboard,
    this.constraints, {
    Key? key,
  }) : super(key: key);

  @override
  State<Work> createState() => _WorkState();
}

class _WorkState extends State<Work> {
  double left = -10;

  @override
  void didChangeDependencies() {
    Future.delayed(
        const Duration(milliseconds: 100), () => setState(() => {left = 0}));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    var config = Provider.of<Config>(context, listen: false);
    return Card(
      color: Colors.transparent,
      child: Stack(children: [
        Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 15, top: 20, right: 20),
            child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Tooltip(
                    message: "双击同步 HCM",
                    child: GestureDetector(
                      onDoubleTap: () => DashInfo.callAndShow(
                          Dashboard.checkHCMCard, context, config),
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                          child: Text.rich(TextSpan(children: [
                            const TextSpan(
                                text: "已工作 ",
                                style: TextStyle(color: Colors.white)),
                            TextSpan(
                                text: "${widget.dashboard.work.WorkHour}",
                                style: const TextStyle(
                                    fontFamily: "consolas",
                                    fontSize: 20,
                                    color: Colors.white)),
                            const TextSpan(
                                text: " h",
                                style: TextStyle(color: Colors.white))
                          ]))),
                    ),
                  ),
                  widget.dashboard.work.OffWork
                      ? DashInfo.noticeOf(["无需打卡"], color: Colors.green)
                      : widget.dashboard.work.NeedMorningCheck
                          ? DashInfo.noticeOf(["记得打卡"], color: Colors.orange)
                          : widget.dashboard.alertNightDayWork
                              ? DashInfo.noticeOf(["记得打卡"], color: Colors.red)
                              : DashInfo.noticeOf(
                                  widget.dashboard.work.signData())
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
                              onDoubleTap: () => DashInfo.callAndShow(
                                  Dashboard.setClean, context, config),
                              child: Row(children: [
                                buildProgressIcon(
                                    dashboard.cleanPercentInRange, "comb"),
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text.rich(TextSpan(children: [
                                        const TextSpan(text: " 已坚持"),
                                        TextSpan(
                                            text:
                                                " ${dashboard.clean.HabitHint} ",
                                            style: const TextStyle(
                                                fontFamily: "consolas",
                                                fontSize: 20)),
                                        const TextSpan(text: "天")
                                      ])),
                                      Text(
                                        " 最长 ${dashboard.cleanMarvelCount} 天",
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
                                  DashInfo.callAndShow(
                                      (c) => Dashboard.setBlue(c, dateStr),
                                      context,
                                      config);
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
                                        const TextSpan(text: " 已坚持"),
                                        TextSpan(
                                            text: " ${dashboard.noBlueCount} ",
                                            style: const TextStyle(
                                                fontFamily: "consolas",
                                                fontSize: 20)),
                                        const TextSpan(text: "天")
                                      ])),
                                      Text(
                                          " 最长 ${dashboard.noBlueMarvelCount} 天",
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
            : /*ColorFiltered(
                colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.45 - progress),
                    BlendMode.srcATop),
                child: Image.asset("images/dash/$png.png", width: 50)))*/
            ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaY: 5, sigmaX: 5),
                child: Image.asset("images/dash/$png.png", width: 50)));
  }
}

///日记卡片
class Diary extends StatefulWidget {
  final Dashboard dashboard;
  final BoxConstraints constraints;

  const Diary(
    this.dashboard,
    this.constraints, {
    Key? key,
  }) : super(key: key);

  @override
  State<Diary> createState() => _DiaryState();
}

class _DiaryState extends State<Diary> {
  late double scale = 0.6;
  late d.Diary? diary;

  @override
  void didChangeDependencies() {
    Future.delayed(
        const Duration(milliseconds: 500), () => setState(() => {scale = 0.8}));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    diary = d.DiaryManager.today(widget.dashboard.diaries);
    return Card(
        color: Colors.white.withOpacity(1),
        child: Container(
            padding:
                const EdgeInsets.only(left: 10, right: 20, top: 20, bottom: 20),
            child: diary == null ? buildWhenNoDiary() : buildTodayDiary()),
        elevation: 0.2);
  }

  Widget buildTodayDiary() {
    var data = diary!;
    var image = data.previewPicture;
    var content = Expanded(
        child: GestureDetector(
      onTap: () {
        launchUrl(Uri.parse(data.url));
      },
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(data.title, style: const TextStyle(fontSize: 18)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 5),
                child: Text(data.preview,
                    style: const TextStyle(
                        overflow: TextOverflow.fade, color: Colors.black54),
                    softWrap: true),
              ),
            ),
            Transform.translate(
              offset: const Offset(-10, 3),
              child: DashInfo.noticeOf(data.labels,
                  color: const Color.fromRGBO(196, 196, 196, 1.0),
                  align: MainAxisAlignment.start),
            )
          ]),
    ));
    return SizedBox(
      height: 100,
      child: Row(
          mainAxisSize: MainAxisSize.min,
          children: image == null
              ? [
                  Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Image.asset("images/empty.png",
                          width: 110, height: 110, fit: BoxFit.contain)),
                  content
                ]
              : [
                  Padding(
                      padding: const EdgeInsets.only(right: 15, left: 2),
                      child: ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(5)),
                        child: FadeInImage.assetNetwork(
                            placeholder: "images/dash/lol.png",
                            image: image,
                            width: 95,
                            height: 95,
                            fit: BoxFit.cover),
                      )),
                  content
                ]),
    );
  }

  Widget buildWhenNoDiary() => Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                            AnimatedScale(
                              duration: const Duration(seconds: 1),
                              curve: Curves.bounceOut,
                              scale: scale,
                              child: Image.asset("images/empty.png", width: 60),
                            ),
                            Flexible(
                              child: Container(
                                  padding: const EdgeInsets.only(
                                      left: 10, right: 20),
                                  child: const Text("我家楼下有两棵树，一棵是枣树，另一棵也是枣树。",
                                      softWrap: true,
                                      style: TextStyle(fontSize: 15))),
                            )
                          ])),
                      ElevatedButton(
                          style: ButtonStyle(
                              elevation: MaterialStateProperty.all(0.1)),
                          onPressed: () {
                            launchUrl(Uri.parse(d.DiaryManager.newDiaryUrl));
                          },
                          child: const Text("写篇日记"))
                    ]))
          ]);
}
