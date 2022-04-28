import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SNHApp extends StatelessWidget {
  const SNHApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: Theme.of(context).copyWith(
          primaryColor: const Color(0xFFE87797),
          appBarTheme:
              AppBarTheme.of(context).copyWith(color: const Color(0xFFE87797))),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("SNH48 Pocket"),
        ),
        body: const SNH(),
      ),
    );
  }
}

class SNH extends StatefulWidget {
  const SNH({Key? key}) : super(key: key);

  @override
  State<SNH> createState() => _SNHState();
}

class _SNHState extends State<SNH> {
  @override
  void initState() {
    future = Bean.fetchData();
    super.initState();
  }

  late Future<List<Idol>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (c, d) {
        if (d.hasData) {
          final List<Idol> data = d.data as List<Idol>;
          return RefreshIndicator(
            onRefresh: () async {
              final res = await Bean.fetchData();
              setState(() {
                future = Future.value(res);
              });
            },
            child: Scrollbar(
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: MySPH("Team SII", const Color(0xff91cdeb)),
                  ),
                  buildSliverList(data, "SII"),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: MySPH("Team NII", const Color(0xffae86bb)),
                  ),
                  buildSliverList(data, "NII"),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: MySPH("Team HII", const Color(0xff398000)),
                  ),
                  buildSliverList(data, "HII"),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: MySPH("Team X", const Color(0xffa9cc29)),
                  ),
                  buildSliverList(data, "X")
                ],
              ),
            ),
          );
        } else if (d.hasError) {
          return Text("Oops: ${d.error}");
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  SliverPadding buildSliverList(List<Idol> data, String teamName) {
    data = data.where((element) => element.teamName == teamName).toList();
    return SliverPadding(
      padding: const EdgeInsets.only(top: 5, bottom: 20),
      sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, childAspectRatio: 1 / 1.1),
          delegate: SliverChildBuilderDelegate((c, index) {
            Idol p = data[index];
            return InkWell(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (c) {
                  return IdolDetail(p);
                }));
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: p.avatarUrl,
                    child: ClipOval(
                      child: CircleAvatar(
                        child: Image.network(p.avatarUrl),
                        backgroundColor: Colors.white,
                        radius: 32,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 5),
                    child: Text(p.sname),
                  )
                ],
              ),
            );
          }, childCount: data.length)),
    );
  }
}

class IdolDetail extends StatelessWidget {
  Idol p;

  IdolDetail(this.p, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            stretch: true,
            pinned: true,
            leading: const BackButton(color: Colors.black,),
            expandedHeight: 300,
            backgroundColor: Colors.pink[100],
            automaticallyImplyLeading: true,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.fadeTitle,
                StretchMode.zoomBackground
              ],
              collapseMode: CollapseMode.parallax,
              titlePadding: const EdgeInsets.only(right: 10, bottom: 10, left: 10),
              title: Container(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Colors.pink[100]!.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2)),
                  padding: const EdgeInsets.only(left: 10, right: 10, bottom: 3),
                  child: Text(
                    p.name,
                    style: const TextStyle(color: Colors.black),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              background: Hero(
                tag: p.avatarUrl,
                child: Opacity(
                  opacity: 0.9,
                  child: Image.network(
                    p.avatarUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          SliverList(
              delegate: SliverChildListDelegate([
            buildCard("编号", p.sid.toString()),
            buildCard("组名", p.gname),
            buildCard("名字", p.sname),
            buildCard("昵称", p.nickname),
            buildCard("公司", p.company),
            buildCard("加入日期", p.join_day),
            buildCard("身高", "${p.height} cm"),
            buildCard("生日", p.birth_day),
            buildCard("星座", p.star_sign_12),
            buildCard("出生地", p.birth_place),
            buildCard("特长", p.speciality),
            buildCard("爱好", p.hobby),
            buildCard("经历", p.experience),
            buildCard("微博", p.weibo_uid),
            buildCard("组名", p.tname)
          ]))
        ],
      ),
    );
  }

  buildCard(String title, String text) {
    return Card(
      elevation: 0.2,
      margin: const EdgeInsets.only(bottom: 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title),
            Text(
              text,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16),
            )
          ],
        ),
      ),
    );
  }
}

class MySPH extends SliverPersistentHeaderDelegate {
  final String title;
  final Color color;
  MySPH(this.title, this.color);
  @override Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
        alignment: Alignment.center,
        color: color,
        height: 40,
        width: double.infinity,
        child: Text(
          title,
          style: const TextStyle(fontSize: 22, color: Colors.white),
        ));
  }
  @override double get maxExtent => 40;
  @override double get minExtent => 40;
  @override bool shouldRebuild(covariant MySPH oldDelegate) {
    return oldDelegate.title != title;
  }
}

class Idol {
  int sid;
  int gid;
  String gname;
  String sname;
  String fname;
  String pinyin;
  String abbr;
  int tid;
  int pid;
  String tname;
  String nickname;
  String company;
  String join_day;
  int height;
  String birth_day;
  String star_sign_12;
  String birth_place;
  String speciality;
  String hobby;
  String experience;
  String weibo_uid;
  String tcolor;
  String gcolor;

  String get avatarUrl => "https://www.snh48.com/images/member/zp_$sid.jpg";

  String get teamName => tname;

  String get name => sname;

  Idol.of(
      this.sid,
      this.gid,
      this.gname,
      this.sname,
      this.fname,
      this.pinyin,
      this.abbr,
      this.tid,
      this.pid,
      this.nickname,
      this.company,
      this.join_day,
      this.height,
      this.birth_day,
      this.star_sign_12,
      this.birth_place,
      this.speciality,
      this.hobby,
      this.experience,
      this.weibo_uid,
      this.tcolor,
      this.gcolor,
      this.tname);
}

class Bean {
  static String url = "https://h5.48.cn/resource/jsonp/allmembers.php?gid=10";

  static Future<List<Idol>> fetchData() async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) throw "Error fetch data";
    final List data_list = jsonDecode(res.body)["rows"];
    final data = data_list
        .map((e) => Idol.of(
            int.parse(e["sid"]),
            int.parse(e["gid"]),
            e["gname"],
            e["sname"],
            e["fname"],
            e["pinyin"],
            e["abbr"],
            int.parse(e["tid"]),
            int.parse(e["pid"]),
            e["nickname"],
            e["company"],
            e["join_day"],
            int.parse(e["height"]),
            e["birth_day"],
            e["star_sign_12"],
            e["birth_place"],
            e["speciality"],
            e["hobby"],
            e["experience"],
            e["weibo_uid"],
            e["tcolor"],
            e["gcolor"],
            e["tname"]))
        .toList();
    return data;
  }
}
