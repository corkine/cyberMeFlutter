import 'package:cyberme_flutter/main.dart';
import 'package:cyberme_flutter/pocket/viewmodels/tray.dart';
import 'package:cyberme_flutter/pocket/views/util.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class TraySettingView extends ConsumerStatefulWidget {
  const TraySettingView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _TraySettingViewState();
}

class _TraySettingViewState extends ConsumerState<TraySettingView> {
  @override
  Widget build(BuildContext context) {
    final items = ref.watch(traySettingsProvider).value ?? [];
    return Theme(
        data: appThemeData,
        child: Scaffold(
            appBar: AppBar(title: const Text('Tray Settings'), actions: [
              IconButton(
                  onPressed: () => _showAddEditDialog(),
                  icon: const Icon(Icons.add)),
              IconButton(
                  onPressed: () async {
                    final res = await ref
                        .read(traySettingsProvider.notifier)
                        .saveTraySettings();
                    showSimpleMessage(context, content: res, useSnackBar: true);
                  },
                  icon: const Icon(Icons.save)),
              const SizedBox(width: 5)
            ]),
            body: ListView.builder(
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                      onTap: () => _showAddEditDialog(item: item),
                      trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => ref
                              .read(traySettingsProvider.notifier)
                              .deleteItem(item.id)),
                      title: Text(item.name),
                      subtitle: Row(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            item.isSink
                                ? const Icon(Icons.dashboard, size: 15)
                                : const Icon(Icons.web, size: 15),
                            const SizedBox(width: 5),
                            Expanded(
                                child: Text(item.url,
                                    overflow: TextOverflow.fade, maxLines: 1))
                          ]));
                },
                itemCount: items.length)));
  }

  void _showAddEditDialog({TrayItem? item}) {
    final nameController = TextEditingController(text: item?.name);
    final urlController = TextEditingController(text: item?.url);
    var isSink = item?.isSink ?? true;

    showDialog(
        context: context,
        builder: (context) => Theme(
            data: appThemeData,
            child: StatefulBuilder(
                builder: (context, setState) => AlertDialog(
                        title: Text(item == null ? 'Add Item' : 'Edit Item'),
                        content:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          TextField(
                            controller: nameController,
                            decoration:
                                const InputDecoration(labelText: 'Name'),
                          ),
                          TextField(
                            controller: urlController,
                            decoration: const InputDecoration(labelText: 'URL'),
                          ),
                          const SizedBox(height: 10),
                          Row(children: [
                            Checkbox(
                                value: isSink,
                                onChanged: (v) => setState(() {
                                      isSink = v!;
                                    })),
                            const Text('内部 URL')
                          ])
                        ]),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                              onPressed: () {
                                final name = nameController.text.trim();
                                final url = urlController.text.trim();
                                if (name.isNotEmpty && url.isNotEmpty) {
                                  if (item == null) {
                                    ref
                                        .read(traySettingsProvider.notifier)
                                        .addItem(name, url, isSink);
                                  } else {
                                    ref
                                        .read(traySettingsProvider.notifier)
                                        .editItem(TrayItem(
                                            id: item.id,
                                            url: url,
                                            name: name,
                                            isSink: isSink));
                                  }
                                  Navigator.of(context).pop();
                                }
                              },
                              child: const Text('Save'))
                        ]))));
  }
}
