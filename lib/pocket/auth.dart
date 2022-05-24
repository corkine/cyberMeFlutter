import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../health/data.dart';
import '../learn/game.dart';
import '../learn/snh.dart';
import 'config.dart';

/// 用户信息 Drawer Widget
Widget userMenuDrawer(Config config, BuildContext context) => Drawer(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
          Column(mainAxisAlignment: MainAxisAlignment.start, children: [
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
                    ))),
            ListTile(
                leading: const Icon(Icons.home),
                title: const Text('主页'),
                onTap: () => launch('https://mazhangjing.com')),
            ListTile(
                leading: const Icon(Icons.all_inclusive_sharp),
                title: const Text('博客'),
                onTap: () {}),
            ListTile(
                leading: const Icon(Icons.videogame_asset),
                title: const Text('游戏'),
                onTap: () => Info.readData().then((value) => {
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (c) {
                        return Game(info: value);
                      }))
                    })),
            ListTile(
                leading: const Icon(Icons.store),
                title: const Text('SNH48'),
                onTap: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (c) {
                      return const SNHApp();
                    })))
          ]),
          Column(children: [
            SizedBox(
                width: 200,
                child: ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.green.shade300)),
                    onPressed: () => handleLogin(config, context),
                    child: Text(config.user.isEmpty ? '验证秘钥' : '取消登录'))),
            const Padding(
                padding: EdgeInsets.only(bottom: 15),
                child: Text(
                  Config.version,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ))
          ])
        ]));

/// 处理登录逻辑
void handleLogin(Config config, BuildContext context) {
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
        savingData(config.user, config.password);
      }
    });
  }
}

/// 保存登录信息到本地存储
void savingData(String user, String pass) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('user', user);
  prefs.setString('password', pass);
}
