import 'package:cyberme_flutter/pocket/viewmodels/image.dart';
import 'package:cyberme_flutter/pocket/views/server/container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../util.dart';

class ImageView extends ConsumerStatefulWidget {
  const ImageView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ImageViewState();
}

class _ImageViewState extends ConsumerState<ImageView> {
  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("容器镜像管理"), actions: [
          IconButton(onPressed: () async {}, icon: const Icon(Icons.save)),
          const SizedBox(width: 10)
        ]),
        body: IndexedStack(
            index: _currentIndex,
            children: const [RegistryView(), ContainerView()]),
        floatingActionButton: FloatingActionButton(
            onPressed: () {
              Widget? view;
              switch (_currentIndex) {
                default:
                  break;
              }
              if (view != null) {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => view!));
              }
            },
            child: const Icon(Icons.add)),
        bottomNavigationBar: BottomNavigationBar(
            onTap: (i) {
              setState(() {
                _currentIndex = i;
              });
            },
            currentIndex: _currentIndex,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.cloud_queue), label: "仓库"),
              BottomNavigationBarItem(icon: Icon(Icons.view_in_ar), label: "镜像")
            ]));
  }
}

class RegistryView extends ConsumerStatefulWidget {
  const RegistryView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RegistryViewState();
}

class _RegistryViewState extends ConsumerState<RegistryView> {
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(getRegistryProvider).value ?? [];
    return ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];
          return Dismissible(
            key: ValueKey(item.id),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.endToStart) {
                if (await showSimpleMessage(context, content: "确定删除此仓库吗?")) {
                  final res = await ref
                      .read(imageDbProvider.notifier)
                      .deleteRegistry(item.id);
                  await showSimpleMessage(context,
                      content: res, useSnackBar: true);
                  return true;
                }
              } else {
                //showEditDialog(activity);
                return false;
              }
              return false;
            },
            secondaryBackground: m.Container(
                color: Colors.red,
                child: const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                        padding: EdgeInsets.only(right: 20),
                        child: Text("删除",
                            style: TextStyle(
                                color: Colors.white, fontSize: 15))))),
            background: m.Container(
                color: Colors.blue,
                child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                        padding: EdgeInsets.only(left: 20),
                        child: Text("编辑",
                            style: TextStyle(
                                color: Colors.white, fontSize: 15))))),
            child: ListTile(
                title: Row(
                  children: [
                    m.Container(
                        padding: const EdgeInsets.only(
                          left: 4,
                          right: 4,
                        ),
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: Theme.of(context)
                                .primaryColor
                                .withOpacity(0.2)),
                        child: Text(item.id.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 12, fontFamily: "Consolas"))),
                    Text(item.note,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                onTap: () {},
                trailing: IconButton(
                    onPressed: () => launchUrlString(item.manageUrl),
                    icon: const Icon(Icons.open_in_browser_sharp)),
                dense: true,
                subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(item.user), Text(item.url)])),
          );
        });
  }
}
