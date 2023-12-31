import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clipboard/clipboard.dart';
import 'package:cyberme_flutter/api/movie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../api/tv.dart';
import '../../main.dart';
import '../config.dart';
import '../models/movie.dart';

class MovieView extends ConsumerStatefulWidget {
  const MovieView({super.key});

  @override
  ConsumerState<MovieView> createState() => _MovieViewState();
}

class _MovieViewState extends ConsumerState<MovieView> {
  @override
  void deactivate() {
    ref
        .read(movieSettingsProvider.notifier)
        .syncUpload(filter: ref.read(movieFiltersProvider));
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final setting = ref.watch(movieSettingsProvider).value;
    final movies = ref.watch(movieFilteredProvider);
    final tracking =
        ref.watch(seriesDBProvider).value?.map((e) => e.url).toSet() ?? {};
    final filter = ref.watch(movieFiltersProvider);
    final showHot = setting?.showHot ?? true;
    final showTv = setting?.showTv ?? true;
    final loading = movies.isEmpty;
    var title = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("${showHot ? "HOT" : "NEW"} ${showTv ? "Series" : "Movie"}",
          style: const TextStyle(fontSize: 19)),
      const SizedBox(height: 2),
      loading
          ? const Text("Loading...", style: TextStyle(fontSize: 10))
          : Text("共 ${movies.length} 条结果", style: const TextStyle(fontSize: 10))
    ]);
    var appBar = AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black26,
        title: title,
        centerTitle: false,
        actions: [
          IconButton(
              onPressed: () => showModalBottomSheet(
                  context: context,
                  builder: (context) => const SeriesSubscribeView()),
              icon: const Icon(Icons.track_changes_outlined)),
          IconButton(
              onPressed: ref.read(movieSettingsProvider.notifier).toggleShowTv,
              icon: Icon(showTv ? Icons.tv : Icons.movie)),
          IconButton(
              onPressed: ref.read(movieSettingsProvider.notifier).toggleShowHot,
              icon: Icon(showHot
                  ? Icons.local_fire_department_outlined
                  : Icons.new_releases))
        ]);
    var searchBar = Container(
        margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        decoration: BoxDecoration(
            color: Colors.black54, borderRadius: BorderRadius.circular(10)),
        alignment: Alignment.center,
        child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (c) {
                  return BottomSheet(
                      backgroundColor: Colors.transparent,
                      onClosing: () {},
                      enableDrag: false,
                      builder: (c) => const MovieFilterView());
                }),
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(toDesc(filter, setting),
                          style: const TextStyle(color: Colors.white))
                    ]))));
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: appBar,
        body: Stack(children: [
          RefreshIndicator(
              onRefresh: () async => await ref.refresh(getMoviesProvider),
              child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 150, childAspectRatio: 0.7),
                  itemCount: movies.length,
                  itemBuilder: (c, i) {
                    final e = movies[i];
                    final isWatched = showTv
                        ? setting?.watchedTv.contains(e.url) ?? false
                        : setting?.watchedMovie.contains(e.url) ?? false;
                    final isTracking = tracking.contains(e.url);
                    final isIgnored =
                        setting?.ignoreItems.contains(e.url) ?? false;
                    final want = setting?.wantItems.contains(e.url) ?? false;
                    return InkWell(
                        onTap: () {
                          Navigator.of(context).push(PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) {
                                return MovieDetailView(e);
                              },
                              transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) =>
                                  FadeTransition(
                                      opacity: animation, child: child),
                              reverseTransitionDuration:
                                  const Duration(milliseconds: 200),
                              transitionDuration:
                                  const Duration(milliseconds: 200)));
                        },
                        onLongPress: () => showItemMenu(
                            e, showTv, isWatched, isIgnored, isTracking),
                        child: MovieCard(
                            e: e,
                            key: ObjectKey(e),
                            watched: isWatched,
                            isTracking: isTracking,
                            ignored: isIgnored,
                            want: want));
                  })),
          Positioned(
              child: SafeArea(child: searchBar), left: 0, right: 0, bottom: 0)
        ]));
  }

  String toDesc(MovieFilter filter, MovieSetting? setting) {
    final selectStar = filter.selectStar;
    final selectTags = filter.selectTags;
    final showWatched = filter.showWatched;
    final showTracked = filter.showTracked;
    final showWant = !filter.hideWant;
    final enableFilter = !showWatched || !showTracked || !showWant;
    final useSort = filter.useSort;
    String more = "";
    if (enableFilter && useSort) {
      more = ", 开启筛选和排序";
    } else if (enableFilter) {
      more = ", 开启筛选";
    } else if (useSort) {
      more = ", 开启排序";
    }
    if (selectStar == 0 && selectTags.isEmpty) {
      return "过滤器关$more";
    } else if (selectStar != 0 && selectTags.isNotEmpty) {
      return "大于 ${selectStar.toInt()} 星, 选中类别 ${selectTags.length} 个$more";
    } else if (selectStar != 0) {
      return "大于 ${selectStar.toInt()} 星$more";
    } else {
      return "选中类别 ${selectTags.length} 个$more";
    }
  }

  void showItemMenu(
      Movie e, bool isTv, bool isWatched, bool isIgnored, bool isTracking) {
    List<Widget> opts;
    if (isTv) {
      opts = [
        SimpleDialogOption(
            onPressed: isTv
                ? () {
                    Navigator.of(context).pop();
                    showModalBottomSheet(
                        context: context,
                        builder: (context) => isTracking
                            ? SeriesSubscribeView(delMovie: e)
                            : SeriesSubscribeView(addMovie: e));
                  }
                : null,
            child: Text(isTracking ? "删除追踪" : "添加追踪")),
        ...!isTracking
            ? [
                SimpleDialogOption(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ref
                          .read(movieSettingsProvider.notifier)
                          .makeWatched(isTv, e.url!, reverse: isWatched);
                    },
                    child: Text(isWatched ? "标记为未观看" : "标记为已观看"))
              ]
            : []
      ];
    } else {
      opts = [
        SimpleDialogOption(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(movieSettingsProvider.notifier)
                  .makeWatched(isTv, e.url!, reverse: isWatched);
            },
            child: Text(isWatched ? "标记为未观看" : "标记为已观看"))
      ];
    }
    showDialog(
        context: context,
        builder: (context) => Theme(
            data: appThemeData,
            child: SimpleDialog(title: Text(e.title!), children: [
              SimpleDialogOption(
                  onPressed: () => launchUrlString(e.url!),
                  child: const Text("在站点查看详情...")),
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.of(context).pop();
                    handleAddShortLink(e.url!);
                  },
                  child: const Text("生成短链接...")),
              ...opts,
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref
                        .read(movieSettingsProvider.notifier)
                        .makeIgnored(e.url!, reverse: isIgnored);
                  },
                  child: Text(
                      "${isIgnored ? "不忽略" : "忽略"}此${isTv ? "电视剧" : "电影"}",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)))
            ])));
  }

  Future handleAddShortLink(String url) async {
    final keyword = "mo" + (Random().nextInt(90000) + 10000).toString();
    final r = await get(Config.goUrl(keyword, url),
        headers: config.cyberBase64Header);
    final d = jsonDecode(r.body);
    final m = d["message"] ?? "没有消息";
    final s = (d["status"] as int?) ?? -1;
    var fm = m;
    if (s > 0) {
      await FlutterClipboard.copy("https://go.mazhangjing.com/$keyword");
      fm = fm + "，已将链接拷贝到剪贴板。";
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(fm),
        action: SnackBarAction(label: "OK", onPressed: () {})));
  }
}

class MovieDetailView extends ConsumerStatefulWidget {
  final Movie movie;
  const MovieDetailView(this.movie, {super.key});

  @override
  ConsumerState<MovieDetailView> createState() => _MovieDetailViewState();
}

class _MovieDetailViewState extends ConsumerState<MovieDetailView> {
  @override
  Widget build(BuildContext context) {
    final data =
        ref.watch(fetchMovieDetailProvider.call(widget.movie.url!, true)).value;
    final setting = ref.watch(movieSettingsProvider).value;
    final isWanted = setting?.wantItems.contains(widget.movie.url!) ?? false;
    final x = data?.img == null ? 0.3 : 1.0;
    return Scaffold(
        body: CustomScrollView(slivers: [
      SliverAppBar.large(
          title: Text(widget.movie.title.toString()),
          expandedHeight: 230,
          actions: [
            IconButton(
                onPressed: () async {
                  final _ = await ref.refresh(fetchMovieDetailProvider
                      .call(widget.movie.url!, false)
                      .future);
                  ref.invalidate(
                      fetchMovieDetailProvider.call(widget.movie.url!, true));
                },
                icon: const Icon(Icons.refresh)),
            IconButton(
                onPressed: () => launchUrlString(widget.movie.url!),
                icon: const Icon(Icons.open_in_browser))
          ],
          flexibleSpace: FlexibleSpaceBar(
              background: Stack(
            fit: StackFit.expand,
            children: [
              ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: CachedNetworkImage(
                    imageUrl: widget.movie.img!,
                    fit: BoxFit.fitWidth,
                    repeat: ImageRepeat.repeat,
                  )),
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: Hero(
                    tag: widget.movie.url!,
                    child: CachedNetworkImage(
                      imageUrl: widget.movie.img!,
                      fit: BoxFit.fitHeight,
                    )),
              )
            ],
          ))),
      SliverToBoxAdapter(
          child: AnimatedOpacity(
              opacity: x,
              duration: const Duration(milliseconds: 500),
              child: Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10, top: 5),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(
                                        data?.title ??
                                            widget.movie.title ??
                                            "-",
                                        style: const TextStyle(
                                            fontSize: 30,
                                            overflow: TextOverflow.fade)),
                                    Text(data?.titleEn ?? "",
                                        style: const TextStyle(fontSize: 15))
                                  ])),
                              Container(
                                  width: 2,
                                  height: 80,
                                  margin: const EdgeInsets.only(right: 3),
                                  color:
                                      const Color.fromARGB(255, 222, 222, 222)),
                              buildRating(data)
                            ]),
                        const SizedBox(height: 5),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(data?.year ?? ""),
                              const SizedBox(width: 5),
                              Text(data?.country ?? ""),
                              const SizedBox(width: 5),
                              Text(data?.duration ?? "",
                                  style: const TextStyle(
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.grey,
                                      decorationStyle:
                                          TextDecorationStyle.dashed,
                                      decorationThickness: 3)),
                              const Spacer(),
                              data?.level.isEmpty ?? true
                                  ? const SizedBox()
                                  : Container(
                                      decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(3.0)),
                                      padding: const EdgeInsets.only(
                                          left: 7, right: 7, bottom: 2, top: 2),
                                      margin: const EdgeInsets.only(right: 7),
                                      child: Text(data?.level ?? "",
                                          style: const TextStyle(
                                              color: Colors.white)))
                            ]),
                        ...data?.update.isEmpty ?? true
                            ? []
                            : [
                                Text(data?.update ?? "",
                                    style: const TextStyle(color: Colors.green))
                              ],
                        const SizedBox(height: 15),
                        Text(data?.description ?? ""),
                        const SizedBox(height: 20),
                      ])))),
      SliverFillRemaining(
          hasScrollBody: false,
          child: Column(children: [
            const Spacer(),
            ButtonBar(alignment: MainAxisAlignment.center, children: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("返回")),
              TextButton(
                  onPressed: () => launchUrlString(widget.movie.url!),
                  child: const Text("查看资源...")),
              // TextButton(
              //     onPressed: () => launchUrlString(widget.movie.url!),
              //     child: const Text("添加追踪")),
              TextButton(
                  onPressed: () {
                    ref
                        .read(movieSettingsProvider.notifier)
                        .makeWanted(widget.movie.url!, reverse: isWanted);
                  },
                  child: Row(children: [
                    Icon(
                      isWanted ? Icons.star : Icons.star_border_outlined,
                      color: Colors.yellow,
                    ),
                    const SizedBox(width: 3),
                    Text(isWanted ? "取消想看" : "想看")
                  ])),
              // TextButton(
              //     onPressed: () => launchUrlString(widget.movie.url!),
              //     child: const Text("加入黑名单"))
            ])
          ]))
    ]));
  }

  Padding buildRating(MovieDetail? data) {
    var doubanCount = data?.rating.doubanCount ?? "";
    if (doubanCount == "人评价") {
      doubanCount = "0人评价";
    }
    var imbdCount = data?.rating.imdbCount ?? "";
    if (imbdCount == "人评价") {
      imbdCount = "0人评价";
    }
    return Padding(
        padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 10),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(data?.rating.imdbStar ?? "-",
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1)),
                  Transform.translate(
                      offset: const Offset(2, 2), child: const Text("IMDB"))
                ],
              ),
              Text(imbdCount, style: const TextStyle(fontSize: 10)),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(data?.rating.doubanStar ?? "-",
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1)),
                  Transform.translate(
                      offset: const Offset(2, 2), child: const Text("豆瓣"))
                ],
              ),
              Text(doubanCount, style: const TextStyle(fontSize: 10))
            ]));
  }
}

class MovieCard extends StatelessWidget {
  final bool watched;
  final bool want;
  final bool isTracking;
  final bool ignored;
  const MovieCard(
      {super.key,
      required this.e,
      required this.watched,
      required this.ignored,
      required this.isTracking,
      required this.want});

  final Movie e;

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.bottomCenter, children: [
      Positioned.fill(
          child: Hero(
              tag: e.url!,
              child: CachedNetworkImage(imageUrl: e.img!, fit: BoxFit.cover))),
      Positioned(
          top: 0,
          left: 0,
          child: CustomPaint(
              painter: ReadPainter(
                  draw: isTracking
                      ? "在追"
                      : watched
                          ? "已看"
                          : ignored
                              ? "忽略"
                              : want
                                  ? "想看"
                                  : null,
                  color: isTracking
                      ? Colors.red
                      : ignored
                          ? const Color.fromARGB(255, 0, 0, 0)
                          : want
                              ? const Color.fromARGB(255, 8, 193, 20)
                              : const Color.fromARGB(255, 13, 32, 243)))),
      Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
              alignment: Alignment.centerLeft,
              padding:
                  const EdgeInsets.only(left: 10, right: 10, bottom: 5, top: 5),
              color: const Color(0x9E2F2F2F), //
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(e.title!,
                              style: const TextStyle(color: Colors.white),
                              softWrap: false,
                              overflow: TextOverflow.fade),
                          Text(e.update!,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10))
                        ])),
                    Text(e.star! == "-" ? "" : e.star!,
                        style: const TextStyle(color: Colors.white))
                  ])))
    ]);
  }
}

class ReadPainter extends CustomPainter {
  final String? draw;
  final Color? color;

  ReadPainter({super.repaint, required this.draw, this.color});
  @override
  void paint(Canvas canvas, Size size) {
    if (draw == null) return;
    const w = 36.0;
    var paint = Paint()..color = color ?? Colors.black.withOpacity(0.4);
    var path = Path();
    path.moveTo(15, 0);
    path.lineTo(w, 0);
    path.lineTo(0, w);
    path.lineTo(0, 15);
    path.close();
    canvas.drawPath(path, paint);
    canvas.rotate(-0.8);
    canvas.drawParagraph(
        (ParagraphBuilder(
                ParagraphStyle(fontSize: 9, textAlign: TextAlign.center))
              ..pushStyle(ui.TextStyle(color: Colors.white))
              ..addText(draw!)
              ..pop())
            .build()
          ..layout(const ui.ParagraphConstraints(width: 30)),
        const Offset(-16, 12));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return (oldDelegate as ReadPainter).draw != draw;
  }
}

class MovieFilterView extends ConsumerStatefulWidget {
  const MovieFilterView({super.key});

  @override
  ConsumerState<MovieFilterView> createState() => _MovieFilterViewState();
}

class _MovieFilterViewState extends ConsumerState<MovieFilterView> {
  @override
  Widget build(BuildContext context) {
    var filter = ref.watch(movieFiltersProvider);
    final avgStar = filter.avgStar;
    final selectStar = filter.selectStar;
    final allTags = filter.allTags;
    final selectTags = filter.selectTags;
    var filterChips = Wrap(
        children: allTags
            .map((e) => FilterChip(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.only(left: 0, right: 0),
                labelPadding: const EdgeInsets.only(left: 10, right: 10),
                color: const MaterialStatePropertyAll(Colors.black),
                showCheckmark: false,
                checkmarkColor: Colors.white,
                side: BorderSide(
                    color: selectTags.contains(e)
                        ? Colors.white
                        : Colors.transparent),
                label: Text(e, style: const TextStyle(color: Colors.white)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                selected: selectTags.contains(e),
                onSelected: (_) =>
                    ref.read(movieFiltersProvider.notifier).toggleTag(e)))
            .toList(growable: false),
        spacing: 5,
        runSpacing: 5);
    return Scaffold(
        backgroundColor: Colors.black,
        body: SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
                child: DefaultTextStyle(
                    style: const TextStyle(color: Colors.white),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...filterChips.children.isEmpty
                              ? []
                              : [
                                  Padding(
                                      padding: const EdgeInsets.only(bottom: 5),
                                      child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text("按类别过滤"),
                                            TextButton(
                                                onPressed: ref
                                                    .read(movieFiltersProvider
                                                        .notifier)
                                                    .cleanSelectTags,
                                                child: const Text("清空过滤器"))
                                          ])),
                                  filterChips,
                                  const SizedBox(height: 20)
                                ],
                          const Text("按星级过滤"),
                          Slider(
                              thumbColor: Colors.white,
                              secondaryTrackValue: avgStar,
                              value: selectStar,
                              min: 0,
                              max: 9,
                              divisions: 9,
                              label: selectStar == 0
                                  ? " 任意星级 "
                                  : " 大于 $selectStar 星 ",
                              onChanged: (v) => ref
                                  .read(movieFiltersProvider.notifier)
                                  .setStar(v)),
                          const SizedBox(height: 20),
                          Row(children: [
                            const Text("显示已观看"),
                            const Spacer(),
                            Switch.adaptive(
                                value: filter.showWatched,
                                onChanged: (v) => ref
                                    .read(movieFiltersProvider.notifier)
                                    .setShowWatched(v))
                          ]),
                          Row(children: [
                            const Text("显示正追踪"),
                            const Spacer(),
                            Switch.adaptive(
                                value: filter.showTracked,
                                onChanged: (v) => ref
                                    .read(movieFiltersProvider.notifier)
                                    .setShowTracked(v))
                          ]),
                          Row(children: [
                            const Text("显示已忽略"),
                            const Spacer(),
                            Switch.adaptive(
                                value: filter.showIgnored,
                                onChanged: (v) => ref
                                    .read(movieFiltersProvider.notifier)
                                    .setShowIgnored(v))
                          ]),
                          Row(children: [
                            const Text("不显示想看"),
                            const Spacer(),
                            Switch.adaptive(
                                value: filter.hideWant,
                                onChanged: (v) => ref
                                    .read(movieFiltersProvider.notifier)
                                    .setHideWant(v))
                          ]),
                          Row(children: [
                            const Text("想看、评分排序"),
                            const Spacer(),
                            Switch.adaptive(
                                value: filter.useSort,
                                onChanged: (v) => ref
                                    .read(movieFiltersProvider.notifier)
                                    .setUseSort(v))
                          ]),
                          const SizedBox(height: 20)
                        ])))));
  }
}

class SeriesSubscribeView extends ConsumerStatefulWidget {
  final Movie? addMovie;
  final Movie? delMovie;
  const SeriesSubscribeView({super.key, this.addMovie, this.delMovie});

  @override
  ConsumerState<SeriesSubscribeView> createState() =>
      _SeriesSubscribeViewState();
}

class _SeriesSubscribeViewState extends ConsumerState<SeriesSubscribeView> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (widget.addMovie != null) {
        await handleAdd(widget.addMovie!.title, widget.addMovie!.url);
      }
      if (widget.delMovie != null) {
        ref
            .read(seriesDBProvider.notifier)
            .deleteByUrl(widget.delMovie!.url!)
            .then((msg) => showDialog(
                context: context,
                builder: (ctx) => Theme(
                    data: appThemeData,
                    child: AlertDialog(
                        title: const Text("结果"),
                        content: Text(msg),
                        actions: [
                          TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                ref.invalidate(seriesDBProvider);
                              },
                              child: const Text("确定"))
                        ]))));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(seriesDBProvider).value;
    Widget content;
    if (data == null) {
      content = const Center(child: CupertinoActivityIndicator());
    } else {
      final now = DateTime.now();
      content = RefreshIndicator(
          onRefresh: () async => await ref.refresh(seriesDBProvider),
          child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                return SeriesSubscribeItem(item, now, key: ValueKey(item.id));
              }));
    }
    return Theme(
        data: appThemeData,
        child: Scaffold(
            appBar: AppBar(title: const Text('Series Subscribe'), actions: [
              IconButton(
                  onPressed: () => handleAdd(null, null),
                  icon: const Icon(Icons.add))
            ]),
            body: content));
  }

  handleAdd(String? name, String? url) async {
    final nameC = TextEditingController(text: name);
    final urlC = TextEditingController(text: url);
    var nameErr = "";
    var urlErr = "";
    final urlTextField = TextField(
        controller: urlC,
        decoration: InputDecoration(
            errorText: urlErr.isEmpty ? null : urlErr,
            suffix: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                  onPressed: () async {
                    final data = await Clipboard.getData("text/plain");
                    urlC.text = data!.text ?? "";
                  },
                  icon: const Icon(Icons.paste, size: 16)),
              IconButton(
                  onPressed: () async {
                    final name = urlC.text.isEmpty
                        ? null
                        : await ref
                            .read(seriesDBProvider.notifier)
                            .findName(urlC.text);
                    if (name == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("无法从 URL 解析名称")));
                    } else {
                      nameC.text = name;
                      setState(() {});
                    }
                  },
                  icon: const Icon(Icons.find_in_page, size: 16))
            ]),
            labelText: "URL",
            hintText: "请输入URL",
            border: const UnderlineInputBorder()));
    handleCheckAndAdd() async {
      nameErr = "";
      urlErr = "";
      if (nameC.text.isEmpty) {
        nameErr = "名称不允许为空";
      }
      if (urlC.text.isEmpty) {
        urlErr = "URL 不允许为空";
      } else if (RegExp(r"^https?://").hasMatch(urlC.text) == false) {
        urlErr = "URL 不合法";
      }
      if (nameErr.isNotEmpty || urlErr.isNotEmpty) {
        setState(() {});
        return;
      }
      final res =
          await ref.read(seriesDBProvider.notifier).add(nameC.text, urlC.text);
      await showDialog(
          context: context,
          builder: (ctx) => Theme(
              data: appThemeData,
              child: AlertDialog(
                  title: const Text("结果"),
                  content: Text(res),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          ref.invalidate(seriesDBProvider);
                        },
                        child: const Text("确定"))
                  ])));
    }

    await showDialog(
        context: context,
        builder: (context) => Theme(
            data: appThemeData,
            child: StatefulBuilder(
                builder: (context, setState) => AlertDialog(
                        title: const Text("添加追踪"),
                        content:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          TextField(
                              controller: nameC,
                              decoration: InputDecoration(
                                  errorText: nameErr.isEmpty ? null : nameErr,
                                  labelText: "名称",
                                  hintText: "请输入名称",
                                  border: const UnderlineInputBorder())),
                          urlTextField
                        ]),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text("取消")),
                          TextButton(
                              onPressed: handleCheckAndAdd,
                              child: const Text("确定"))
                        ]))));
  }
}

class SeriesSubscribeItem extends ConsumerStatefulWidget {
  final Series item;
  final DateTime now;
  const SeriesSubscribeItem(this.item, this.now, {super.key});

  @override
  ConsumerState<SeriesSubscribeItem> createState() =>
      _SeriesSubscribeItemStatus();
}

class _SeriesSubscribeItemStatus extends ConsumerState<SeriesSubscribeItem> {
  late Series item;
  late List<String> series;
  late bool recentUpdate;
  late String lastUpdate;
  late bool lastWatched;
  late String updateAt;

  @override
  Widget build(BuildContext context) {
    item = widget.item;
    series = [...item.info.series];
    series.sort();
    recentUpdate = widget.now.difference(item.updateAt).inDays < 3;
    lastUpdate = series.lastOrNull ?? "无更新信息";
    lastWatched = item.info.watched.contains(lastUpdate);
    updateAt = DateFormat("yyyy-MM-dd HH:mm").format(item.updateAt);
    return ListTile(
        onTap: () => handleTapItem(item, lastUpdate),
        title: Row(children: [
          Container(
              padding: const EdgeInsets.only(left: 8, right: 8),
              decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 60, 61, 60),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(item.id.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12))),
          const SizedBox(width: 5),
          Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold))
        ]),
        subtitle:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 4),
          RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                  text: lastUpdate,
                  style: recentUpdate
                      ? const TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          color: Colors.green)
                      : TextStyle(
                          color: Theme.of(context).colorScheme.onBackground),
                  children: [
                    if (lastWatched)
                      TextSpan(
                          text: " (已看)",
                          style: TextStyle(
                              color: recentUpdate
                                  ? Colors.green
                                  : Theme.of(context)
                                      .colorScheme
                                      .onBackground)),
                    TextSpan(
                        text: " @$updateAt",
                        style: const TextStyle(
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.normal,
                            color: Colors.grey,
                            fontSize: 12)),
                  ]))
        ]));
  }

  handleTapItem(Series item, String lastUpdate) {
    handleDelete() async {
      Navigator.of(context).pop();
      final msg = await ref.read(seriesDBProvider.notifier).delete(item.id);
      await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: const Text("结果"),
                  content: Text(msg),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ref.invalidate(seriesDBProvider);
                        },
                        child: const Text("确定"))
                  ]));
    }

    handleUpdate() async {
      Navigator.of(context).pop();
      final msg = await ref
          .read(seriesDBProvider.notifier)
          .updateWatched(item.name, lastUpdate);
      await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: const Text("结果"),
                  content: Text(msg),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ref.invalidate(seriesDBProvider);
                        },
                        child: const Text("确定"))
                  ]));
    }

    handleUpdateAll() async {
      Navigator.of(context).pop();
      final msg = await ref
          .read(seriesDBProvider.notifier)
          .updateAllWatched(item.name, item.info.series);
      await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: const Text("结果"),
                  content: Text(msg),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ref.invalidate(seriesDBProvider);
                        },
                        child: const Text("确定"))
                  ]));
    }

    showDialog(
        context: context,
        builder: (ctx) => SimpleDialog(title: Text(item.name), children: [
              SimpleDialogOption(
                  onPressed: () => launchUrlString(item.url),
                  child: const Text("查看详情...")),
              SimpleDialogOption(
                  onPressed: handleUpdateAll, child: const Text("标记所有已看")),
              SimpleDialogOption(
                  onPressed: handleUpdate, child: const Text("标记当前已看")),
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(item.toString()),
                        duration: const Duration(seconds: 120)));
                  },
                  child: const Text("调试信息")),
              SimpleDialogOption(
                  onPressed: handleDelete,
                  child: Text("删除追踪",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)))
            ]));
  }
}
