import 'dart:convert';

import 'package:clipboard/clipboard.dart';
import 'package:cyberme_flutter/api/express.dart';
import 'package:cyberme_flutter/main.dart';
import 'package:cyberme_flutter/pocket/app/util.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart';

import '../config.dart';

class ExpressView extends ConsumerStatefulWidget {
  const ExpressView({super.key});

  @override
  ConsumerState<ExpressView> createState() => _ExpressViewState();
}

class _ExpressViewState extends ConsumerState<ExpressView> {
  Set<String> expandedItems = {};
  @override
  Widget build(BuildContext context) {
    final express = ref.watch(expressesProvider).value;
    return Theme(
        data: appThemeData,
        child: Scaffold(
            appBar: AppBar(title: const Text("Express!Me"), centerTitle: true),
            body: Column(children: [
              Expanded(
                  child: express?.isEmpty ?? false
                      ? const Center(child: Text("暂无快递信息"))
                      : RefreshIndicator(
                          onRefresh: () async =>
                              await ref.refresh(expressesProvider.future),
                          child: ListView(
                              children: (express ?? [])
                                  .map((e) => buildExpressTile(e, context))
                                  .toList(growable: false)))),
              SafeArea(
                  child:
                      ButtonBar(alignment: MainAxisAlignment.center, children: [
                TextButton(
                    onPressed: () async {
                      final res = await ref
                          .read(expressesProvider.notifier)
                          .forceUpdate();
                      await showSimpleMessage(context, content: res);
                    },
                    child: const Text("同步")),
                TextButton(
                    onPressed: () => showModalBottomSheet(
                        context: context,
                        builder: (c) => BottomSheet(
                            onClosing: () {},
                            builder: (c) => const ExpressAddView())),
                    child: const Text("添加快递"))
              ]))
            ])));
  }

  ListTile buildExpressTile(ExpressItem e, BuildContext context) {
    final itemCount = e.extra.length;
    return ListTile(
        splashColor: Colors.transparent,
        onTap: () => setState(() {
              if (expandedItems.contains(e.id)) {
                expandedItems.remove(e.id);
              } else {
                expandedItems.add(e.id);
              }
            }),
        onLongPress: () => showContextMenu(context, e),
        title: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(e.id, style: const TextStyle(fontSize: 13))
            ])),
        subtitle: Stack(children: [
          Positioned(
              top: 5,
              left: 8.5,
              bottom: 4,
              child: Container(
                  width: 1, height: 50, color: Colors.grey.withOpacity(0.3))),
          Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: buildExpressDetailsList(e, itemCount))
        ]));
  }

  List<Widget> buildExpressDetailsList(ExpressItem e, int itemCount) {
    return e.extra.indexed
        .take(expandedItems.contains(e.id) ? e.extra.length : 1)
        .map((e) => Padding(
            padding: const EdgeInsets.only(left: 25),
            child: DefaultTextStyle(
                style: TextStyle(
                    fontSize: 12,
                    color: e.$1 == 0
                        ? Colors.green
                        : const Color.fromARGB(255, 88, 88, 88),
                    fontWeight:
                        e.$1 == 0 ? FontWeight.bold : FontWeight.normal),
                child: TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 300),
                    tween: Tween(begin: (itemCount - e.$1) * 0.001, end: 1.0),
                    builder: (context, value, child) {
                      return Opacity(opacity: value, child: child);
                    },
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            CustomPaint(
                                painter: StatusCircle(isLast: e.$1 == 0)),
                            Text(e.$2.timeReadable,
                                softWrap: true,
                                style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                    fontFamily: "consolas"))
                          ]),
                          const SizedBox(height: 5),
                          Text(e.$2.status, softWrap: true),
                          const SizedBox(height: 5)
                        ])))))
        .toList(growable: false);
  }

  Future<dynamic> showContextMenu(BuildContext context, ExpressItem e) {
    return showDialog(
        context: context,
        builder: (context) => Theme(
            data: appThemeData,
            child: SimpleDialog(
                title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(e.id,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.white54))
                    ]),
                children: [
                  SimpleDialogOption(
                      onPressed: () async {
                        await FlutterClipboard.copy(e.id);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text("已拷贝快递单号到剪贴板。"),
                            action:
                                SnackBarAction(label: "OK", onPressed: () {}),
                            duration: const Duration(milliseconds: 400)));
                        Navigator.of(context).pop();
                      },
                      child: const Text("复制单号")),
                  SimpleDialogOption(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await handleDeleteExpress(e.id);
                        ref.invalidate(expressesProvider);
                      },
                      child: const Text("删除"))
                ])));
  }

  handleDeleteExpress(String no) async {
    final r = await get(Uri.parse(Config.deleteExpress(no)),
        headers: config.cyberBase64Header);
    final d = jsonDecode(r.body);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(d["message"])));
  }
}

class ExpressAddView extends ConsumerStatefulWidget {
  const ExpressAddView({super.key});

  @override
  ConsumerState<ExpressAddView> createState() => _ExpressAddViewState();
}

class _ExpressAddViewState extends ConsumerState<ExpressAddView> {
  final formKey = GlobalKey<FormState>();
  var rewrite = false;
  var wait = true;
  var id = TextEditingController();
  var focusNode = FocusNode();
  var note = '';
  var sfPhone = '';

  @override
  void initState() {
    super.initState();
    FlutterClipboard.paste().then((value) {
      if (value.isNotEmpty) {
        id.text = value;
        focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
        data: appThemeData,
        child: Scaffold(
            //appBar: AppBar(title: const Text("添加快递"), centerTitle: true),
            body: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Form(
                    key: formKey,
                    child: Column(children: [
                      TextFormField(
                          decoration: const InputDecoration(labelText: "快递单号*"),
                          validator: (v) => v!.isNotEmpty ? null : "需要提供单号",
                          controller: id),
                      TextFormField(
                          focusNode: focusNode,
                          decoration: const InputDecoration(labelText: "快递备注*"),
                          validator: (v) => v!.isNotEmpty ? null : "需要提供快递备注",
                          onChanged: (e) => note = e),
                      TextFormField(
                          decoration: const InputDecoration(
                              labelText: "收货人手机后四位", helperText: "顺丰快递需要填写"),
                          onChanged: (e) => sfPhone = e),
                      const SizedBox(height: 10),
                      Transform.translate(
                          offset: const Offset(-10, 0),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Checkbox(
                                    value: rewrite,
                                    onChanged: (n) =>
                                        setState(() => rewrite = n!)),
                                const Text("如果存在，则覆盖")
                              ])),
                      Transform.translate(
                          offset: const Offset(-10, -10),
                          child: Row(children: [
                            Checkbox(
                                value: wait,
                                onChanged: (n) => setState(() => wait = n!)),
                            const Text("如果不存在，则加入等待列表")
                          ])),
                      ButtonBar(children: [
                        TextButton(
                            onPressed: () {
                              formKey.currentState?.reset();
                              id.clear();
                            },
                            child: const Text("清空")),
                        TextButton(
                            onPressed: () async {
                              final d = await FlutterClipboard.paste();
                              if (d.isNotEmpty) {
                                setState(() => id.text = d);
                              }
                            },
                            child: const Text("从剪贴板粘贴单号")),
                        TextButton(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                handleAdd(
                                    sfPhone.isNotEmpty
                                        ? "${id.text}:$sfPhone"
                                        : id.text,
                                    note,
                                    rewrite,
                                    wait);
                              }
                            },
                            child: const Text("提交"))
                      ])
                    ])))));
  }

  handleAdd(String no, String note, bool rewrite, bool wait) async {
    final r = await get(
        Uri.parse(Config.expressAddUrl(note, rewrite, wait, no)),
        headers: config.cyberBase64Header);
    final d = jsonDecode(r.body);
    ref.invalidate(expressesProvider);
    await showSimpleMessage(context, content: d["message"], withPopFirst: true);
  }
}

class StatusCircle extends CustomPainter {
  final bool isLast;

  StatusCircle({super.repaint, required this.isLast});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isLast ? Colors.green : const Color.fromARGB(255, 86, 86, 86);
    canvas.drawCircle(const Offset(-15.9, 0), 6, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
