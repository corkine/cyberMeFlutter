import 'package:cyberme_flutter/api/statistics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final themeData = ThemeData.dark(useMaterial3: true);

class StatisticsView extends ConsumerWidget {
  const StatisticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(getStatisticsProvider).value?.$1;
    return Theme(
        data: themeData,
        child: Scaffold(
            appBar: AppBar(title: const Text("接口信息统计"), actions: [
              IconButton(
                  onPressed: () => ref.refresh(getStatisticsProvider),
                  icon: const Icon(Icons.refresh))
            ]),
            body: s == null
                ? const Center(child: CupertinoActivityIndicator())
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(children: [
                      buildOf("Web 主页接口", s.dashboard),
                      buildOf("客户端接口", s.client),
                      buildOf("短链接系统", s.go),
                      buildOf("故事系统", s.story),
                      buildOf("任务系统", s.task),
                      buildOf("问卷系统", s.psych)
                    ]))));
  }

  Widget buildOf(String item, count) {
    return Card(
        elevation: 1,
        child: ListTile(title: Text(item), trailing: Text(count.toString())));
  }
}

class ServiceView extends ConsumerWidget {
  const ServiceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(getServiceStatusProvider).value?.$1;
    return Theme(
        data: themeData,
        child: Scaffold(
            appBar: AppBar(title: const Text("服务状态")),
            body: s == null
                ? const Center(child: CupertinoActivityIndicator())
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RefreshIndicator(
                        onRefresh: () async =>
                            await ref.refresh(getServiceStatusProvider),
                        child: ListView.builder(
                            itemBuilder: (c, i) {
                              final item = s[i];
                              return Card(
                                elevation: 1,
                                child: ListTile(
                                    onTap: () {
                                      Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (c) =>
                                                  ServiceDetails(item)));
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                          color: item.endOfSupport
                                              ? Colors.red
                                              : Colors.green,
                                          width: 1),
                                    ),
                                    title: Text(item.serviceName ?? "未知服务"),
                                    subtitle: Text(
                                        "当前版本 ${item.version}，建议版本 ${item.suggestVersion}"),
                                    trailing: Text(
                                        item.endOfSupport ? "已停止" : "运行中")),
                              );
                            },
                            itemCount: s.length)))));
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
    showDialog(
        context: context,
        builder: (c) => AlertDialog(
                backgroundColor: themeData.backgroundColor,
                title: Text("确认操作",
                    style: themeData.textTheme.headlineLarge
                        ?.copyWith(fontSize: 20, color: Colors.red)),
                content: Text(
                    "是否要${status.endOfSupport ? "启动" : "停止"}服务？此操作可能影响正在使用应用的用户，请谨慎操作！",
                    style: themeData.textTheme.bodyLarge),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("取消")),
                  TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        final msg = await setServiceStatus(
                            status.path!, status.endOfSupport);
                        final s =
                            await ref.refresh(getServiceStatusProvider.future);
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
                                    backgroundColor: themeData.backgroundColor,
                                    title: Text("操作结果",
                                        style: themeData.textTheme.headlineLarge
                                            ?.copyWith(fontSize: 20)),
                                    content: Text(msg,
                                        style: themeData.textTheme.bodyLarge),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text("确认"))
                                    ]));
                      },
                      child: const Text("确认"))
                ]));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
        data: themeData,
        child: Scaffold(
            appBar: AppBar(title: Text(status.serviceName ?? "未知服务"), actions: [
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
                      Text("模板消息 ${status.endOfSupportMessage ?? "无"}")
                    ])))));
  }
}
