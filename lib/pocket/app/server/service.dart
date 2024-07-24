import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:uuid/uuid.dart';

import '../../../api/service.dart';
import 'server.dart';
import 'token.dart';

class ServiceManageView extends ConsumerStatefulWidget {
  const ServiceManageView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ServiceViewState();
}

class _ServiceViewState extends ConsumerState<ServiceManageView> {
  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("服务管理"), actions: [
          IconButton(
              onPressed: () async {
                await ref.watch(serviceDbProvider.notifier).rewrite();
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text("已更新")));
              },
              icon: const Icon(Icons.save)),
          const SizedBox(width: 10)
        ]),
        body: IndexedStack(index: _currentIndex, children: const [
          ServiceEmbededView(),
          ServerEmbededView(),
          TokenEmbededView()
        ]),
        floatingActionButton: FloatingActionButton(
            onPressed: () {
              Widget? view;
              switch (_currentIndex) {
                case 0:
                  view = const ServiceEditorView(null);
                case 1:
                  view = const ServerEditorView(null);
                case 2:
                  view = const TokenEditorView(null);
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
              BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "服务"),
              BottomNavigationBarItem(icon: Icon(Icons.dns), label: "主机"),
              BottomNavigationBarItem(icon: Icon(Icons.key), label: "OAuth密钥"),
            ]));
  }
}

class ServiceEmbededView extends ConsumerStatefulWidget {
  const ServiceEmbededView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ServiceEmbededViewState();
}

class _ServiceEmbededViewState extends ConsumerState<ServiceEmbededView> {
  bool _showEndpoints = false;
  final Set<String> _selectHost = {};
  bool _showFilter = false;
  @override
  Widget build(BuildContext context) {
    final db = ref.watch(serviceDbProvider).value;
    var services = db?.services.values.toList() ?? [];
    final hostMap = db?.servers ?? {};
    final hosts = hostMap.values.toList();
    services = services.where((s) {
      final match1 = _showEndpoints ? s.type == ServiceType.http : true;
      final match2 = _selectHost.isEmpty || _selectHost.contains(s.serverId);
      return match1 && match2;
    }).toList();
    services.sort((b, a) {
      final r = a.serverId.compareTo(b.serverId);
      if (r == 0) {
        return a.type.index.compareTo(b.type.index);
      } else {
        return r;
      }
    });
    return Stack(children: [
      ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return ListTile(
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                          title: const Text("可用端点"),
                          children: service.endpoints.isEmpty
                              ? [const SimpleDialogOption(child: Text("无可用端点"))]
                              : [
                                  for (var e in service.endpoints)
                                    SimpleDialogOption(
                                        child: Text(e),
                                        onPressed: () =>
                                            launchUrlString("https://" + e))
                                ]));
                },
                dense: true,
                title: Row(children: [
                  Transform.translate(
                      offset: const Offset(-1.5, 1),
                      child: Icon(service.type.icon, size: 18)),
                  const SizedBox(width: 3),
                  Text(service.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16))
                ]),
                contentPadding: const EdgeInsets.only(left: 20, right: 5),
                subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hostMap[service.serverId]?.name ?? "无服务器",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary)),
                      if (!_showEndpoints) Text(service.note),
                      if (_showEndpoints)
                        Text(service.endpoints.join("\n"),
                            style: const TextStyle(
                                fontSize: 13,
                                color: Colors.blue,
                                fontFamily: 'consolas'))
                    ]),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  ServiceEditorView(service)))),
                  IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => ref
                          .read(serviceDbProvider.notifier)
                          .deleteService(service.id))
                ]));
          }),
      Positioned(
          child: Wrap(spacing: 5, runSpacing: 5, children: [
            if (_showFilter)
              ActionChip(
                  color: _showEndpoints
                      ? WidgetStatePropertyAll(
                          Theme.of(context).colorScheme.primaryContainer)
                      : null,
                  label: const Text("HTTP 服务"),
                  onPressed: () {
                    setState(() => _showEndpoints = !_showEndpoints);
                  }),
            if (_showFilter)
              ...hosts.map((h) => ActionChip(
                  label: Text(h.name),
                  color: _selectHost.contains(h.id)
                      ? WidgetStatePropertyAll(
                          Theme.of(context).colorScheme.primaryContainer)
                      : null,
                  onPressed: () {
                    setState(() {
                      if (_selectHost.contains(h.id)) {
                        _selectHost.remove(h.id);
                      } else {
                        _selectHost.add(h.id);
                      }
                    });
                  })),
            IconButton(
                onPressed: () => setState(() => _showFilter = !_showFilter),
                icon: Icon(Icons.filter_alt,
                    color: Theme.of(context).colorScheme.secondary))
          ]),
          right: 10,
          bottom: 10,
          left: 10)
    ]);
  }
}

class ServiceEditorView extends ConsumerStatefulWidget {
  final ServerService? service;
  const ServiceEditorView(this.service, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ServiceEditorViewState();
}

class _ServiceEditorViewState extends ConsumerState<ServiceEditorView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _noteController;
  late TextEditingController _implController;
  late ServiceType _type;
  List<String> endpoints = [];
  List<String> tokens = [];
  String? server;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service?.name);
    _noteController = TextEditingController(text: widget.service?.note);
    _implController = TextEditingController(text: widget.service?.implDetails);
    _type = widget.service?.type ?? ServiceType.http;
    endpoints = [...?widget.service?.endpoints];
    tokens = [...?widget.service?.tokenIds];
    server = widget.service?.serverId;
    if (server != null && server!.isEmpty) server = null;
  }

  @override
  void dispose() {
    _clearForm();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _noteController.clear();
    _implController.clear();
  }

  void _addOrUpdateServer() {
    if (_formKey.currentState!.validate()) {
      var newService = (widget.service ?? ServerService(id: const Uuid().v4()))
          .copyWith(
              name: _nameController.text,
              note: _noteController.text,
              endpoints: endpoints,
              tokenIds: tokens,
              serverId: server ?? "",
              implDetails: _implController.text,
              type: _type);
      ref.read(serviceDbProvider.notifier).makeMemchangeOfService(newService);
      _clearForm();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdd = widget.service == null;
    final tokensMap = ref.read(serviceDbProvider).value?.tokens ?? {};
    final serversMap = ref.read(serviceDbProvider).value?.servers ?? {};
    if (!serversMap.containsKey(server)) server = null;
    tokens.removeWhere((element) => !tokensMap.containsKey(element));
    return Scaffold(
        appBar: AppBar(title: Text(isAdd ? "Add" : "Edit")),
        body: Form(
            key: _formKey,
            child: ListView(
                padding: const EdgeInsets.only(left: 16, right: 16),
                children: [
                  TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name*'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      }),
                  TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(labelText: 'Note'),
                      maxLines: null),
                  Row(children: [
                    Text("Type", style: Theme.of(context).textTheme.bodyLarge),
                    const Spacer(),
                    DropdownButton<ServiceType>(
                        focusColor: Colors.transparent,
                        value: _type,
                        items: [
                          for (final s in ServiceType.values)
                            DropdownMenuItem(value: s, child: Text(s.desc))
                        ],
                        onChanged: (v) => setState(() {
                              if (v != null) _type = v;
                            }))
                  ]),
                  Row(children: [
                    Text("Endpoints",
                        style: Theme.of(context).textTheme.bodyLarge),
                    const Spacer(),
                    IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => addOrEditEndpoint())
                  ]),
                  Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...endpoints.map((e) => ListTile(
                            title: Text(e,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.black87)),
                            contentPadding: const EdgeInsets.only(),
                            onTap: () => launchUrlString("https://" + e),
                            trailing:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => addOrEditEndpoint(e)),
                              IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () =>
                                      setState(() => endpoints.remove(e)))
                            ])))
                      ]),
                  Row(children: [
                    Text("Server",
                        style: Theme.of(context).textTheme.bodyLarge),
                    const Spacer(),
                    if (server == null || serversMap.containsKey(server))
                      DropdownButton(
                          focusColor: Colors.transparent,
                          value: server,
                          items: [
                            for (final s in [
                              ...serversMap.values,
                              Server(id: "0", name: "取消选择")
                            ])
                              DropdownMenuItem(value: s.id, child: Text(s.name))
                          ],
                          onChanged: (v) => setState(() {
                                if (v != null && v != "0") {
                                  server = v;
                                } else if (v == "0") {
                                  server = null;
                                }
                              }))
                  ]),
                  Row(children: [
                    Text("Tokens",
                        style: Theme.of(context).textTheme.bodyLarge),
                    const Spacer(),
                    if (tokensMap.isEmpty)
                      const Text("请先新建 Token")
                    else
                      DropdownButton(
                          focusColor: Colors.transparent,
                          value: null,
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text("选择 Token")),
                            for (final s in [...tokensMap.values])
                              DropdownMenuItem(value: s.id, child: Text(s.name))
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              if (!tokens.contains(v)) {
                                setState(() {
                                  tokens.add(v);
                                });
                              }
                            }
                          })
                  ]),
                  Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...tokens.map((e) {
                          final token = tokensMap[e]!;
                          return ListTile(
                              title: Text(token.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.black87)),
                              subtitle: Text(token.note,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.black87)),
                              onTap: () =>
                                  launchUrlString("https://" + token.manageUrl),
                              contentPadding: const EdgeInsets.only(),
                              trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () async {
                                          await Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      TokenEditorView(token)));
                                          setState(() {});
                                        }),
                                    IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () =>
                                            setState(() => tokens.remove(e)))
                                  ]));
                        })
                      ]),
                  TextFormField(
                      controller: _implController,
                      decoration:
                          const InputDecoration(labelText: 'Impl Details'),
                      maxLines: null),
                  const SizedBox(height: 55)
                ])),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: _addOrUpdateServer,
            label: Text(isAdd ? "添加服务" : "更新服务"),
            icon: Icon(isAdd ? Icons.add : Icons.save)));
  }

  addOrEditEndpoint([String? endpoint]) async {
    final c = TextEditingController(text: endpoint);
    final res = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
                content: TextField(
                    autofocus: true,
                    controller: c,
                    decoration: const InputDecoration(
                        labelText: "端点", prefixText: "https://")),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(""),
                      child: const Text("取消")),
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(c.text),
                      child: const Text("确定"))
                ]));
    if (res != null && res.isNotEmpty) {
      if (endpoint != null) {
        endpoints.remove(endpoint);
        endpoints.add(res);
      } else {
        endpoints.add(res);
      }
      setState(() {});
    }
  }
}
