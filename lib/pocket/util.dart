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
        filename.substring(0, filename.length > 15 ? 15 : filename.length) + "." + suffix;
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
