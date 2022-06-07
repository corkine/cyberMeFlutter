import 'dart:math';
import 'dart:ui';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/diary.dart';
import 'util.dart' as util;
import 'package:provider/provider.dart';
import 'package:swipable_stack/swipable_stack.dart';

import 'config.dart';

String buttonTitle = "日记";

Widget title = const Text("日日新");

Widget mainButton = const Icon(Icons.add_a_photo);

Widget mainWidget = const DiaryStage();

List<Widget> menuActions(BuildContext context, Config config) {
  return [
    PopupMenuButton(
        icon: const Icon(Icons.more_vert_rounded),
        onSelected: (e) {},
        itemBuilder: (c) {
          return [PopupMenuItem(child: const Text("还没有施工"), onTap: () {})];
        })
  ];
}

void mainAction(BuildContext context, Config config) async {
  /*launch(DiaryManager.newDiaryUrl).then((value) {
    //on desktop, this will call immediately, not like mobile
    if (kDebugMode) print("back to app!");
  });*/
  String? url;
  var image = await util.pickImage(context);
  if (image != null) {
    if (kDebugMode) print("uploading image $image");
    var uploadRes = await util.uploadImage(image, config);
    if (uploadRes[0] == null) {
      if (kDebugMode) print("upload failed! ${uploadRes[1]}");
    } else {
      url = uploadRes[0];
      await FlutterClipboard.copy("![]($url)");
    }
  }
  if (kDebugMode) print(url);
  Future.delayed(const Duration(milliseconds: 500), () => launch(DiaryManager.newDiaryUrl));
}

class DiaryStage extends StatefulWidget {
  const DiaryStage({Key? key}) : super(key: key);

  @override
  State<DiaryStage> createState() => _DiaryStageState();
}

class _DiaryStageState extends State<DiaryStage> {
  Future<List<Diary>>? future;
  late Config config;

  @override
  void didChangeDependencies() {
    config = Provider.of<Config>(context, listen: true);
    if (config.isLoadedFromLocal) {
      future ??= DiaryManager.loadFromApi(config);
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) print("Building DiaryStage");
    return FutureBuilder(
        future: future,
        builder: util.commonFutureBuilder<List<Diary>>((diaries) => DiaryCards(
            diaries: diaries.sublist(
                0, diaries.length > 10 ? 10 : diaries.length))));
  }
}

class DiaryCards extends StatefulWidget {
  const DiaryCards({Key? key, required this.diaries}) : super(key: key);

  final List<Diary> diaries;

  @override
  State<DiaryCards> createState() => _DiaryCardsState();
}

class _DiaryCardsState extends State<DiaryCards> {
  late SwipableStackController _controller;
  late List<String?> urls;

  @override
  void initState() {
    super.initState();
    urls = widget.diaries.map((e) => e.previewPicture).toList();
    _controller = SwipableStackController();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.center,
        child: SwipableStack(
          swipeAnchor: SwipeAnchor.top,
          detectableSwipeDirections: const {
            //SwipeDirection.right,
            SwipeDirection.left,
          },
          //horizontalSwipeThreshold: 0.8,
          //verticalSwipeThreshold: 0.8,
          controller: _controller,
          stackClipBehaviour: Clip.none,
          allowVerticalSwipe: true,
          builder: (context, properties) {
            //if (kDebugMode) print("prop: ${properties.index}");
            var index = properties.index;
            var target = index % urls.length;
            String? url = urls[target];
            Diary d = widget.diaries[target];
            return ClipRRect(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0)),
              child: Container(
                  color: Colors.white,
                  height: MediaQuery.of(context).size.height,
                  width: double.infinity,
                  child: Stack(alignment: Alignment.center, children: [
                    Positioned.fill(
                        child: url == null
                            ? Container(
                                padding: const EdgeInsets.only(
                                    left: 30, right: 50, bottom: 60),
                                child: Image.asset("images/dash/lol.png"))
                            : Image.network(url, fit: BoxFit.cover)),
                    Positioned(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                              bottomLeft: Radius.circular(0),
                              bottomRight: Radius.circular(0)),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: GestureDetector(
                              onTapDown: (de) {
                                var width = MediaQuery.of(context).size.width;
                                var localX = de.localPosition.dx;
                                var thirdPart = width * 1.0 / 3;
                                if (localX < thirdPart) {
                                  _controller.rewind(); //只能回退一次
                                } else if (localX > thirdPart + thirdPart) {
                                  _controller.next(
                                      swipeDirection: SwipeDirection.left);
                                } else {
                                  launch(d.url);
                                }
                              },
                              child: Container(
                                color: CupertinoDynamicColor.resolve(
                                    Colors.white60, context),
                                padding: const EdgeInsets.only(
                                    top: 15, left: 15, right: 15, bottom: 20),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("${d.day}: ${d.title}",
                                          style: Theme.of(context)
                                              .primaryTextTheme
                                              .headline2!
                                              .copyWith(
                                                  color: Colors.black,
                                                  fontSize: 19)),
                                      const SizedBox(height: 10),
                                      Text(d.preview,
                                          style: Theme.of(context)
                                              .primaryTextTheme
                                              .bodyText1!
                                              .copyWith(color: Colors.black54))
                                    ]),
                              ),
                            ),
                          ),
                        ),
                        bottom: 0,
                        left: 0,
                        right: 0)
                  ])),
            );
          },
          /*overlayBuilder: (context, properties) {
          final opacity = min(properties.swipeProgress, 1.0);
          final isRight = properties.direction == SwipeDirection.right;
          return Opacity(
            opacity: isRight ? opacity : 0,
            child: const Text("Hello"),
          );
        },*/
          swipeAssistDuration: const Duration(milliseconds: 100),
        ));
  }
}
