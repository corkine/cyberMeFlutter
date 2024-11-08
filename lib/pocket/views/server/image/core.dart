import 'package:cyberme_flutter/pocket/views/server/image/container.dart';
import 'package:cyberme_flutter/pocket/views/util.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../viewmodels/image.dart';
import 'registry.dart';

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
          IconButton(
              onPressed: () async {
                final a =
                    await ref.watch(imageDbProvider.notifier).saveToRemote();
                await showSimpleMessage(context, content: a, useSnackBar: true);
              },
              icon: const Icon(Icons.save)),
          const SizedBox(width: 10)
        ]),
        body: IndexedStack(
            index: _currentIndex,
            children: const [RegistryView(), ContainerView()]),
        floatingActionButton: FloatingActionButton(
            onPressed: () {
              Widget? view;
              switch (_currentIndex) {
                case 0:
                  view = RepoAddEditView(registry: Registry());
                case 1:
                  view = ContainerAddEditView(Container1());
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
