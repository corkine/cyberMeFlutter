import 'dart:convert';
import 'dart:math';

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
  bool loading = false;

  @override
  void initState() {
    super.initState();
    config = Provider.of<Config>(context, listen: false);
    fetchData(config).then((value) => setState(() => movie = value));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: buildAppBar(),
        body: RefreshIndicator(
            onRefresh: () async => movie = await fetchData(config),
            child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 150, childAspectRatio: 0.7),
                itemCount: movie.length,
                itemBuilder: (c, i) {
                  final e = movie[i];
                  return InkWell(
                      onTap: () => launchUrlString(e.url!),
                      onLongPress: () => handleAddShortLink(config, e.url!),
                      child: MovieCard(e: e, key: ObjectKey(e)));
                })));
  }

  AppBar buildAppBar() {
    return AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black26,
        title: loading
            ? Column(children: [
                buildTitle(),
                const Text("Loading...", style: TextStyle(fontSize: 10))
              ])
            : buildTitle(),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  showTv = !showTv;
                });
                fetchData(config)
                    .then((value) => setState(() => movie = value));
              },
              icon: Icon(showTv ? Icons.tv : Icons.movie)),
          IconButton(
              onPressed: () {
                setState(() {
                  showHot = !showHot;
                });
                fetchData(config)
                    .then((value) => setState(() => movie = value));
              },
              icon: Icon(showHot
                  ? Icons.local_fire_department_outlined
                  : Icons.new_releases))
        ]);
  }

  Text buildTitle() {
    return Text(
        "Mini4k ${showHot ? "Hot" : "New"} ${showTv ? "Series" : "Movie"}");
  }

  Future<List<Movie>> fetchData(Config config) async {
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
    setState(() {
      loading = false;
    });
    return md;
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
                image: NetworkImage(e.img!), fit: BoxFit.cover)),
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
