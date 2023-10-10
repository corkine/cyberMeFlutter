import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    config = Provider.of<Config>(context, listen: false);
    fetchData(config).then((value) => setState(() => movie = value));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
              "Mini4k ${showHot ? "Hot" : "New"} ${showTv ? "Series" : "Movie"}"),
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
          ],
        ),
        body: RefreshIndicator(
            onRefresh: () async => movie = await fetchData(config),
            child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 150, childAspectRatio: 0.7),
                itemCount: movie.length,
                itemBuilder: (c, i) {
                  final e = movie[i];
                  return InkWell(
                      onTap: () {},
                      onLongPress: () => launchUrlString(e.url!),
                      child:
                          Stack(alignment: Alignment.bottomCenter, children: [
                        Positioned.fill(
                            child: Image.network(e.img!, fit: BoxFit.cover)),
                        Positioned(
                            left: 10,
                            top: 4,
                            child: Text("${e.star == "N/A" ? "" : e.star}",
                                style: const TextStyle(color: Colors.white))),
                        Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                                color: Colors.black.withOpacity(0.5),
                                child: Padding(
                                    padding: const EdgeInsets.only(
                                        top: 3, bottom: 3, left: 3, right: 3),
                                    child: Text(e.title!,
                                        style: const TextStyle(
                                            color: Colors.transparent))))),
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 3, bottom: 3, left: 3, right: 3),
                          child: Text(e.title!,
                              style: const TextStyle(color: Colors.white)),
                        )
                      ]));
                })));
  }

  Future<List<Movie>> fetchData(Config config) async {
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
    return md;
  }
}
