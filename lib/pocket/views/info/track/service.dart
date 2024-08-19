import 'package:cyberme_flutter/main.dart';
import 'package:cyberme_flutter/pocket/views/util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../viewmodels/statistics.dart';

class ServiceView extends ConsumerWidget {
  final bool useSheet;
  const ServiceView({super.key, this.useSheet = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(getServiceStatusProvider).value?.$1;
    Widget content;
    if (s == null) {
      content = const Center(child: CupertinoActivityIndicator());
    } else {
      final items = ListView.builder(
              itemBuilder: (c, i) {
                final item = s[i];
                handleShowDetail() {
                  if (useSheet) {
                    showModal(context, ServiceDetails(item));
                  } else {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (c) => ServiceDetails(item)));
                  }
                }

                return Card(
                    elevation: 1,
                    child: ListTile(
                        onTap: handleShowDetail,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                                color: item.endOfSupport
                                    ? Colors.red
                                    : Colors.green,
                                width: 1)),
                        title: Text(item.serviceName ?? "未知服务"),
                        subtitle: Text(
                            "当前版本 ${item.version}，建议版本 ${item.suggestVersion}"),
                        trailing: Text(item.endOfSupport ? "已停止" : "运行中")));
              },
              itemCount: s.length)
          .animate()
          .fadeIn()
          .moveY(begin: 30, end: 0);
      content = Padding(
          padding: const EdgeInsets.all(8.0),
          child: RefreshIndicator(
              onRefresh: () async =>
                  await ref.refresh(getServiceStatusProvider),
              child: items));
    }
    return Theme(
        data: appThemeData,
        child: Scaffold(
            appBar: AppBar(title: const Text("App Service")), body: content));
  }
}

class ServiceDetails extends ConsumerStatefulWidget {
  final ServiceStatus status;

  const ServiceDetails(this.status, {super.key});

  @override
  ConsumerState<ServiceDetails> createState() => _ServiceDetailsState();
}

class _ServiceDetailsState extends ConsumerState<ServiceDetails> {
  late var status = widget.status;

  setStatusToggle(BuildContext context, WidgetRef ref) async {
    handleAction() async {
      Navigator.of(context).pop();
      final msg = await setServiceStatus(status.path!, status.endOfSupport);
      final s = await ref.refresh(getServiceStatusProvider.future);
      for (var element in s.$1) {
        if (element.path == status.path) {
          status = element;
          setState(() {});
          break;
        }
      }
      showDialog(
          context: context,
          builder: (c) => AlertDialog(
                  backgroundColor: appThemeData.colorScheme.surface,
                  title: Text("操作结果",
                      style: appThemeData.textTheme.headlineLarge
                          ?.copyWith(fontSize: 20)),
                  content: Text(msg, style: appThemeData.textTheme.bodyLarge),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("确认"))
                  ]));
    }

    showDialog(
        context: context,
        builder: (c) => AlertDialog(
                backgroundColor: appThemeData.colorScheme.surface,
                title: Text("确认操作",
                    style: appThemeData.textTheme.headlineLarge
                        ?.copyWith(fontSize: 20, color: Colors.red)),
                content: Text(
                    "是否要${status.endOfSupport ? "启动" : "停止"}服务？此操作可能影响正在使用应用的用户，请谨慎操作！",
                    style: appThemeData.textTheme.bodyLarge),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("取消")),
                  TextButton(onPressed: handleAction, child: const Text("确认"))
                ]));
  }

  setNewMessage(BuildContext context, WidgetRef ref) async {
    final tc = TextEditingController(text: status.endOfSupportMessage ?? "");
    handleAction() async {
      Navigator.of(context).pop();
      if (tc.text.isEmpty) {
        await showSimpleMessage(context,
            content: "消息为空，已取消操作。", useSnackBar: true);
      } else {
        final msg = await setServiceStatus(status.path!, !status.endOfSupport,
            msg: tc.text);
        final s = await ref.refresh(getServiceStatusProvider.future);
        for (var element in s.$1) {
          if (element.path == status.path) {
            status = element;
            setState(() {});
            break;
          }
        }
        await showSimpleMessage(context, content: msg);
      }
    }

    showDialog(
        context: context,
        builder: (c) => Theme(
            data: appThemeData,
            child: AlertDialog(
                backgroundColor: appThemeData.colorScheme.surface,
                content: TextField(
                    controller: tc,
                    maxLines: 10,
                    decoration: const InputDecoration(label: Text("模板消息"))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("取消")),
                  TextButton(onPressed: handleAction, child: const Text("确认"))
                ])));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
        data: appThemeData,
        child: Scaffold(
            appBar: AppBar(title: Text(status.serviceName ?? "未知服务"), actions: [
              IconButton(
                  onPressed: () => setNewMessage(context, ref),
                  icon:
                      const Icon(Icons.message, color: Colors.white, size: 16)),
              IconButton(
                  onPressed: () => setStatusToggle(context, ref),
                  icon: status.endOfSupport
                      ? const Icon(Icons.play_arrow, color: Colors.green)
                      : const Icon(Icons.stop, color: Colors.red))
            ]),
            body: Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text("运行日志",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...status.logs.map((e) => Text(e)),
                      const SizedBox(height: 20),
                      const Text("运行状态",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                          "当前版本 ${status.version}\n建议版本 ${status.suggestVersion}"),
                      Text("运行路径 ${status.path}"),
                      Text("支持状态 ${status.endOfSupport ? "已停止" : "运行中"}"),
                      Text("模板消息 ${status.endOfSupportMessage ?? "无"}"),
                      const SizedBox(height: 20)
                    ])))));
  }
}
