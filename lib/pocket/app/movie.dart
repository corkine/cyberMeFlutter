import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../config.dart';
import '../models/movie.dart';

class MovieView extends StatefulWidget {
  const MovieView({super.key});

  @override
  State<MovieView> createState() => _MovieViewState();
}

class _MovieViewState extends State<MovieView> {
  late Config config;

  bool showTv = true;
  bool showHot = true;

  List<Movie> movie = [];
  List<Movie> movieFiltered = [];
  var filter = MovieFilter();

  bool loading = false;

  @override
  void initState() {
    super.initState();
    config = Provider.of<Config>(context, listen: false);
    fetchAndUpdateData(config);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: buildAppBar(),
        body: Stack(children: [
          RefreshIndicator(
              onRefresh: () async => await fetchAndUpdateData(config),
              child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 150, childAspectRatio: 0.7),
                  itemCount: movieFiltered.length,
                  itemBuilder: (c, i) {
                    final e = movieFiltered[i];
                    return InkWell(
                        onTap: () => launchUrlString(e.url!),
                        onLongPress: () => handleAddShortLink(config, e.url!),
                        child: MovieCard(e: e, key: ObjectKey(e)));
                  })),
          Positioned(
              child: SafeArea(
                  child: Container(
                      margin: const EdgeInsets.only(
                          left: 10, right: 10, bottom: 10),
                      decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10)),
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
                                            setMovieAndFiltered(
                                                justFilter: true);
                                            return true;
                                          },
                                          child: MovieFilterView(
                                              filter: filter, movies: movie),
                                        ));
                              }),
                          child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(buildFilterText(),
                                        style: const TextStyle(
                                            color: Colors.white))
                                  ]))))),
              left: 0,
              right: 0,
              bottom: 0)
        ]));
  }

  AppBar buildAppBar() {
    return AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black26,
        title: buildTitle(),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  showTv = !showTv;
                });
                fetchAndUpdateData(config);
              },
              icon: Icon(showTv ? Icons.tv : Icons.movie)),
          IconButton(
              onPressed: () {
                setState(() {
                  showHot = !showHot;
                });
                fetchAndUpdateData(config);
              },
              icon: Icon(showHot
                  ? Icons.local_fire_department_outlined
                  : Icons.new_releases))
        ]);
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

  Future fetchAndUpdateData(Config config) async {
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

  Future handleAddShortLink(Config config, String url) async {
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
  const MovieCard({
    super.key,
    required this.e,
  });

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
                          Wrap(
                              children: types
                                  .map((e) => FilterChip(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.only(
                                          left: 0, right: 0),
                                      labelPadding: const EdgeInsets.only(
                                          left: 10, right: 10),
                                      color: const MaterialStatePropertyAll(
                                          Colors.black),
                                      showCheckmark: false,
                                      checkmarkColor: Colors.white,
                                      side: BorderSide(
                                          color: widget.filter.filteredTypes
                                                  .contains(e)
                                              ? Colors.white
                                              : Colors.transparent),
                                      label: Text(e,
                                          style: const TextStyle(
                                              color: Colors.white)),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                      selected: widget.filter.filteredTypes
                                          .contains(e),
                                      onSelected: (_) => setState(() {
                                            if (widget.filter.filteredTypes
                                                .contains(e)) {
                                              widget.filter.filteredTypes
                                                  .remove(e);
                                            } else {
                                              widget.filter.filteredTypes
                                                  .add(e);
                                            }
                                          })))
                                  .toList(growable: false),
                              spacing: 5,
                              runSpacing: 5),
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
