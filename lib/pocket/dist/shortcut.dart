import 'package:clipboard/clipboard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';
import '../config.dart';
import '../day.dart';
import 'goods.dart';
import 'link.dart';
import '../models/day.dart';
import '../util.dart' as util;

const registerItems = <ShortcutItem>[
  ShortcutItem(type: 'action_hcm', localizedTitle: '检查打卡情况'),
  ShortcutItem(type: 'action_clean', localizedTitle: '标记一次清洁'),
  ShortcutItem(type: 'action_upload', localizedTitle: '上传图片'),
  ShortcutItem(type: 'action_quicklink', localizedTitle: '查找短链'),
  // const ShortcutItem(
  //     type: 'action_add_quicklink_short', localizedTitle: '添加短链接'),
  // const ShortcutItem(
  //     type: 'action_add_quicklink_long', localizedTitle: '从剪贴板添加短链接'),
  ShortcutItem(type: 'action_add_good', localizedTitle: '物品入库'),
];

void setupQuickAction(BuildContext context) {
  try {
    var quickActions = const QuickActions();
    quickActions.initialize((shortcutType) {
      switch (shortcutType) {
        case "action_quicklink":
          Config config = Provider.of<Config>(context, listen: false);
          showSearch(context: context, delegate: ItemSearchDelegate(config));
          break;
        case 'action_add_good':
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (BuildContext c) {
            return const GoodAdd(null, fromActionCameraFirst: true);
          }));
          break;
        case 'action_add_quicklink_long':
          FlutterClipboard.paste().then((query) => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (BuildContext c) {
                return AddDialog(query, isShortWord: false);
              })));
          break;
        case 'action_add_quicklink_short':
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (BuildContext c) {
            return const AddDialog('', isShortWord: true);
          }));
          break;
        case 'action_clean':
          var config = Provider.of<Config>(context, listen: false);
          config.justInit().then(
              (_) => DayInfo.callAndShow(Dashboard.setClean, context, config));
          break;
        case 'action_hcm':
          var config = Provider.of<Config>(context, listen: false);
          config.justInit().then((_) =>
              DayInfo.callAndShow(Dashboard.checkHCMCard, context, config));
          break;
        case 'action_upload':
          var config = Provider.of<Config>(context, listen: false);
          Future.delayed(const Duration(milliseconds: 700), () {
            config.justInit().then((value) async {
              String? url;
              var image = await util.pickImage(context);
              if (image != null) {
                if (kDebugMode) print("uploading image $image");
                var uploadRes = await util.uploadImage(image, config);
                if (uploadRes[0] == null) {
                  if (kDebugMode) print("upload failed! ${uploadRes[1]}");
                } else {
                  url = uploadRes[0];
                  await FlutterClipboard.copy(url!);
                  var message = await Dashboard.uploadOneNote(config, url);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("上传笔记返回数据：$message"),
                  ));
                }
              }
              if (kDebugMode) print(url);
            });
          });
      }
    });
    quickActions.setShortcutItems(registerItems);
  } on Exception {
    if (kDebugMode) {
      print("Init ShortCut failed, may platform not support it.");
    }
  }
}
