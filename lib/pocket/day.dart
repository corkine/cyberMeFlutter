import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '/pocket/config.dart';
import '/pocket/models/day.dart';
import 'package:provider/provider.dart';

class DayInfo {
  static String title = Dashboard.todayShort();
  static const Widget titleWidget = Text("我的一天");
  static List<Widget> menuActions = [
    PopupMenuButton(
        icon: const Icon(Icons.more_vert_rounded),
        onSelected: (e) {},
        itemBuilder: (c) {
          return [const PopupMenuItem(child: Text("Example"))];
        })
  ];
  static Widget mainWidget = const DayHome();
  static const TextStyle normal = TextStyle(fontSize: 14);
  static const TextStyle noticeStyle =
      TextStyle(color: Colors.white, fontSize: 12);
  static const EdgeInsets noticePadding = EdgeInsets.fromLTRB(10, 3, 10, 3);
}

class DayHome extends StatefulWidget {
  const DayHome({Key? key}) : super(key: key);

  @override
  State<DayHome> createState() => _DayHomeState();
}

class _DayHomeState extends State<DayHome> {
  @override
  Widget build(BuildContext context) {
    return Consumer<Config>(
      builder: (context, config, _) => SingleChildScrollView(
        child: FutureBuilder(
          future: Dashboard.loadFromApi(config),
          builder: (context, future) {
            if (future.hasData) return buildMainPage(future.data as Dashboard);
            if (future.hasError) {
              return Container(
                  padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height / 3),
                  alignment: Alignment.center,
                  child: Text("发生了一些错误：${future.error}"));
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
                        padding: EdgeInsets.all(8.0),
                        child: Text("正在联系服务器"),
                      )
                    ]));
          },
        ),
      ),
    );
  }

  Widget buildMainPage(Dashboard dashboard) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding:
                const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(13, 10, 13, 15),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text("我的待办",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
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
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(todo.list, style: DayInfo.normal),
                        )))
                    .toList()),
              ],
            ),
          ),
          elevation: 0.2,
        ),
        //工作日卡片，包含是否打卡，是否下班，工作时长，打卡信息
        SizedBox(
          height: 150,
          child: LayoutBuilder(
              builder: (context, constraints) => Card(
                    child: Stack(children: [
                      Positioned(
                          left: -20,
                          bottom: -16,
                          child: dashboard.work.NeedWork
                              ? dashboard.work.OffWork
                                  ? Image.asset("images/offwork.png",
                                      height: constraints.maxHeight)
                                  : Image.asset("images/work.png",
                                      height: constraints.maxHeight)
                              : Image.asset("images/offwork.png",
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
                                Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(8, 4, 8, 4),
                                    child: Text.rich(TextSpan(children: [
                                      const TextSpan(text: "已工作 "),
                                      TextSpan(
                                          text: "${dashboard.work.WorkHour}",
                                          style: const TextStyle(
                                              fontFamily: "consolas",
                                              fontSize: 20)),
                                      const TextSpan(text: " h")
                                    ]))),
                                dashboard.work.NeedMorningCheck
                                    ? Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8, 4, 8, 4),
                                        child: Container(
                                            padding: DayInfo.noticePadding,
                                            decoration: BoxDecoration(
                                                color: Colors.green,
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            child: const Text("记得打卡",
                                                style: DayInfo.noticeStyle)))
                                    : Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8, 4, 8, 4),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: (dashboard.work
                                              .signData()
                                              .map((time) => Padding(
                                                  padding: const EdgeInsets.only(
                                                      left: 10),
                                                  child: Container(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 7,
                                                              right: 7,
                                                              top: 1,
                                                              bottom: 1),
                                                      decoration: BoxDecoration(
                                                          color: const Color.fromRGBO(
                                                              47, 46, 65, 1.0),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  10)),
                                                      child: Text(time,
                                                          style: const TextStyle(color: Colors.white)))))).toList(),
                                        ))
                              ]))
                    ]),
                    elevation: 0.2,
                  )),
        ),
        Card(
          child: Column(
            children: [
              Image.asset(
                "images/diary.png",
                height: 180,
                width: double.infinity,
              ),
              const Padding(
                  padding: EdgeInsets.only(bottom: 20, right: 10),
                  child: Text("没有日记"))
            ],
          ),
          elevation: 0.2,
        )
      ],
    );
  }
}
