import 'dart:math';

import 'package:cyberme_flutter/pocket/viewmodels/esxi.dart';
import 'package:cyberme_flutter/main.dart';
import 'package:cyberme_flutter/pocket/views/util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

class StatusPainter extends CustomPainter {
  final double width;
  final double height;
  final Color color;

  StatusPainter(this.color, this.width, this.height);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(-1, 10 - height, width, height), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class EsxiView extends ConsumerStatefulWidget {
  const EsxiView({super.key});

  @override
  ConsumerState<EsxiView> createState() => _EsxiViewState();
}

class _EsxiViewState extends ConsumerState<EsxiView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleRouteParameters();
    });
  }

  void _handleRouteParameters() async {
    final Map<String, String>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>?;

    if (args != null && args.containsKey('host') && args.containsKey('power')) {
      final String host = args['host']!;
      final String power = args['power']!;

      final data = await ref.read(esxiInfosProvider.future);
      final vm = data.$1!.vms
          .where((vm) => vm.name == host || vm.vmid == host)
          .firstOrNull;

      if (vm != null) {
        showSimpleMessage(context,
            content: "正在对虚拟机 ${vm.name} 执行动作：${power.toUpperCase()}",
            useSnackBar: true,
            duration: 1500);
        VmPower powerAction;
        switch (power.toLowerCase()) {
          case 'on':
            powerAction = VmPower.on;
            break;
          case 'off':
            powerAction = VmPower.off;
            break;
          case 'suspended':
            powerAction = VmPower.suspended;
            break;
          default:
            powerAction = VmPower.on; // 默认为开机
        }

        ref
            .read(esxiInfosProvider.notifier)
            .changeState(vm, powerAction)
            .then((res) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res),
            duration: const Duration(seconds: 2),
          ));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('未找到指定的虚拟机: $host'),
            duration: const Duration(seconds: 2)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(esxiInfosProvider).value;
    final setting =
        ref.watch(eSXiSettingsProvider).value ?? const ESXiSetting();
    Widget content;
    if (data == null) {
      content = const Padding(
          padding: EdgeInsets.only(top: 50),
          child: CupertinoActivityIndicator());
    } else if (data.$2.isNotEmpty) {
      content = Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Center(child: Text(data.$2)));
    } else {
      final d = data.$1!;
      content = Padding(
          padding: const EdgeInsets.only(left: 0, right: 0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
                padding: EdgeInsets.only(left: 15, top: 8, bottom: 0),
                child: Text("ADDRESS",
                    style: TextStyle(fontWeight: FontWeight.bold))),
            ...d.ips
                .map((e) {
                  return ListTile(
                      title: Text(e.ip_address),
                      subtitle: Text(
                          e.ip_family + " / " + e.type.replaceAll("__", ", ")),
                      trailing: Text(e.interface),
                      dense: true);
                })
                .toList()
                .animate()
                .fadeIn()
                .moveY(begin: 10, end: 0),
            const Padding(
                padding: EdgeInsets.only(left: 15, top: 8, bottom: 0),
                child:
                    Text("VMS", style: TextStyle(fontWeight: FontWeight.bold))),
            ...d.vms.indexed
                .map((e) {
                  final vm = e.$2;
                  final svc = setting.services[e.$2.vmid]?.toList() ?? [];
                  final ip = setting.ips[e.$2.vmid] ?? "";
                  return Dismissible(
                      key: ValueKey(e),
                      confirmDismiss: (direction) async {
                        final res = await ref
                            .read(esxiInfosProvider.notifier)
                            .changeState(
                                vm,
                                direction == DismissDirection.endToStart
                                    ? VmPower.suspended
                                    : VmPower.on);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(res),
                            duration: const Duration(milliseconds: 500)));
                        return false;
                      },
                      secondaryBackground: Container(
                          color: Colors.yellow,
                          child: const Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                  padding: EdgeInsets.only(right: 20),
                                  child: Text("休眠",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15))))),
                      background: Container(
                          color: Colors.green,
                          child: const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                  padding: EdgeInsets.only(left: 20),
                                  child: Text("启动",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15))))),
                      child: ListTile(
                          onTap: () => showModalBottomSheet(
                              context: context,
                              builder: (context) =>
                                  ESXiVmDeatilView(e.$2.vmid)),
                          title: Row(children: [
                            status2Logo(e.$2, index: e.$1),
                            Text(e.$2.name)
                          ]),
                          subtitle: Text(vmOs(e.$2) +
                              " / ${e.$2.version}" +
                              (ip.isEmpty ? "" : " / $ip")),
                          trailing: svc.isEmpty
                              ? null
                              : Container(
                                      padding: const EdgeInsets.only(
                                          left: 5, right: 5, bottom: 3, top: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade200,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text("服务 ${svc.length}",
                                          style: const TextStyle(
                                              color: Colors.white)))
                                  .animate()
                                  .shake(),
                          dense: true));
                })
                .toList()
                .animate()
                .fadeIn()
                .moveY(begin: 10, end: 0),
            const SizedBox(height: 100),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(d.version,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 10))
            ]),
            const SizedBox(height: 10)
          ]));
    }
    return Scaffold(
        body: CustomScrollView(slivers: [
      SliverAppBar.large(
          title:
              const Text("Pocket ESXi", style: TextStyle(color: Colors.white)),
          actions: [
            IconButton(
                onPressed: () async {
                  final answer = await showSimpleMessage(context,
                      content: "将会关闭服务器，确定执行此操作吗?");
                  if (answer) {
                    final res = await ref
                        .read(esxiInfosProvider.notifier)
                        .powerOff(reboot: false);
                    await showSimpleMessage(context, content: res);
                  }
                },
                icon: const Icon(Icons.power_settings_new)),
            IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showMaterialBanner(
                      MaterialBanner(
                          content: const Text("正在刷新数据，请稍后..."),
                          actions: [
                        TextButton(
                            onPressed: () => ScaffoldMessenger.of(context)
                                .clearMaterialBanners(),
                            child: const Text("OK"))
                      ]));
                  ref.read(esxiInfosProvider.notifier).sync().then((value) =>
                      ScaffoldMessenger.of(context).clearMaterialBanners());
                },
                icon: const Icon(Icons.sync))
          ],
          pinned: true,
          stretch: true,
          flexibleSpace: Container(
              decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage("images/server.jpg"),
                      fit: BoxFit.cover)))),
      SliverToBoxAdapter(child: content)
    ]));
  }

  String vmOs(EsxiVm e) {
    final os = e.os.toLowerCase();
    if (os.contains("windows")) {
      return "Windows";
    } else if (os.contains("ubuntu")) {
      return "Ubuntu Linux";
    } else if (os.contains("cent")) {
      return "CentOS Linux";
    } else if (os.contains("mac") || os.contains("darwin")) {
      return "macOS";
    } else if (os.contains("linux")) {
      return "Linux";
    } else {
      return os;
    }
  }

  popVmMenu(EsxiVm vm) async {
    change(VmPower power) async {
      Navigator.of(context).pop();
      final res =
          await ref.read(esxiInfosProvider.notifier).changeState(vm, power);
      await showDialog(
          context: context,
          builder: (context) => Theme(
              data: appThemeData,
              child: AlertDialog(
                  title: const Text("结果"),
                  content: Text(res),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("确定"))
                  ])));
    }

    await showDialog(
        context: context,
        builder: (context) => SimpleDialog(
                title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(vm.name.toUpperCase()),
                        const Spacer(),
                        status2Logo(vm),
                        Text("may ${vm.power}",
                            style: const TextStyle(fontSize: 12))
                      ]),
                      Text(
                          "id: ${vm.vmid}\nfile: ${vm.guest}\nos: ${vm.os}\nversion: ${vm.version}",
                          style: const TextStyle(fontSize: 12))
                    ]),
                children: [
                  SimpleDialogOption(
                      onPressed: () => change(VmPower.on),
                      child: const Text("启动此虚拟机")),
                  SimpleDialogOption(
                      onPressed: () => change(VmPower.suspended),
                      child: const Text("暂停此虚拟机")),
                  SimpleDialogOption(
                      onPressed: () => change(VmPower.off),
                      child: Text("关闭此虚拟机",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)))
                ]));
  }
}

class ESXiVmDeatilView extends ConsumerStatefulWidget {
  final String vmId;
  const ESXiVmDeatilView(this.vmId, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ESXiVmDeatilViewState();
}

class _ESXiVmDeatilViewState extends ConsumerState<ESXiVmDeatilView> {
  @override
  Widget build(BuildContext context) {
    final setting =
        ref.watch(eSXiSettingsProvider).value ?? const ESXiSetting();
    final vm = ref
        .watch(esxiInfosProvider)
        .value
        ?.$1
        ?.vms
        .where((element) => element.vmid == widget.vmId)
        .firstOrNull;
    if (vm == null) {
      return const Center(child: CupertinoActivityIndicator());
    }
    final svc = setting.services[vm.vmid]?.toList() ?? [];
    final ip = setting.ips[vm.vmid] ?? "";
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 20),
      Padding(
              padding: const EdgeInsets.only(left: 11),
              child: Text(vm.name,
                  style: TextStyle(
                      fontSize: 24,
                      decoration: TextDecoration.underline,
                      decorationStyle: TextDecorationStyle.solid,
                      decorationThickness: 1.5,
                      decorationColor: status2Color(vm))))
          .animate()
          .flipV(delay: 100.milliseconds),
      Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: Text(
              "id: ${vm.vmid}\nip: ${ip.isEmpty ? "Unknown" : ip}\nfile: ${vm.guest}\nos: ${vm.os}\nversion: ${vm.version}",
              style: const TextStyle(fontSize: 12))),
      const SizedBox(height: 10),
      Expanded(
          child: ListView.builder(
              itemBuilder: (context, index) {
                final service = svc[index];
                return Dismissible(
                    key: ValueKey(service),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        final ready = await showSimpleMessage(context,
                            content: "确定删除此服务?");
                        if (ready) {
                          await ref
                              .read(eSXiSettingsProvider.notifier)
                              .removeService(widget.vmId, service);
                          return true;
                        }
                      } else {
                        addOrEditSvc(service);
                        return false;
                      }
                      return null;
                    },
                    secondaryBackground: Container(
                        color: Colors.red,
                        child: const Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                                padding: EdgeInsets.only(right: 20),
                                child: Icon(Icons.delete,
                                    color: Colors.white, size: 30)))),
                    background: Container(
                        color: Colors.blue,
                        child: const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                                padding: EdgeInsets.only(left: 20),
                                child: Text("修改",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 15))))),
                    child: ListTile(
                        onTap: ip.isEmpty
                            ? null
                            : () => launchUrlString(
                                "${service.useHttps ? 'https' : 'http'}://$ip:${service.port}"),
                        title: Text(service.name),
                        subtitle:
                            Text(service.note.isEmpty ? "无备注" : service.note),
                        trailing: Text(service.port.toString()),
                        dense: true));
              },
              itemCount: svc.length)),
      ButtonBar(alignment: MainAxisAlignment.center, children: [
        TextButton(onPressed: () => changeIp(setting), child: const Text("地址")),
        TextButton(
            onPressed: () => addOrEditSvc(null), child: const Text("服务+")),
        TextButton(
            onPressed: () => change(vm, VmPower.on), child: const Text("启动")),
        TextButton(
            onPressed: () => change(vm, VmPower.suspended),
            child: const Text("暂停")),
        TextButton(
            onPressed: () => change(vm, VmPower.off),
            child: Text("关闭",
                style: TextStyle(color: Theme.of(context).colorScheme.error)))
      ])
    ]);
  }

  change(EsxiVm vm, VmPower power) async {
    final res =
        await ref.read(esxiInfosProvider.notifier).changeState(vm, power);
    await showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(title: const Text("结果"), content: Text(res), actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("确定"))
            ]));
  }

  addOrEditSvc(ESXiService? svc) async {
    final name = TextEditingController(text: svc?.name ?? "");
    final port = TextEditingController(text: svc?.port.toString() ?? "");
    final note = TextEditingController(text: svc?.note ?? "");
    var useHttps = svc?.useHttps ?? true;
    await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setState) => Theme(
                data: appThemeData,
                child: AlertDialog(
                    title: Text(svc == null ? "添加服务" : "修改服务"),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextField(
                          autofocus: true,
                          controller: name,
                          decoration: const InputDecoration(labelText: "服务名*")),
                      TextField(
                          controller: port,
                          decoration: const InputDecoration(labelText: "端口*"),
                          keyboardType: TextInputType.number),
                      TextField(
                          controller: note,
                          decoration: const InputDecoration(labelText: "备注")),
                      const SizedBox(height: 10),
                      Row(children: [
                        const Text("https 协议"),
                        const Spacer(),
                        Switch(
                            value: useHttps,
                            onChanged: (v) => setState(() => useHttps = v))
                      ])
                    ]),
                    actions: [
                      TextButton(
                          onPressed: () {
                            //服务名和端口不能为空
                            if (name.text.isEmpty || port.text.isEmpty) {
                              showSimpleMessage(context, content: "服务名和端口不能为空");
                              return;
                            }
                            //端口必须为数字
                            if (!RegExp(r"^\d+$").hasMatch(port.text)) {
                              showSimpleMessage(context, content: "端口必须为数字");
                              return;
                            }
                            //添加服务
                            ref
                                .read(eSXiSettingsProvider.notifier)
                                .addService(
                                    widget.vmId,
                                    ESXiService(
                                        name: name.text,
                                        port: int.parse(port.text),
                                        note: note.text,
                                        useHttps: useHttps),
                                    svc != null)
                                .then((value) {
                              if (value.isEmpty) {
                                Navigator.of(context).pop();
                              } else {
                                Navigator.of(context).pop();
                                showSimpleMessage(context, content: value);
                              }
                            });
                          },
                          child: const Text("确定"))
                    ]))));
  }

  changeIp(ESXiSetting setting) async {
    final ip = TextEditingController(text: setting.ips[widget.vmId] ?? "");
    await showDialog(
        context: context,
        builder: ((context) => Theme(
              data: appThemeData,
              child: AlertDialog(
                  title: const Text("修改IP"),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(
                        autofocus: true,
                        controller: ip,
                        decoration: const InputDecoration(labelText: "IP*")),
                  ]),
                  actions: [
                    TextButton(
                        onPressed: () {
                          //IP不能为空
                          if (ip.text.isEmpty) {
                            showSimpleMessage(context, content: "IP不能为空");
                            return;
                          }
                          //添加IP
                          ref
                              .read(eSXiSettingsProvider.notifier)
                              .addIp(
                                widget.vmId,
                                ip.text,
                              )
                              .then((value) {
                            if (value.isEmpty) {
                              Navigator.of(context).pop();
                            } else {
                              Navigator.of(context).pop();
                              showSimpleMessage(context, content: value);
                            }
                          });
                        },
                        child: const Text("确定"))
                  ]),
            )));
  }
}

Color status2Color(EsxiVm e) {
  return e.powerEnum == VmPower.on
      ? Colors.green
      : e.powerEnum == VmPower.off
          ? Colors.red
          : e.powerEnum == VmPower.suspended
              ? Colors.yellow
              : Colors.grey;
}

Widget status2Logo(EsxiVm e,
    {int index = 0, double height = 10, double width = 30}) {
  return TweenAnimationBuilder(
      key: ValueKey(e.power),
      //key: UniqueKey(),
      tween: IntTween(begin: max(30 - index * 30, 0), end: 100),
      curve: Curves.easeOutQuad,
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return CustomPaint(
            painter: StatusPainter(
                status2Color(e), width * value * 0.01, height * value * 0.01));
      });
}
