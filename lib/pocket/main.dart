import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:hello_flutter/learn/snh.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../learn/data.dart';
import '../learn/game.dart';
import 'goods.dart';
import 'link.dart';
import 'config.dart';

class CMPocket {
  static void run() {
    runApp(ChangeNotifierProvider(
      create: (c) => Config(),
      child: const MaterialApp(
        title: 'CMPocket',
        debugShowCheckedModeBanner: true,
        home: PocketHome(),
      ),
    ));
  }
}

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
        return RichText(
            text: TextSpan(text: '短链接', style: Config.headerStyle, children: [
          TextSpan(
              text:
                  ' (最近 ${config.shortURLShowLimit} 天${config.filterDuplicate ? ' 去重' : ''})',
              style: Config.smallHeaderStyle)
        ]));
      case 1:
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
      case 2:
        return const Text('健康管理');
      default:
        return const Text('CMGO');
    }
  }

  /// 决定显示的页面
  _widgets(int index) {
    switch (index) {
      case 0:
        return const QuickLinkPage();
      case 1:
        return const GoodsHome();
      default:
        return Container();
    }
  }

  /// 决定标题栏显示的菜单按钮
  List<Widget> _buildActions(Config config, int index) {
    if (index == 0) {
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
                child: Row(
                  children: const [
                    Padding(
                      padding: EdgeInsets.only(right: 3),
                      child: Icon(Icons.done),
                    ),
                    Text('确定')
                  ],
                ),
              )
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
      case 0:
        showSearch(context: context, delegate: ItemSearchDelegate(config));
        break;
      case 1:
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
        return const Icon(Icons.add);
      default:
        return const Icon(Icons.search);
    }
  }

  /// 处理 App 的认证和登录信息
  _handleLogin(Config config) {
    if (config.user.isNotEmpty) {
      config.user = '';
      config.password = '';
      config.justNotify();
    } else {
      showDialog<List<String>>(
          context: context,
          builder: (BuildContext c) {
            final userController = TextEditingController();
            final passwordController = TextEditingController();
            return SimpleDialog(
              title: const Text('输入用户名和登录凭证'),
              contentPadding: const EdgeInsets.all(19),
              children: [
                TextField(
                    controller: userController,
                    decoration: const InputDecoration(labelText: '用户名')),
                TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: '密码'),
                    obscureText: true),
                ButtonBar(
                  children: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(null);
                        },
                        child: const Text('取消')),
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(
                              [userController.text, passwordController.text]);
                        },
                        child: const Text('确定')),
                  ],
                )
              ],
            );
          }).then((List<String>? value) {
        if (value != null) {
          config.user = value[0];
          config.password = value[1];
          config.justNotify();
          _savingData(config.user, config.password);
        }
      });
    }
  }

  _savingData(String user, String pass) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('user', user);
    prefs.setString('password', pass);
  }

  final QuickActions quickActions = const QuickActions();

  _doAddLong() async {
    var query = await FlutterClipboard.paste();
    Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext c) {
      return AddDialog(query, isShortWord: false);
    }));
  }

  _doAddShort() async {
    Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext c) {
      return const AddDialog('', isShortWord: true);
    }));
  }

  /// iOS 右键菜单注册
  @override
  void initState() {
    super.initState();
    quickActions.initialize((shortcutType) {
      if (shortcutType == 'action_quicklink') {
        /*setState(() {
          _index = 0;
        });*/
        Config config = Provider.of<Config>(context, listen: false);
        showSearch(context: context, delegate: ItemSearchDelegate(config));
      } else if (shortcutType == 'action_add_good') {
        Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext c) {
          return const GoodAdd(null, fromActionCameraFirst: true);
        }));
      } else if (shortcutType == 'action_add_quicklink_long') {
        _doAddLong();
      } else if (shortcutType == 'action_add_quicklink_short') {
        _doAddShort();
      }
    });
    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(type: 'action_quicklink', localizedTitle: '查找短链接'),
      const ShortcutItem(
          type: 'action_add_quicklink_short', localizedTitle: '添加短链接'),
      const ShortcutItem(
          type: 'action_add_quicklink_long', localizedTitle: '从剪贴板添加短链接'),
      const ShortcutItem(type: 'action_add_good', localizedTitle: '新物品入库')
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Config>(
      builder: (BuildContext context, Config config, Widget? w) {
        return Scaffold(
            drawer: Drawer(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const UserAccountsDrawerHeader(
                        decoration: BoxDecoration(
                            image: DecorationImage(
                                fit: BoxFit.fitWidth,
                                alignment: Alignment.centerLeft,
                                image: AssetImage('images/girl.jpg'))),
                        accountName: Text('Corkine Ma'),
                        accountEmail: Text('corkine@outlook.com'),
                        currentAccountPicture: FractionalTranslation(
                            translation: Offset(-0.1, 0.1),
                            child: Icon(
                              Icons.face_unlock_sharp,
                              size: 70,
                              color: Colors.white,
                            )),
                      ),
                      ListTile(
                        leading: const Icon(Icons.home),
                        title: const Text('主页'),
                        onTap: () {
                          launch('https://mazhangjing.com');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.all_inclusive_sharp),
                        title: const Text('博客'),
                        onTap: () {},
                      ),
                      ListTile(
                        leading: const Icon(Icons.videogame_asset),
                        title: const Text('游戏'),
                        onTap: () {
                          Info.readData().then((value) => {
                                Navigator.of(context)
                                    .push(MaterialPageRoute(builder: (c) {
                                  return Game(info: value);
                                }))
                              });
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.store),
                        title: const Text('SNH48'),
                        onTap: () {
                          Navigator.of(context)
                              .push(MaterialPageRoute(builder: (c) {
                            return const SNHApp();
                          }));
                        },
                      )
                    ],
                  ),
                  Column(
                    children: [
                      SizedBox(
                          width: 200,
                          child: ElevatedButton(
                              style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(
                                      Colors.green.shade300)),
                              onPressed: () => _handleLogin(config),
                              child:
                                  Text(config.user.isEmpty ? '验证秘钥' : '取消登录'))),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 15),
                        child: Text(
                          Config.version,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            appBar: AppBar(
                elevation: 7,
                title: _title(config),
                leading: Builder(
                  builder: (BuildContext context) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ),
                centerTitle: true,
                toolbarHeight: Config.toolBarHeight,
                actions: _buildActions(config, _index)),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _callActionButton(config, _index),
              child: _buildActionButtonWidget(_index),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            body: _widgets(_index),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
              items: const [
                BottomNavigationBarItem(
                    label: '短链接',
                    icon: Icon(Icons.bookmark_border_rounded),
                    activeIcon: Icon(Icons.bookmark)),
                BottomNavigationBarItem(
                    label: '物品管理',
                    icon: Icon(Icons.checkroom_outlined),
                    activeIcon: Icon(Icons.checkroom))
              ],
            ));
      },
    );
  }
}
