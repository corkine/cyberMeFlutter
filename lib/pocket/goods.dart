import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import '../util.dart';
import 'models/good.dart';
import 'config.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clipboard/clipboard.dart';

class GoodsHome extends StatefulWidget {
  const GoodsHome({Key? key}) : super(key: key);

  @override
  _GoodsHomeState createState() => _GoodsHomeState();
}

class _GoodsHomeState extends State<GoodsHome> {
  late Future<dynamic> _data;
  late http.Client _client;

  Future<List<Good>> fetchData(Config config) async {
    return _client.get(Uri.parse(config.goodsURL())).then((value) {
      var data = jsonDecode(const Utf8Codec().decode(value.bodyBytes));
      return (data as List).map((e) => Good.fromJSON(e)).toList();
    });
  }

  _retry(Config config) => setState(() {
        _data = fetchData(config);
      });

  @override
  void initState() {
    super.initState();
    _client = http.Client();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Config>(
      builder: (BuildContext context, Config config, Widget? w) {
        _data = fetchData(config);
        return FutureBuilder(
            future: _data,
            builder: (b, s) {
              if (s.connectionState != ConnectionState.done) {
                return Util.waiting;
              }
              if (s.hasError) {
                return InkWell(
                    radius: 20,
                    onTap: () => _retry(config),
                    child: const Center(child: Text('检索出错，点击重试')));
              }
              if (s.hasData) {
                final List<Good> data = s.data as List<Good>;
                data.sort((Good a, Good b) => Good.compare(config, a, b));
                return GoodList(config.notShowArchive
                    ? data
                        .where((element) => element.currentStateEn != 'Archive')
                        .toList()
                    : data);
              }
              return const Center(
                child: Text('没有数据'),
              );
            });
      },
    );
  }
}

class GoodList extends StatefulWidget {
  final List<Good> goods;

  const GoodList(this.goods, {Key? key}) : super(key: key);

  @override
  _GoodListState createState() => _GoodListState();
}

class _GoodListState extends State<GoodList> {
  @override
  Widget build(BuildContext context) {
    final goods = widget.goods;
    final config = Provider.of<Config>(context, listen: false);
    final map = config.map;
    Good good; //现在已经排过序了，根据排序结果将其顺序规整化
    //print('sorting now.');
    for (int i = 0; i < goods.length; i++) {
      good = goods[i];
      map[good.id] = (i + 1) * 300;
    }
    //从长按修改返回后，从编辑顺序返回后刷新并制定旧的滑动位置
    final _controller = ScrollController(initialScrollOffset: config.position);
    config.position = 0.0; //重置保存的位置，下次 longPress、进入列表编辑模式后 重新保存此值
    config.controller =
        _controller; //每次得到列表都刷新 Controller 对象，确保其是最后列表的 Controller
    return config.useReorderableListView
        ? ReorderableListView.builder(
            physics: const BouncingScrollPhysics(),
            itemExtent: 90,
            buildDefaultDragHandles: true,
            itemBuilder: (c, i) =>
                buildDismissible(i, context, _controller, config, goods),
            itemCount: goods.length,
            scrollController: _controller,
            onReorder: (int o, int n) {
              if (o < n) n -= 1;
              final Good old = goods.removeAt(o);
              //print('Old $old index is $o，new index is $n');
              goods.insert(n, old);
              if (n + 1 < goods.length) {
                int top = (n >= 1 ? map[goods[n - 1].id] : 0) as int;
                int bottom = map[goods[n + 1].id] as int;
                //print('top is$top, bottom is $bottom');
                final choose = Random().nextInt(bottom - top) + top; //可能等于顶部值
                //print('random is $choose');
                map[old.id] = choose;
              }
            })
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemExtent: 90,
            controller: _controller,
            itemCount: goods.length,
            itemBuilder: (c, i) =>
                buildDismissible(i, context, _controller, config, goods));
  }

  Dismissible buildDismissible(int i, BuildContext context,
      ScrollController _controller, Config config, List<Good> goods) {
    return Dismissible(
      key: Key(goods[i].id),
      background: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: const [
          Padding(
            padding: EdgeInsets.only(left: 20),
            child: Text('长按修改，点击查看'),
          )
        ],
      ),
      secondaryBackground: Container(
        color: Colors.red,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            Icon(
              Icons.delete,
              color: Colors.white,
            ),
            SizedBox(width: 30)
          ],
        ),
      ),
      confirmDismiss: (d) => _handleDismiss(d, goods[i], context),
      onDismissed: (DismissDirection d) {
        setState(() => goods.removeAt(i));
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 1, top: 1),
        child: Stack(children: [
          Opacity(
            opacity: 0.2,
            child: Container(
              color: goods[i].picture != null ? null : Colors.blueGrey,
              decoration: goods[i].picture != null
                  ? BoxDecoration(
                      image: DecorationImage(
                      image: NetworkImage(goods[i].picture!),
                      fit: BoxFit.fitWidth,
                      colorFilter: const ColorFilter.mode(
                          Colors.white12, BlendMode.color),
                      alignment: const Alignment(0, -0.5),
                    ))
                  : null,
              width: double.infinity,
              height: 100,
            ),
          ),
          config.useReorderableListView
              ? InkWell(child: buildContainer(goods, i, config))
              : InkWell(
                  onTap: () {
                    final config = Provider.of<Config>(context, listen: false);
                    launch(config.goodsView(goods[i]));
                    if (config.autoCopyToClipboard) {
                      FlutterClipboard.copy(config.goodsViewNoToken(goods[i]))
                          .then((value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('外部访问链接已拷贝到剪贴板')));
                      });
                    }
                  },
                  onLongPress: () {
                    final config = Provider.of<Config>(context, listen: false);
                    config.position = _controller.offset;
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (BuildContext context) {
                      return GoodAdd(goods[i]);
                    }));
                  },
                  child: buildContainer(goods, i, config),
                )
        ]),
      ),
    );
  }

  Container buildContainer(List<Good> goods, int i, Config config) {
    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      height: 100,
      child: ListTile(
        tileColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(top: 5, right: 9),
          child: CircleAvatar(
            backgroundColor: Colors.blueGrey.shade200,
            foregroundColor: Colors.white,
            child: Text(goods[i].name.substring(0, 1).toUpperCase()),
          ),
        ),
        horizontalTitleGap: 0,
        title: RichText(
            text: TextSpan(
                text: goods[i].name,
                style: const TextStyle(color: Colors.black, fontSize: 18),
                children: [
              TextSpan(
                  text: '  ' +
                      DateFormat('yy/M/d').format(
                          config.showUpdateButNotCreateTime
                              ? goods[i].updateTime
                              : goods[i].addTime),
                  style: const TextStyle(color: Colors.grey, fontSize: 12))
            ])),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white54),
              padding:
                  const EdgeInsets.only(left: 6, right: 6, top: 1, bottom: 1),
              child: Text(goods[i].importance! + ' | ' + goods[i].currentState),
            ),
            const SizedBox(
              width: 7,
            ),
            Expanded(
              child: Text(
                goods[i].description ?? '',
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
            )
          ],
        ),
        trailing: null,
      ),
    );
  }

  Future<bool> _handleDismiss(
      DismissDirection direction, Good good, BuildContext context) async {
    final config = Provider.of<Config>(context, listen: false);
    if (direction == DismissDirection.startToEnd) return false;
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (c) => AlertDialog(
              title: Text('确认删除 ${good.name} 吗？'),
              content: const Text('此操作不可取消'),
              actions: [
                ButtonBar(
                  children: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: const Text('取消')),
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        child: const Text(
                          '确认',
                          style: TextStyle(color: Colors.red),
                        ))
                  ],
                )
              ],
            )).then((value) {
      if (value) {
        http
            .get(Uri.parse(config.deleteGoodsURL(good.id)))
            .then((value) =>
                jsonDecode(const Utf8Codec().decode(value.bodyBytes)))
            .then((value) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('${value['message']}')));
          return true;
        });
        return true;
      } else {
        return false;
      }
    });
  }
}

class GoodAdd extends StatefulWidget {
  final Good? good;
  final bool fromActionCameraFirst;

  const GoodAdd(this.good, {Key? key, this.fromActionCameraFirst = false})
      : super(key: key);

  @override
  _GoodAddState createState() => _GoodAddState();
}

class _GoodAddState extends State<GoodAdd> {
  final formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late MultipartRequest request;
  File? _image;

  @override
  void initState() {
    super.initState();
    _resetRequest();
    if (widget.fromActionCameraFirst) _handleFetch();
  }

  @override
  Widget build(BuildContext context) {
    final good = widget.good;
    return Scaffold(
      appBar: AppBar(
        title: Text(good == null ? '添加物品' : '修改物品'),
        toolbarHeight: Config.toolBarHeight,
      ),
      body: _uploading
          ? Container(
              alignment: const Alignment(0, -0.2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                      height: 13,
                      width: 13,
                      child: CircularProgressIndicator(strokeWidth: 1.7)),
                  SizedBox(width: 10),
                  Text('正在联系服务器并交换数据...')
                ],
              ))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: buildForm(context),
              ),
            ),
    );
  }

  Form buildForm(BuildContext context) {
    final good = widget.good;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            initialValue: good == null ? '' : good.id.replaceFirst('CM', ''),
            autocorrect: false,
            decoration: const InputDecoration(
                labelText: '编号*',
                helperText: '编号必须以 CM 开头',
                prefixText: 'CM',
                helperStyle: Config.formHelperStyle),
            validator: (v) =>
                (v != null && v.isNotEmpty) ? null : '编号必须以 CM 开头，不可为空',
            onSaved: (d) =>
                request.fields[good == null ? 'goodId' : 'newGoodId'] =
                    'CM' + d!.toUpperCase(),
          ),
          const SizedBox(height: 7),
          TextFormField(
            initialValue: good == null ? '' : good.name,
            autocorrect: false,
            decoration: const InputDecoration(
                labelText: '名称*',
                helperText: '简短描述物品信息',
                helperStyle: Config.formHelperStyle),
            validator: (v) => (v != null && v.isNotEmpty) ? null : '名称不可为空',
            onSaved: (d) => request.fields['name'] = d!,
          ),
          const SizedBox(height: 7),
          TextFormField(
            initialValue: good == null ? '' : good.description ?? '',
            autocorrect: false,
            decoration: const InputDecoration(labelText: '描述'),
            onSaved: (d) => good != null
                ? good.description != null &&
                        d!.isEmpty //当进行更新时如果原来 description 不为空，现在为空
                    ? request.fields['description'] = '' //删除字段
                    : request.fields['description'] = d! //更新字段
                : d!.isNotEmpty //当进行新建时，如果不为空，则添加字段，反之不添加
                    ? request.fields['description'] = d
                    : null,
          ),
          const SizedBox(height: 17),
          DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: '状态*'),
              value: good == null ? 'Active' : good.currentStateEn ?? 'Active',
              onChanged: (e) {},
              hint: const Text('选择物品所处状态'),
              onSaved: (d) => d != null && d.isNotEmpty
                  ? request.fields['currentState'] = d
                  : null,
              items: const [
                DropdownMenuItem<String>(
                  child: Text('活跃'),
                  value: 'Active',
                ),
                DropdownMenuItem<String>(
                  child: Text('普通'),
                  value: 'Ordinary',
                ),
                DropdownMenuItem<String>(
                  child: Text('不活跃'),
                  value: 'NotActive',
                ),
                DropdownMenuItem<String>(
                  child: Text('归档'),
                  value: 'Archive',
                ),
                DropdownMenuItem<String>(
                  child: Text('移除'),
                  value: 'Remove',
                ),
                DropdownMenuItem<String>(
                  child: Text('外借'),
                  value: 'Borrow',
                ),
                DropdownMenuItem<String>(
                  child: Text('丢失'),
                  value: 'Lost',
                ),
              ]),
          const SizedBox(height: 7),
          DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: '级别*'),
              value: good == null ? 'A' : good.importance ?? 'A',
              onChanged: (e) {},
              onSaved: (d) => d != null && d.isNotEmpty
                  ? request.fields['importance'] = d
                  : null,
              hint: const Text('选择物品所处状态'),
              items: const [
                DropdownMenuItem<String>(
                  child: Text('非常重要 '),
                  value: 'A',
                ),
                DropdownMenuItem<String>(
                  child: Text('很重要'),
                  value: 'B',
                ),
                DropdownMenuItem<String>(
                  child: Text('比较重要'),
                  value: 'C',
                ),
                DropdownMenuItem<String>(
                  child: Text('有些重要'),
                  value: 'D',
                ),
                DropdownMenuItem<String>(
                  child: Text('不重要'),
                  value: 'N',
                )
              ]),
          const SizedBox(height: 7),
          TextFormField(
              initialValue: good == null ? '' : good.place ?? '',
              autocorrect: false,
              decoration: const InputDecoration(
                  labelText: '位置',
                  helperText: '物品一般放置位置',
                  helperStyle: Config.formHelperStyle),
              onSaved: (d) => good != null
                  ? good.place != null &&
                          d != null &&
                          d.isEmpty //当进行更新时如果原来 place 不为空，现在为空
                      ? request.fields['place'] = '' //删除字段
                      : request.fields['place'] = d! //更新字段
                  : d != null && d.isNotEmpty //当进行新建时，如果不为空，则添加字段，反之不添加
                      ? request.fields['place'] = d
                      : null),
          const SizedBox(height: 7),
          TextFormField(
              initialValue: good == null ? '' : good.message ?? '',
              autocorrect: false,
              decoration: const InputDecoration(
                  labelText: '消息',
                  helperText: '他人扫码可见内容',
                  helperStyle: Config.formHelperStyle),
              onSaved: (d) => good != null
                  ? good.message != null &&
                          d != null &&
                          d.isEmpty //当进行更新时如果原来消息不为空，现在为空
                      ? request.fields['message'] = '' //删除字段
                      : request.fields['message'] = d! //更新字段
                  : d != null && d.isNotEmpty //当进行新建时，如果不为空，则添加字段，反之不添加
                      ? request.fields['message'] = d
                      : null
              //（服务端实现有问题，当不提供字段时，默认使用原始值，当提供字段时，使用新字段，不能设置为 null）
              ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                  padding: const EdgeInsets.only(
                      left: 0, right: 10, top: 10, bottom: 0),
                  child: TextButton(
                    onPressed: _handleFetch,
                    child: Row(
                      children: [
                        Icon(good == null
                            ? _image == null
                                ? Icons.photo_camera
                                : Icons.remove_circle_outline
                            : Icons.photo_camera),
                        const SizedBox(width: 6),
                        Text(good == null
                            ? _image == null
                                ? '拍摄物品照片'
                                : '删除所选照片'
                            : good.picture == null
                                ? '补充添加照片'
                                : '更新所选照片')
                      ],
                    ),
                  )),
              //新键（good == null,_image == null）时直接返回空，新键拍照后（good == null,_image != null）展示预览，
              //更新（good != null,_image == null）时没有图片(good != null,_image == null,good.picture == null)返回空，
              //有图片(good != null,_image == null,good.picture != null)返回图片，更新拍照(good != null,_image == null,
              //_image != null)后展示预览。
              _image != null
                  ? Image.file(_image!, width: 100)
                  : good != null && good.picture != null
                      ? Image.network(good.picture!, width: 100)
                      : const SizedBox(
                          height: 1,
                          width: 1,
                        )
            ],
          ),
          ButtonBar(
            children: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('返回/取消')),
              ElevatedButton(
                  onPressed: _savingData,
                  child: Text(good == null ? '创建' : '更新')),
            ],
          )
        ],
      ),
    );
  }

  _resetRequest() {
    final config = Provider.of<Config>(context, listen: false);
    request = http.MultipartRequest(
        'POST',
        Uri.parse(widget.good == null
            ? config.goodsAddURL
            : config.goodsUpdateURL(widget.good!.id)));
    request.fields.clear();
  }

  _handleFetch() async {
    if (_image == null) {
      //_image 为空则拍照更新，反之则将其置为空，新键或更新对其无影响
      final pickedFile = await _picker.getImage(source: ImageSource.camera);
      File? image;
      if (pickedFile != null) {
        print(pickedFile.path);
        image = await compressAndGetFile(
            File(pickedFile.path),
            pickedFile.path
                .replaceFirst('image_picker', 'compressed_image_picker'));
        setState(() {
          _image = image;
        });
      }
    } else {
      setState(() {
        _image = null;
      });
    }
  }

  Future<File?> compressAndGetFile(File file, String targetPath) async {
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      minHeight: 640,
      minWidth: 480,
      quality: 100,
    );
    print(
        'File length ${file.lengthSync()}, Compressed to ${result?.lengthSync()}');
    return result;
  }

  bool _uploading = false;

  _savingData() async {
    var failed = true;
    if (formKey.currentState!.validate()) {
      setState(() {
        _uploading = true;
      });
      try {
        formKey.currentState!.save();
        print(request.fields);
        if (_image != null) {
          //新建，有新图片 或者 修改，更新图片。
          //当新建时没有添加图片，或者修改图片未更改（_image 始终为空），则不做处理。
          final file =
              await http.MultipartFile.fromPath('picture', _image!.path);
          request.files.add(file);
        }
        //request.headers[HttpHeaders.authorizationHeader] = Config.base64Token;
        final response = await request.send();
        final data = await response.stream.toBytes();
        print(utf8.decode(data));
        Map<String, dynamic> result = jsonDecode(utf8.decode(data));
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result['message'])));
        Navigator.of(context).pop();
        final model = Provider.of<Config>(context, listen: false);
        model.justNotify();
        failed = false;
        return result;
      } finally {
        _resetRequest();
        setState(() {
          _uploading = false;
        });
        if (failed) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('上传失败')));
        }
      }
    }
  }
}
