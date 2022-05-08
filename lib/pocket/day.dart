import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '/pocket/config.dart';
import '/pocket/time.dart';
import '/pocket/models/day.dart';
import '/pocket/models/diary.dart' as d;
import 'package:provider/provider.dart';
import 'package:clipboard/clipboard.dart';
import 'package:url_launcher/url_launcher.dart';

class DayInfo {
  static String title = TimeUtil.todayShort();
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
          const Color.fromRGBO(250, 250, 250, 1),
          const Color.fromRGBO(250, 250, 250, 1).withOpacity(0.85),
          const Color.fromRGBO(250, 250, 250, 1).withOpacity(0.75),
          Colors.white.withOpacity(0.2),
          Colors.white.withOpacity(0)
        ],
            stops: const [
          0,
          0.1,
          0.2,
          0.3,
          1
        ]));
    final now = DateTime.now();
    if (now.hour <= 16 && now.hour >= 3) {
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
              const Color.fromRGBO(250, 250, 250, 1),
              const Color.fromRGBO(250, 250, 250, 1).withOpacity(0.95),
              const Color.fromRGBO(250, 250, 250, 1).withOpacity(0.85),
              const Color.fromRGBO(250, 250, 250, 1).withOpacity(0.73),
              Colors.white.withOpacity(0.2),
              Colors.white.withOpacity(0)
            ],
                stops: const [
              0,
              0.1,
              0.2,
              0.3,
              0.4,
              1
            ]))
      ];
    }
  }

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
                          padding: DayInfo.noticePadding,
                          decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(time, style: DayInfo.noticeStyle)))))
                  .toList()));
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
    return FutureBuilder(
      future: future,
      builder: (context, future) {
        print("state ${future.connectionState}");
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
                  Image.asset("images/empty.png", width: 200),
                  Text("发生了一些错误：${future.error}", textAlign: TextAlign.center)
                ]),
          );
        }
        return Container(
            alignment: Alignment.center,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  Padding(padding: EdgeInsets.all(20), child: Text("正在联系服务器"))
                ]));
      },
    );
  }

  Widget buildMainPage(Dashboard dashboard) {
    print("Ref");
    final bg = DayInfo.background();
    final allY = MediaQuery.of(context).size.height;
    return Stack(alignment: Alignment.topCenter, children: [
      Transform.translate(
        offset: const Offset(0, 30),
        child: Container(
          padding: EdgeInsets.only(top: allY - 400, left: 0, right: 0),
          child: Stack(
            children: [
              SizedBox(
                  width: double.infinity,
                  child: Image.asset(bg[0], fit: BoxFit.fitWidth)),
              Positioned.fill(child: Container(decoration: bg[1]))
            ],
          ),
        ),
      ),
      RefreshIndicator(
          onRefresh: () async {
            future = Dashboard.loadFromApi(config);
            await Future.delayed(
                const Duration(seconds: 1), () => setState(() {}));
          },
          child: MainPage(config: config, dashboard: dashboard))
    ]);
  }
}

/*GlobalKey background = GlobalKey();
  final bgPadding =
      ((background.currentContext?.findRenderObject()! as RenderBox?)
          ?.localToGlobal(Offset.zero).dy) ?? 0;*/

///一个始终显示在底部的背景图案（当 Viewpoint 高度不足则填充空白, 没有使用，
///其不能实现和 ScrollView 一致的动画，看起来比较突兀）
///另一种实现方案是将背景作为最后一个列表项放置，同时在其前面插入一个透明的 Box
///通过 GlobalKey 定位并且获取其 Offset 并且设置自己的 padding
class Background extends SingleChildRenderObjectWidget {
  @override
  RenderObject createRenderObject(BuildContext context) {
    return BackgroundBox(context);
  }

  const Background({required Widget child, Key? key})
      : super(child: child, key: key);
}

class BackgroundBox extends RenderBox with RenderObjectWithChildMixin {
  final BuildContext ctx;

  BackgroundBox(this.ctx);

  @override
  void performLayout() {
    child?.layout(constraints, parentUsesSize: true);
    size = (child as RenderBox).size;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var height = MediaQuery.of(ctx).size.height;
    var needTranslate = height - offset.dy - size.height - 100;
    if (needTranslate > 0) {
      //添加额外的空白，这里的 100 包含了 header 和 tabBar 的高度（估计）
      context.paintChild(child!, offset.translate(0, needTranslate));
    } else {
      //绘制在紧贴着上面的位置
      context.paintChild(child!, offset);
    }
  }
}

///所有卡片
class MainPage extends StatelessWidget {
  const MainPage({
    Key? key,
    required this.dashboard,
    required this.config,
  }) : super(key: key);

  final Config config;
  final Dashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        //待办卡片
        Card(child: Todo(config, dashboard), elevation: 0.2),
        //工作日卡片，包含是否打卡，是否下班，工作时长，打卡信息
        SizedBox(
            height: 130,
            child: LayoutBuilder(
                builder: (context, constraints) =>
                    Work(dashboard, constraints))),
        //习惯卡片
        SizedBox(
            height: 100,
            child: LayoutBuilder(
                builder: (context, constraints) =>
                    Habit(dashboard, constraints))),
        LayoutBuilder(
            builder: (context, constraints) => Diary(dashboard, constraints)),
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
                    DayInfo.noticeOf([dashboard.dayWorkString],
                        color: dashboard.alertMorningDayWork
                            ? Colors.red[400]!
                            : Colors.blue[400]!)
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
                  dashboard.work.OffWork
                      ? DayInfo.noticeOf(["无需打卡"], color: Colors.green)
                      : dashboard.work.NeedMorningCheck
                          ? DayInfo.noticeOf(["记得打卡"], color: Colors.orange)
                          : dashboard.alertNightDayWork
                              ? DayInfo.noticeOf(["记得打卡"], color: Colors.red)
                              : DayInfo.noticeOf(dashboard.work.signData())
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
              child: DayInfo.noticeOf(data.labels,
                  color: const Color.fromRGBO(196, 196, 196, 1.0),
                  align: MainAxisAlignment.start),
            )
          ]),
    ));
    return SizedBox(
      height: 110,
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
                      padding: const EdgeInsets.only(right: 15),
                      child: FadeInImage.assetNetwork(
                          placeholder: "images/dash/lol.png",
                          image: image,
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover)),
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
