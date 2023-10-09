import 'dart:convert';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../config.dart';
import '../models/track.dart';

class TrackView extends StatefulWidget {
  const TrackView({super.key});

  @override
  State<TrackView> createState() => _TrackViewState();
}

Future call() async {}

class _TrackViewState extends State<TrackView> {
  Config? config;

  @override
  void didChangeDependencies() {
    if (config == null) {
      config = Provider.of<Config>(context);
      fetchSvc(config!).then((value) => setState(() {
            data = value;
          }));
    }
    super.didChangeDependencies();
  }

  List<(String, String)> data = [];

  bool justShowTrack = true;

  bool sortByUrl = false;

  @override
  Widget build(BuildContext context) {
    var d = justShowTrack
        ? data
            .where((element) => element.$1.startsWith("/cyber/go/track"))
            .toList(growable: false)
        : data;
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("Track System"),
          actions: [
            IconButton(
                onPressed: () => setState(() {
                      sortByUrl = !sortByUrl;
                      if (sortByUrl) {
                        data.sort((a, b) => b.$1.compareTo(a.$1));
                      } else {
                        data.sort((a, b) =>
                            int.parse(b.$2).compareTo(int.parse(a.$2)));
                      }
                    }),
                icon: Icon(sortByUrl
                    ? Icons.sort_by_alpha
                    : Icons.format_list_numbered)),
            IconButton(
                onPressed: () => setState(() => justShowTrack = !justShowTrack),
                icon: Icon(
                    justShowTrack ? Icons.filter_alt_off : Icons.filter_alt))
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            data = await fetchSvc(config!);
            debugPrint("reload svc done!");
          },
          child: ListView.builder(
              itemBuilder: (ctx, idx) {
                final c = d[idx];
                return ListTile(
                    visualDensity: VisualDensity.compact,
                    title: Text(c.$1),
                    subtitle: Text(c.$2),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (ctx) =>
                            TrackDetailView(url: c.$1, count: c.$2))));
              },
              itemCount: d.length),
        ));
  }

  Future<List<(String, String)>> fetchSvc(Config config) async {
    final Response r = await get(Uri.parse(Config.visitsUrl),
        headers: config.cyberBase64Header);
    final d = jsonDecode(r.body);
    if ((d["status"] as int?) == 1) {
      final res = (d["data"] as List)
          .map((e) => e as List)
          .map((e) => (e.first.toString(), e.last.toString()))
          .toList(growable: false);
      if (sortByUrl) {
        res.sort((a, b) {
          return a.$1.compareTo(b.$1);
        });
      } else {
        res.sort((a, b) {
          return int.parse(b.$2).compareTo(int.parse(a.$2));
        });
      }
      return res;
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(d["message"])));
      return [];
    }
  }
}

class TrackDetailView extends StatefulWidget {
  final String url;
  final String count;

  const TrackDetailView({super.key, required this.url, required this.count});

  @override
  State<TrackDetailView> createState() => _TrackDetailViewState();
}

class _TrackDetailViewState extends State<TrackDetailView> {
  Config? config;

  @override
  void didChangeDependencies() {
    if (config == null) {
      config = Provider.of<Config>(context);
      fetchDetail(config!).then((value) => setState(() {
            logs = value?.logs ?? [];
            isTrack = value?.monitor ?? false;
          }));
    }
    super.didChangeDependencies();
  }

  List<Logs> logs = [];
  bool isTrack = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.url.split("/").last),
          actions: [
            IconButton(
                onPressed: () async {
                  await setTrack(config!, widget.url, !isTrack);
                  final d = await fetchDetail(config!);
                  logs = d?.logs ?? [];
                  isTrack = d?.monitor ?? false;
                  setState(() {});
                },
                icon: Icon(
                    isTrack ? Icons.visibility : Icons.visibility_off_outlined))
          ],
        ),
        body: RefreshIndicator(
            onRefresh: () async {
              final d = await fetchDetail(config!);
              logs = d?.logs ?? [];
              debugPrint("reload svc details done!");
            },
            child: ListView.builder(
                itemBuilder: (ctx, idx) {
                  final c = logs[idx];
                  return ListTile(
                      visualDensity: VisualDensity.compact,
                      onTap: () async {
                        await FlutterClipboard.copy(c.ip ?? "");
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("已拷贝地址到剪贴板")));
                      },
                      onLongPress: () async {
                        await launchUrlString(
                            "https://www.ipshudi.com/${c.ip}.htm");
                      },
                      title: Text(c.ip ?? "No IP"),
                      subtitle:
                          Text(c.timestamp?.split(".").first ?? "No Info"),
                      trailing: Text(c.ipInfo ?? ""));
                },
                itemCount: logs.length)));
  }

  Future<Track?> fetchDetail(Config config) async {
    final Response r = await get(
        Uri.parse(Config.logsUrl(base64Encode(utf8.encode(widget.url)))),
        headers: config.cyberBase64Header);
    final d = jsonDecode(r.body);
    if ((d["status"] as int?) == 1) {
      return Track.fromJson(d["data"]);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(d["message"])));
      return null;
    }
  }

  Future setTrack(Config config, String key, bool trackStatus) async {
    final r = await post(Uri.parse(Config.trackUrl),
        headers: config.cyberBase64JsonContentHeader,
        body: jsonEncode({"key": "visit:" + key, "add": trackStatus}));
    final data = jsonDecode(r.body);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(data["message"])));
  }
}
