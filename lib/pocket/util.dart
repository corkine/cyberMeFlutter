import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'config.dart';

const Map<String, dynamic> emptyMap = {};

const animalBgs = [
  "https://static2.mazhangjing.com/cyber/202408/061ec0f1_Snipaste_2024-08-02_14-04-41.jpg",
  "https://static2.mazhangjing.com/cyber/202408/9d058a62_Snipaste_2024-08-02_14-04-48.jpg",
  "https://static2.mazhangjing.com/cyber/202408/59cbf66d_Snipaste_2024-08-02_14-04-57.jpg",
  "https://static2.mazhangjing.com/cyber/202408/1eba9b4c_Snipaste_2024-08-02_14-05-10.jpg",
  "https://static2.mazhangjing.com/cyber/202408/ae3dea88_Snipaste_2024-08-02_14-05-23.jpg",
  "https://static2.mazhangjing.com/cyber/202408/da4ce823_Snipaste_2024-08-02_14-05-36.jpg",
  "https://static2.mazhangjing.com/cyber/202408/ae8cc35f_Snipaste_2024-08-06_13-36-42.jpg",
  "https://static2.mazhangjing.com/cyber/202408/db804a00_Snipaste_2024-08-06_13-36-56.jpg",
  "https://static2.mazhangjing.com/cyber/202408/d9c647d9_Snipaste_2024-08-06_13-37-12.jpg",
  "https://static2.mazhangjing.com/cyber/202408/18c4fc85_Snipaste_2024-08-06_13-37-23.jpg",
  "https://static2.mazhangjing.com/cyber/202408/f681ae63_Snipaste_2024-08-06_13-37-55.jpg",
  "https://static2.mazhangjing.com/cyber/202408/0b0d5f50_Snipaste_2024-08-06_13-38-09.jpg",
  "https://static2.mazhangjing.com/cyber/202408/da8ea1d8_Snipaste_2024-08-06_14-30-10.jpg",
  "https://static2.mazhangjing.com/cyber/202408/2d92cd79_Snipaste_2024-08-06_14-30-28.jpg",
  "https://static2.mazhangjing.com/cyber/202408/b9f56712_Snipaste_2024-08-06_14-30-38.jpg"
];

const coverBgs = [
  "https://static2.mazhangjing.com/cyber/202409/6714aa1d_Snipaste_2024-09-05_10-18-39.jpg",
  "https://static2.mazhangjing.com/cyber/202409/84de40f3_Snipaste_2024-09-05_10-19-25.jpg",
  "https://static2.mazhangjing.com/cyber/202409/623f0074_Snipaste_2024-09-05_10-19-52.jpg",
  "https://static2.mazhangjing.com/cyber/202409/dffd38dd_Snipaste_2024-09-05_10-20-13.jpg",
  "https://static2.mazhangjing.com/cyber/202409/948ab18f_Snipaste_2024-09-05_10-20-32.jpg",
  "https://static2.mazhangjing.com/cyber/202409/3815bfb5_Snipaste_2024-09-05_10-21-06.jpg",
  "https://static2.mazhangjing.com/cyber/202409/c6561a75_Snipaste_2024-09-05_10-21-19.jpg",
  "https://static2.mazhangjing.com/cyber/202409/300d3fa2_Snipaste_2024-09-05_10-21-34.jpg",
  "https://static2.mazhangjing.com/cyber/202409/2c64448b_Snipaste_2024-09-05_10-22-30.jpg",
  "https://static2.mazhangjing.com/cyber/202409/8ce1da26_Snipaste_2024-09-05_10-22-57.jpg",
  "https://static2.mazhangjing.com/cyber/202409/c61f08d0_Snipaste_2024-09-05_10-23-26.jpg"
];

const Map<String, String> storyCover = {
  "格林童话": "https://static2.mazhangjing.com/cyber/202310/753d1738_图片.png",
  "伊索寓言": "https://static2.mazhangjing.com/cyber/202310/51472203_图片.png",
  "一千零一夜": "https://static2.mazhangjing.com/cyber/202310/4ab8d597_图片.png",
  "黑塞童话": "https://static2.mazhangjing.com/cyber/202310/f31ac1f5_图片.png",
  "王尔德童话": "https://static2.mazhangjing.com/cyber/202310/627f2f86_图片.png",
  "笨狼的故事": "https://static2.mazhangjing.com/cyber/202310/efde917f_图片.png",
  "安徒生童话": "https://static2.mazhangjing.com/cyber/202310/efbd86c8_图片.png",
  "佩罗童话": "https://static2.mazhangjing.com/cyber/202405/6c3de10b_image.png",
  "恰佩克童话": "https://static2.mazhangjing.com/cyber/202405/1ab939ee_image.png",
  "罗尔德童话": "https://static2.mazhangjing.com/cyber/202405/b081a67c_image.png",
  "欧亨利短篇小说选": "https://static2.mazhangjing.com/cyber/202405/cf9d091c_image.png",
  "阿瑟克拉克科幻小说选": "https://static2.mazhangjing.com/cyber/202310/d4461685_图片.png",
  "银河系边缘的小失常": "https://static2.mazhangjing.com/cyber/202310/dc840e21_图片.png",
  "伟大的短篇小说们": "https://static2.mazhangjing.com/cyber/202310/d6c77430_图片.png",
  "日本民间童话故事": "https://static2.mazhangjing.com/cyber/202405/f8ef4c95_image.png"
};

String defaultStoryCover =
    "https://static2.mazhangjing.com/cyber/202310/70b6426c_图片.png";

int weekOfYear(DateTime date) {
  // 获取该日期的第一天
  DateTime firstDayOfYear = DateTime(date.year, 1, 1);
  // 计算该日期是第几天
  int dayOfYear = date.difference(firstDayOfYear).inDays + 1;
  // 计算星期几
  int dayOfWeek = date.weekday;
  // 计算第几周
  int weekOfYear = ((dayOfYear - dayOfWeek + 10) / 7).floor();
  return weekOfYear;
}

/// 执行 Redis Lua 脚本，see taoensso.carmine/lua:
///
/// (lua "redis.call('set', _:my-key, _:my-arg)" {:my-key "foo"} {:my-arg "bar"})
///
/// eg. evalRedis(config, "return redis.call('LRANGE', _:my-key, _:from, _:to)", keys: {"my-key": "recent-oss-files"}, args: {"from": 0, "to": -1})
Future<(bool, dynamic)> evalRedis(Config config, String script,
    {Map<String, dynamic> keys = emptyMap,
    Map<String, dynamic> args = emptyMap}) async {
  final data = jsonEncode({"script": script, "keys": keys, "args": args});
  final r = await http.post(Uri.parse(Config.redisUrl),
      headers: config.cyberBase64JsonContentHeader, body: data);
  final d = jsonDecode(r.body);
  final s = (d["status"] as int?) ?? -1;
  return (s > 0, d["data"]);
}

Widget Function(BuildContext, AsyncSnapshot<Object?>) commonFutureBuilder<T>(
        Widget Function(T) buildMainPage) =>
    (BuildContext context, AsyncSnapshot<Object?> future) {
      if (future.hasData && future.data != null) {
        return buildMainPage(future.data as T);
      }
      if (future.hasError) {
        return SizedBox(
          width: double.infinity,
          height: MediaQuery.of(context).size.height - 100,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset("images/empty.png", width: 200),
                Text("发生了一些错误：${future.error}", textAlign: TextAlign.center)
              ]),
        );
      }
      return Container(
          alignment: Alignment.center,
          child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                Padding(padding: EdgeInsets.all(20), child: Text("正在联系服务器"))
              ]));
    };

/// 选取照片，支持单纯从相机或相册选择，支持通过菜单判断，支持压缩和清除 EXIF
/// 调用期间，BuildContext 不可更改
Future<File?> pickImage(
  BuildContext context, {
  bool justCamera = false,
  bool justGallery = false,
  bool withCompress = true,
  int minWidth = 640,
  int minHeight = 480,
  int quality = 95,
  CompressFormat format = CompressFormat.jpeg,
  bool keepExif = false,
}) async {
  final picker = ImagePicker();
  File? image;
  Future<void> pick(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      if (kDebugMode) print(pickedFile.path);
      var file = File(pickedFile.path);
      if (withCompress) {
        var targetPath = pickedFile.path
            .replaceFirst('image_picker', 'compressed_image_picker');
        image = await FlutterImageCompress.compressAndGetFile(
            file.absolute.path, targetPath,
            minHeight: minHeight,
            minWidth: minWidth,
            quality: quality,
            format: format,
            keepExif: keepExif);
        if (kDebugMode) {
          print('File length ${file.lengthSync()}, '
              'Compressed to ${image?.lengthSync()}');
        }
      } else {
        image = file;
      }
    }
  }

  if (!justCamera & !justGallery) {
    await showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
            title: null,
            message: null,
            actions: [
              CupertinoActionSheetAction(
                  onPressed: () async {
                    await pick(ImageSource.camera);
                    Navigator.of(context).pop(null);
                  },
                  child: const Text("用相机拍摄")),
              CupertinoActionSheetAction(
                  onPressed: () async {
                    await pick(ImageSource.gallery);
                    Navigator.of(context).pop(null);
                  },
                  child: const Text("从相册选择"))
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: const Text("取消"),
            )));
  } else if (justCamera) {
    await pick(ImageSource.camera);
  } else if (justGallery) {
    await pick(ImageSource.gallery);
  }
  if (kDebugMode) print("Image is: $image");
  return image;
}

/// 上传照片到 OSS，返回 Pair<Url,Exception>
Future<List<String?>> uploadImage(File file, Config config,
    {String type = "application/octet-stream"}) async {
  /*var resp = await http.post(Uri.parse(Config.ossUrl),
      headers: config.base64Header, body: {"file": file.readAsBytesSync()});*/
  String? url;
  String? message;
  try {
    var req = http.MultipartRequest("POST", Uri.parse(Config.ossUrl));
    req.headers.addAll(config.cyberBase64Header);
    var filename = file.path.split("/").last;
    var suffix = filename.split(".").last;
    filename =
        filename.substring(0, filename.length > 15 ? 15 : filename.length) +
            "." +
            suffix;
    req.files.add(http.MultipartFile.fromBytes("file", file.readAsBytesSync(),
        filename: filename, contentType: MediaType.parse(type)));
    var resp = await req.send();
    var body = await resp.stream.bytesToString();
    var data = jsonDecode(body);
    message = data["message"];
    url = data["data"];
  } on Exception catch (e) {
    message = e.toString();
  }
  return [url, message];
}
