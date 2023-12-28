import 'package:cyberme_flutter/api/esxi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class StatusPainter extends CustomPainter {
  final Color color;

  StatusPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRect(const Rect.fromLTWH(-1, 0, 50, 10), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return color != (oldDelegate as StatusPainter).color;
  }
}

class EsxiView extends ConsumerStatefulWidget {
  const EsxiView({super.key});

  @override
  ConsumerState<EsxiView> createState() => _EsxiViewState();
}

class _EsxiViewState extends ConsumerState<EsxiView> {
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(esxiInfosProvider).value;
    Widget content;
    if (data == null) {
      content = const Padding(
          padding: EdgeInsets.only(top: 50),
          child: CupertinoActivityIndicator());
    } else {
      content = Padding(
          padding: const EdgeInsets.only(left: 0, right: 0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
                padding: EdgeInsets.only(left: 15, top: 8, bottom: 0),
                child: Text("ADDRESS",
                    style: TextStyle(fontWeight: FontWeight.bold))),
            ...data.ips.map((e) {
              return ListTile(
                  title: Text(e.ip_address),
                  subtitle:
                      Text(e.ip_family + " / " + e.type.replaceAll("__", ", ")),
                  trailing: Text(e.interface),
                  dense: true);
            }).toList(),
            const Padding(
                padding: EdgeInsets.only(left: 15, top: 8, bottom: 0),
                child:
                    Text("VMS", style: TextStyle(fontWeight: FontWeight.bold))),
            ...data.vms.map((e) {
              return ListTile(
                  onTap: () => popVmMenu(e),
                  title: Row(children: [status2Logo(e), Text(e.name)]),
                  subtitle: Text(vmOs(e) + " / ${e.version}"),
                  trailing: Text(e.vmid),
                  dense: true);
            }).toList(),
            const SizedBox(height: 100),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(data.version,
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
              const Text("ESXi Manage", style: TextStyle(color: Colors.white)),
          actions: [
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
          expandedHeight: 220,
          pinned: true,
          stretch: true,
          flexibleSpace: Container(
              decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage("images/server.png"),
                      fit: BoxFit.cover)))),
      SliverToBoxAdapter(child: content)
    ]));
  }

  Widget status2Logo(EsxiVm e) {
    return CustomPaint(
        painter: StatusPainter(e.powerEnum == VmPower.on
            ? Colors.green
            : e.powerEnum == VmPower.off
                ? Colors.red
                : e.powerEnum == VmPower.suspended
                    ? Colors.yellow
                    : Colors.grey));
  }

  String vmOs(EsxiVm e) {
    final os = e.os.toLowerCase();
    if (os.contains("windows")) {
      return "Windows";
    } else if (os.contains("linux")) {
      return "Linux";
    } else if (os.contains("mac") || os.contains("darwin")) {
      return "macOS";
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
          builder: (context) => AlertDialog(
                  title: const Text("结果"),
                  content: Text(res),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("确定"))
                  ]));
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
                          "id: ${vm.vmid}\nguest: ${vm.guest}\nos: ${vm.os}\nversion: ${vm.version}",
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
