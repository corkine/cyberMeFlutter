import 'dart:io';

import 'package:cyberme_flutter/learn/flame/angrybirds/main.dart';
import 'package:cyberme_flutter/learn/flame/brickbreaker.dart';
import 'package:cyberme_flutter/learn/game.dart';
import 'package:cyberme_flutter/learn/snh.dart';
import 'package:cyberme_flutter/pocket/views/info/backup.dart';
import 'package:cyberme_flutter/pocket/views/info/cert.dart';
import 'package:cyberme_flutter/pocket/views/info/counter.dart';
import 'package:cyberme_flutter/pocket/views/info/esxi.dart';
import 'package:cyberme_flutter/pocket/views/info/gallery.dart';
import 'package:cyberme_flutter/pocket/views/info/gitea.dart';
import 'package:cyberme_flutter/pocket/views/live/mass/mass.dart';
import 'package:cyberme_flutter/pocket/views/live/sex.dart';
import 'package:cyberme_flutter/pocket/views/info/link.dart';
import 'package:cyberme_flutter/pocket/views/info/location.dart';
import 'package:cyberme_flutter/pocket/views/server/service.dart';
import 'package:cyberme_flutter/pocket/views/news/story.dart';
import 'package:cyberme_flutter/pocket/views/think/block.dart';
import 'views/info/blog.dart';
import 'views/live/blue.dart';
import 'views/think/gpt.dart';
import 'views/live/medic.dart';
import 'views/think/sticky.dart';
import 'dashboard.dart' as dash;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'views/news/movie.dart';
import 'views/news/tugua.dart';
import 'day.dart';
import '../learn/goods.dart';
import '../learn/link.dart';
import 'config.dart';
import 'auth.dart' as auth;
import '../learn/shortcut.dart' as short;
import 'diary.dart' as diary;
import 'views/info/ticket.dart';
import 'views/info/express.dart';
import 'views/think/todo/todo.dart';
import 'views/info/track/track.dart';

final apps = {
  "dashboard": {
    "name": "我的一天",
    "view": (c) => const PocketHome(),
    "addToMenu": true,
    "replace": true,
    "addToContext": false,
    "icon": Icons.calendar_month
  },
  "bigDashboard": {
    "name": "大屏",
    "view": (c) => const dash.DashHome(),
    "addToMenu": true,
    "addToContext": false,
    "replace": false
  },
  "ticket": {
    "name": "12306 车票",
    "view": (c) => const TicketShowPage(),
    "addToMenu": true,
    "addToContext": true,
    "icon": Icons.airplane_ticket
  },
  "express": {
    "name": "快递追踪",
    "view": (c) => const ExpressView(),
    "addToMenu": true,
    "addToContext": true,
    "icon": Icons.card_giftcard
  },
  "service": {
    "name": "服务追踪",
    "view": (c) => const TrackView(),
    "addToMenu": true,
    "addToContext": true,
    "icon": Icons.dashboard
  },
  "todo": {
    "name": "待办事项",
    "view": (c) => const TodoView(),
    "addToMenu": true,
    "addToContext": true,
    "icon": Icons.check_box
  },
  "sexual": {
    "name": "Sexual",
    "view": (c) => const SexualActivityView(),
    "addToMenu": true,
    "addToContext": true,
    "icon": Icons.people
  },
  "bodyMass": {
    "name": "体重记录",
    "view": (c) => const MassActivityView(),
    "addToMenu": true,
    "addToContext": true,
    "icon": Icons.fit_screen
  },
  "score": {
    "name": "积分系统",
    "view": (c) => const ScoreView(),
    "addToMenu": true,
    "addToContext": false,
    "icon": Icons.margin
  },
  "show": {
    "name": "影视热榜",
    "view": (c) => const MovieView(),
    "addToMenu": true,
    "addToContext": false,
    "icon": Icons.movie
  },
  "dapenti": {
    "name": "喷嚏图卦",
    "view": (c) => const TuguaView(),
    "addToMenu": true,
    "addToContext": true,
    "icon": Icons.newspaper
  },
  "story": {
    "name": "故事社",
    "view": (c) => const StoryView(),
    "addToMenu": true,
    "addToContext": false,
    "icon": Icons.bookmark_add
  },
  "esxi": {
    "name": "ESXi",
    "view": (c) => const EsxiView(),
    "addToMenu": true,
    "addToContext": true,
    "icon": Icons.computer
  },
  "blog": {
    "name": "博客",
    "view": (c) => const BlogView(),
    "addToMenu": true,
    "addToContext": false,
    "icon": Icons.article
  },
  "gitea": {
    "name": "Gitea",
    "view": (c) => const GiteaView(),
    "addToMenu": true,
    "addToContext": false,
    "icon": Icons.source
  },
  "gpt": {
    "name": "GPT",
    "view": (c) => const GPTView(),
    "addToMenu": true,
    "icon": Icons.android
  },
  "location": {
    "name": "位置管理",
    "view": (c) => const LocationView(),
    "addToMenu": true,
    "icon": Icons.map
  },
  "link": {
    "name": "短链接管理",
    "view": (c) => const QuickLinkView(),
    "addToMenu": true,
    "addToContext": true,
    "icon": Icons.link
  },
  "medic": {
    "name": "药物管理",
    "view": (c) => const MedicView(),
    "addToMenu": false,
    "addToContext": false,
    "icon": Icons.medical_services_sharp
  },
  "calcgame": {
    "name": "健康游戏",
    "view": (c) => const Game(info: null),
    "addToMenu": true,
    "addToContext": false,
    "icon": Icons.gamepad
  },
  "brickbreaker": {
    "name": "打砖块",
    "view": (c) => const BrickBreakerGame(),
    "addToMenu": true,
    "addToContext": false,
    "icon": Icons.gamepad
  },
  "angrybirds": {
    "name": "愤怒的小鸟",
    "view": (c) => const AngryBirdsGameSimple(),
    "addToMenu": true,
    "addToContext": false,
    "icon": Icons.gamepad
  },
  "snh48": {
    "name": "SNH Pocket",
    "view": (c) => const SNHApp(),
    "addToMenu": true,
    "addToContext": false,
    "icon": Icons.heart_broken_rounded
  },
  "counter": {
    "name": "Counter",
    "view": (c) => const FuckCounterView(),
    "addToMenu": true,
    "addToContext": false,
    "icon": Icons.countertops
  },
  "backup": {
    "name": "Backup",
    "view": (c) => const BackupView(),
    "addToMenu": true,
    "addToContext": false,
    "icon": Icons.backup
  },
  "gallery": {
    "name": "Gallery",
    "view": (c) => const GalleryManagerScreen(),
    "addToMenu": true,
    "addToContext": false,
    "icon": Icons.image
  },
  "cert-manager": {
    "name": "证书管理",
    "view": (c) => const CertConfigView(),
    "addToMenu": true,
    "addToContext": true,
    "icon": Icons.security
  },
  "server": {
    "name": "服务管理",
    "view": (c) => const ServiceManageView(),
    "addToMenu": true,
    "addToContext": true,
    "icon": Icons.computer
  },
  "sticky": {
    "name": "Sticky",
    "view": (c) => const StickyNoteView(),
    "addToMenu": true,
    "addToContext": true,
    "icon": Icons.note
  },
  "blocks": {
    "name": "Blocks",
    "view": (c) => const BlocksView(),
    "addToMenu": true,
    "addToContext": true,
    "icon": Icons.bookmark
  }
};

class PocketHome extends StatefulWidget {
  const PocketHome({Key? key}) : super(key: key);

  @override
  _PocketHomeState createState() => _PocketHomeState();
}

class _PocketHomeState extends State<PocketHome> {
  int _index = Config.pageIndex;

  /// 决定显示的标题
  Widget _title(Config config) {
    switch (_index) {
      case 0:
        return DayInfo.titleWidget;
      case 1:
        return diary.title;
      case 2:
        return RichText(
            text: TextSpan(text: '短链接', style: Config.headerStyle, children: [
          TextSpan(
              text:
                  ' (最近 ${config.shortURLShowLimit} 天${config.filterDuplicate ? ' 去重' : ''})',
              style: Config.smallHeaderStyle)
        ]));
      case 3:
        return config.useReorderableListView
            ? const Text('拖动条目以排序', style: Config.headerStyle)
            : RichText(
                text: TextSpan(
                    text: '物品管理',
                    style: Config.headerStyle,
                    children: [
                    TextSpan(
                        text: ' ('
                            '${config.notShowRemoved ? '不' : ''}显示删除, '
                            '${config.notShowArchive ? '不' : ''}显示收纳)',
                        style: Config.smallHeaderStyle)
                  ]));
      default:
        return const Text('CM GO');
    }
  }

  /// 决定显示的页面
  _widgets(int index) {
    switch (index) {
      case 0:
        return DayInfo.mainWidget;
      case 1:
        return diary.mainWidget;
      case 2:
        return const QuickLinkPage();
      case 3:
        return const GoodsHome();
      default:
        return Container();
    }
  }

  /// 决定标题栏显示的菜单按钮
  List<Widget> _buildActions(Config config, int index) {
    if (index == 0) return DayInfo.menuActions(context, config);
    if (index == 1) return diary.menuActions(context, config);
    if (index == 2) {
      return [
        PopupMenuButton(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (e) {
              if (e is int) config.setShortUrlShowLimit(e);
              if (e is bool) config.setFilterDuplicate(!config.filterDuplicate);
            },
            itemBuilder: (c) {
              return [
                [0, '最近 5 天', 5],
                [0, '最近 10 天', 10],
                [0, '最近 20 天', 20],
                [0, '最近 30 天', 30],
                [1, '去除重复项', config.filterDuplicate]
              ].map((List e) {
                if (e[0] == 0) {
                  return PopupMenuItem(child: Text(e[1]), value: e[2]);
                } else {
                  return PopupMenuItem(
                      child: Text(e[2] ? '取消' + e[1] : e[1]), value: e[2]);
                }
              }).toList();
            })
      ];
    } else {
      return config.useReorderableListView
          ? [
              ElevatedButton(
                  onPressed: () {
                    final position = config.controller.offset;
                    config.position = position;
                    config.setUseReorderableListView(false);
                  },
                  child: const Row(children: [
                    Padding(
                      padding: EdgeInsets.only(right: 3),
                      child: Icon(Icons.done),
                    ),
                    Text('确定')
                  ]))
            ]
          : [
              PopupMenuButton<int>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (e) {
                    switch (e) {
                      case 0:
                        config.setGoodsShortByName(!config.goodsShortByName);
                        break;
                      case 1:
                        config.setGoodsRecentFirst(!config.goodsRecentFirst);
                        break;
                      case 2:
                        config.setNotShowClothes(!config.notShowClothes);
                        break;
                      case 3:
                        config.setNotShowRemoved(!config.notShowRemoved);
                        break;
                      case 4:
                        config.setNotShowArchive(!config.notShowArchive);
                        break;
                      case 5:
                        config.setShowUpdateButNotCreateTime(
                            !config.showUpdateButNotCreateTime);
                        break;
                      case 6:
                        config.setAutoCopyToClipboard(
                            !config.autoCopyToClipboard);
                        break;
                      case 7:
                        final position = config.controller.offset;
                        config.position = position;
                        config.setUseReorderableListView(
                            !config.useReorderableListView);
                        break;
                      default:
                        return;
                    }
                  },
                  itemBuilder: (c) {
                    return [
                      /*[0, '按照名称排序', config.goodsShortByName],
                [1, '按照最近排序', config.goodsRecentFirst],*/
                      [2, '显示衣物', !config.notShowClothes],
                      [3, '显示已删除', !config.notShowRemoved],
                      [4, '显示收纳', !config.notShowArchive],
                      [5, '显示更新而非创建日期', config.showUpdateButNotCreateTime],
                      [6, '将链接拷贝到剪贴板', config.autoCopyToClipboard],
                      [7, '排序模式（仅限同状态和重要度项目排序）', config.useReorderableListView]
                    ].map((List e) {
                      return PopupMenuItem(
                          child: Text(e[2] ? '✅ ' + e[1] : '❎ ' + e[1]),
                          value: e[0] as int);
                    }).toList();
                  })
            ];
    }
  }

  /// 主操作按钮
  _callActionButton(Config config, int index) {
    switch (index) {
      case 1:
        diary.mainAction(context, config);
        break;
      case 2:
        showSearch(context: context, delegate: ItemSearchDelegate());
        break;
      case 3:
        Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext c) {
          return const GoodAdd(null);
        }));
        break;
      default:
        return null;
    }
  }

  Widget _buildActionButtonWidget(int index) {
    switch (index) {
      case 0:
        return const Icon(Icons.search);
      case 1:
        return diary.mainButton;
      case 2:
        return const Icon(Icons.search);
      case 3:
        return const Icon(Icons.add);
      default:
        return const Icon(Icons.search);
    }
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isAndroid) {
      short.setupQuickAction(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: auth.userMenuDrawer(config, context),
        appBar: AppBar(
            elevation: 7,
            title: _title(config),
            leading: Builder(
                builder: (BuildContext context) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer())),
            centerTitle: true,
            toolbarHeight: Config.toolBarHeight,
            actions: _buildActions(config, _index)),
        floatingActionButton: _index == 0
            ? null
            : FloatingActionButton(
                onPressed: () => _callActionButton(config, _index),
                child: _buildActionButtonWidget(_index),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        backgroundColor: Colors.white,
        body: _widgets(_index),
        bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            items: [
              BottomNavigationBarItem(
                  label: DayInfo.title,
                  icon: const Icon(Icons.calendar_today_outlined),
                  activeIcon: const Icon(Icons.calendar_today)),
              BottomNavigationBarItem(
                  label: diary.buttonTitle,
                  icon: const Icon(Icons.sticky_note_2_outlined),
                  activeIcon: const Icon(Icons.sticky_note_2_rounded)),
              const BottomNavigationBarItem(
                  label: '短链接',
                  icon: Icon(Icons.bookmark_border_rounded),
                  activeIcon: Icon(Icons.bookmark)),
              const BottomNavigationBarItem(
                  label: '物品管理',
                  icon: Icon(Icons.checkroom_outlined),
                  activeIcon: Icon(Icons.checkroom))
            ]));
  }
}
