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
  bool showTv = true;
  bool showHot = true;

  List<Movie> movie = [];
  List<Movie> movieFiltered = [];
  var filter = MovieFilter();

  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchAndUpdateData();
  }

  @override
  void deactivate() {
    ref.read(movieSettingsProvider.notifier).syncUpload();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final setting = ref.watch(movieSettingsProvider).value;
    final tracking =
        ref.watch(seriesDBProvider).value?.map((e) => e.url).toSet() ?? {};
    var appBar = AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black26,
        title: buildTitle(),
        centerTitle: false,
        actions: [
          IconButton(
              onPressed: () => showModalBottomSheet(
                  context: context,
                  builder: (context) => const SeriesSubscribeView()),
              icon: const Icon(Icons.track_changes_outlined)),
          IconButton(
              onPressed: () {
                setState(() => showTv = !showTv);
                fetchAndUpdateData();
              },
              icon: Icon(showTv ? Icons.tv : Icons.movie)),
          IconButton(
              onPressed: () {
                setState(() => showHot = !showHot);
                fetchAndUpdateData();
              },
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
                      builder: (c) => WillPopScope(
                          onWillPop: () async {
                            setState(() {});
                            setMovieAndFiltered(justFilter: true);
                            return true;
                          },
                          child:
                              MovieFilterView(filter: filter, movies: movie)));
                }),
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(buildFilterText(),
                          style: const TextStyle(color: Colors.white))
                    ]))));

    return Scaffold(
        backgroundColor: Colors.black,
        appBar: appBar,
        body: Stack(children: [
          RefreshIndicator(
              onRefresh: fetchAndUpdateData,
              child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 150, childAspectRatio: 0.7),
                  itemCount: movieFiltered.length,
                  itemBuilder: (c, i) {
                    final e = movieFiltered[i];
                    final isWatched = showTv
                        ? setting?.watchedTv.contains(e.url) ?? false
                        : setting?.watchedMovie.contains(e.url) ?? false;
                    final isTracking = tracking.contains(e.url);
                    return InkWell(
                        onTap: () =>
                            showItemMenu(e, showTv, isWatched, isTracking),
                        child: MovieCard(
                            e: e,
                            key: ObjectKey(e),
                            watched: isWatched,
                            isTracking: isTracking));
                  })),
          Positioned(
              child: SafeArea(child: searchBar), left: 0, right: 0, bottom: 0)
        ]));
  }

  void showItemMenu(Movie e, bool isTv, bool isWatched, bool isTracking) {
    List<Widget> opts;
    if (showTv) {
      opts = [
        SimpleDialogOption(
            onPressed: showTv
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
        SimpleDialogOption(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(movieSettingsProvider.notifier)
                  .makeWatched(showTv, e.url!, reverse: isWatched);
            },
            child: Text(isWatched ? "标记为未观看" : "标记为已观看"))
      ];
    } else {
      opts = [
        SimpleDialogOption(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(movieSettingsProvider.notifier)
                  .makeWatched(showTv, e.url!, reverse: isWatched);
            },
            child: Text(isWatched ? "标记为未观看" : "标记为已观看"))
      ];
    }
    showDialog(
        context: context,
        builder: (context) => Theme(
            data: appThemeData,
            child: SimpleDialog(title: Text(e.title!), children: [
              ...opts,
              SimpleDialogOption(
                  onPressed: () => launchUrlString(e.url!),
                  child: const Text("在站点查看详情...")),
              SimpleDialogOption(
                  onPressed: () => handleAddShortLink(e.url!),
                  child: const Text("生成短链接..."))
            ])));
  }

  Widget buildTitle() {
    final fl = Text(
        "${showHot ? "🔥" : "NEW"} MINI4K ${showTv ? "Series" : "Movie"}",
        style: const TextStyle(fontSize: 19));
    final sl = loading
        ? const Text("Loading...", style: TextStyle(fontSize: 10))
        : Text("共 ${movieFiltered.length} 条结果",
            style: const TextStyle(fontSize: 10));
    return Column(children: [fl, const SizedBox(height: 2), sl]);
  }

  String buildFilterText() {
    if (filter.star == 0 && filter.filteredTypes.isEmpty) {
      return "过滤器：关";
    } else if (filter.star != 0 && filter.filteredTypes.isNotEmpty) {
      return "过滤器：大于 ${filter.star.toInt()} 星，选中类别 ${filter.filteredTypes.length} 个";
    } else if (filter.star != 0) {
      return "过滤器：大于 ${filter.star.toInt()} 星";
    } else {
      return "过滤器：选中类别 ${filter.filteredTypes.length} 个";
    }
  }

  setMovieAndFiltered({List<Movie>? netData, bool justFilter = false}) {
    if (!justFilter) {
      movie = netData ?? [];
    }
    movieFiltered = [];
    double star = filter.star;
    Set<String> type = filter.filteredTypes;
    for (final m in movie) {
      if ((double.tryParse(m.star ?? "") ?? 100.0) >= star) {
        if (type.isEmpty || showTv || (!showTv && type.contains(m.update))) {
          movieFiltered.add(m);
        }
      }
    }
  }

  Future fetchAndUpdateData() async {
    setState(() {
      loading = true;
    });
    final r = await get(
        Uri.parse(
            Config.movieUrl(showTv ? "tv" : "movie", showHot ? "hot" : "new")),
        headers: config.cyberBase64Header);
    final d = jsonDecode(r.body);
    final m = d["message"] ?? "没有消息";
    if (((d["status"] as int?) ?? -1) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
      return [];
    }
    final data = d["data"] as List?;
    final md = data
            ?.map((e) => e as Map?)
            .map((e) => Movie.fromJson(e))
            .toList(growable: false) ??
        [];
    setMovieAndFiltered(netData: md, justFilter: false);
    setState(() {
      loading = false;
    });
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

class MovieCard extends StatelessWidget {
  final bool watched;
  final bool isTracking;
  const MovieCard(
      {super.key,
      required this.e,
      required this.watched,
      required this.isTracking});

  final Movie e;

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.bottomCenter, children: [
      Positioned.fill(
          child: Ink(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: CachedNetworkImageProvider(e.img!), fit: BoxFit.cover)),
      )),
      Positioned(
          top: 0,
          left: 0,
          child: CustomPaint(
              painter: ReadPainter(
                  draw: isTracking
                      ? "在追"
                      : watched
                          ? "已看"
                          : null,
                  color: isTracking
                      ? Colors.red
                      : const Color.fromARGB(255, 31, 39, 122)))),
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
                    Text(e.star! == "N/A" ? "" : e.star!,
                        style: const TextStyle(color: Colors.white))
                  ]))
          /*ClipRRect(
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: ))*/
          )
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

class MovieFilter {
  double star = 0;
  Set<String> filteredTypes = {};

  MovieFilter();

  @override
  String toString() {
    return 'MovieFilter{star: $star, filteredTypes: $filteredTypes}';
  }
}

class MovieFilterView extends StatefulWidget {
  final MovieFilter filter;
  final List<Movie> movies;

  const MovieFilterView({
    super.key,
    required this.filter,
    required this.movies,
  });

  @override
  State<MovieFilterView> createState() => _MovieFilterViewState();
}

class _MovieFilterViewState extends State<MovieFilterView> {
  late Set<String> types = {};
  double avgStar = 0;

  @override
  void initState() {
    super.initState();
    avgStar = 0;
    for (final m in widget.movies) {
      if (m.update != null && !m.update!.startsWith("第")) {
        types.add(m.update!);
      }
      if (m.star != null) {
        final s = double.tryParse(m.star!);
        if (s != null) {
          avgStar += s;
        }
      }
    }
    avgStar = avgStar / widget.movies.length;
  }

  @override
  Widget build(BuildContext context) {
    var filterChips = Wrap(
        children: types
            .map((e) => FilterChip(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.only(left: 0, right: 0),
                labelPadding: const EdgeInsets.only(left: 10, right: 10),
                color: const MaterialStatePropertyAll(Colors.black),
                showCheckmark: false,
                checkmarkColor: Colors.white,
                side: BorderSide(
                    color: widget.filter.filteredTypes.contains(e)
                        ? Colors.white
                        : Colors.transparent),
                label: Text(e, style: const TextStyle(color: Colors.white)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                selected: widget.filter.filteredTypes.contains(e),
                onSelected: (_) => setState(() {
                      if (widget.filter.filteredTypes.contains(e)) {
                        widget.filter.filteredTypes.remove(e);
                      } else {
                        widget.filter.filteredTypes.add(e);
                      }
                    })))
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
                          Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("按类别过滤"),
                                    TextButton(
                                        onPressed: () => setState(() =>
                                            widget.filter.filteredTypes = {}),
                                        child: const Text("清空过滤器"))
                                  ])),
                          filterChips,
                          const Padding(
                              padding: EdgeInsets.only(bottom: 0, top: 20),
                              child: Text("按星级过滤")),
                          Slider(
                              thumbColor: Colors.white,
                              secondaryTrackValue: avgStar,
                              value: widget.filter.star.toDouble(),
                              min: 0,
                              max: 9,
                              divisions: 9,
                              label: widget.filter.star == 0
                                  ? " 任意星级 "
                                  : " 大于 ${widget.filter.star} 星 ",
                              onChanged: (v) {
                                setState(() {
                                  widget.filter.star = v;
                                });
                              })
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
  void initState() {
    super.initState();
    item = widget.item;
    series = [...item.info.series];
    series.sort();
    recentUpdate = widget.now.difference(item.updateAt).inDays < 3;
    lastUpdate = series.lastOrNull ?? "无更新信息";
    lastWatched = item.info.watched.contains(lastUpdate);
    updateAt = DateFormat("yyyy-MM-dd HH:mm").format(item.updateAt);
  }

  @override
  Widget build(BuildContext context) {
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
      showDialog(
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
      showDialog(
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
      showDialog(
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
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(item.toString()),
                        duration: const Duration(seconds: 120)));
                  },
                  child: const Text("调试信息")),
              SimpleDialogOption(
                  onPressed: handleUpdateAll, child: const Text("标记所有已看")),
              SimpleDialogOption(
                  onPressed: handleUpdate, child: const Text("标记当前已看")),
              SimpleDialogOption(
                  onPressed: handleDelete, child: const Text("删除"))
            ]));
  }
}
