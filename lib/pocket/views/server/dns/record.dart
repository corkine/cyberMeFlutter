import 'package:cyberme_flutter/pocket/views/util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../viewmodels/dns.dart';
import 'core.dart';

class ZoneDnsView extends ConsumerStatefulWidget {
  final DnsSetting setting;
  final Zone zone;
  const ZoneDnsView(this.setting, this.zone, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ZoneDnsViewState();
}

class _ZoneDnsViewState extends ConsumerState<ZoneDnsView> with Loading {
  @override
  Widget build(BuildContext context) {
    final dns = ref
        .watch(getZoneDnsFilterProvider(widget.zone.id, _controller.text))
        .value;
    final body = dns == null
        ? loading
        : dns.$1.isNotEmpty
            ? error(dns.$1)
            : buildBody(dns);
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.zone.name,
                style: const TextStyle(fontSize: 15, fontFamily: "consolas")),
            actions: [
              IconButton(onPressed: addRecord, icon: const Icon(Icons.add)),
              const SizedBox(width: 10)
            ]),
        body: body);
  }

  Widget buildBody(dns) {
    return Column(children: [
      Expanded(
          child: ListView.builder(
              itemBuilder: (context, index) {
                final d = dns.$2![index];
                return Dismissible(
                    key: ValueKey(d.id),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        final ready = await showSimpleMessage(context,
                            content: "确定删除此记录?");
                        if (ready) {
                          final res = await ref
                              .read(dnsSettingDbProvider.notifier)
                              .removeRecord(widget.zone.id, d.id);
                          await showSimpleMessage(context, content: res);
                          return true;
                        }
                      } else {
                        editRecord(d);
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
                        dense: true,
                        leading: Container(
                            padding: const EdgeInsets.only(
                                left: 8, right: 8, top: 2, bottom: 2),
                            decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(5)),
                            child: Text(d.type)),
                        title: Text(d.name),
                        subtitle: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                Text(d.proxied ? "PROXY" : "",
                                    style: const TextStyle(color: Colors.red)),
                                if (d.proxied) const SizedBox(width: 5),
                                Expanded(
                                    child: Text(d.content,
                                        maxLines: 1,
                                        overflow: TextOverflow.fade,
                                        softWrap: false,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary)))
                              ])
                            ])));
              },
              itemCount: dns.$2!.length)),
      Padding(
          padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
          child: CupertinoTextField(
              autofocus: true,
              controller: _controller,
              onSubmitted: (v) {
                setState(() {});
              },
              suffix: InkResponse(
                  onTap: () => setState(() {
                        _controller.text = "";
                      }),
                  child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(Icons.clear,
                          color: Theme.of(context).colorScheme.error,
                          size: 16))),
              style: const TextStyle(fontSize: 12),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8))))
    ]);
  }

  final _controller = TextEditingController();

  void addRecord() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) =>
            RecordAddEditView(zone: widget.zone, record: Record())));
  }

  void editRecord(Record record) {
    if (record.type != "A" &&
        record.type != "CNAME" &&
        record.type != "MX" &&
        record.type != "TXT") {
      showSimpleMessage(context, content: "目前只支持 A 和 CNAME 记录");
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) =>
            RecordAddEditView(zone: widget.zone, record: record)));
  }
}

class RecordAddEditView extends ConsumerStatefulWidget {
  final Zone zone;
  final Record record;
  const RecordAddEditView(
      {super.key, required this.zone, required this.record});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _RecordAddEditViewState();
}

class _RecordAddEditViewState extends ConsumerState<RecordAddEditView> {
  final key = GlobalKey<FormState>();
  late var record = widget.record;
  late bool isEdit = widget.record.id.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: isEdit ? const Text("修改记录") : const Text("增加记录"),
            actions: [
              IconButton(onPressed: commit, icon: const Icon(Icons.save)),
              const SizedBox(width: 10)
            ]),
        body: Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: Form(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Text("类型"),
                        const Spacer(),
                        DropdownButton<String>(
                            isDense: true,
                            focusColor: Colors.transparent,
                            value: record.type,
                            onChanged: (v) => setState(() {
                                  record = record.copyWith(type: v!);
                                }),
                            items: const [
                              DropdownMenuItem(child: Text("A"), value: "A"),
                              DropdownMenuItem(
                                  child: Text("CNAME"), value: "CNAME"),
                              DropdownMenuItem(child: Text("MX"), value: "MX"),
                              DropdownMenuItem(child: Text("TXT"), value: "TXT")
                            ])
                      ]),
                      record.name == widget.zone.name
                          ? TextFormField(
                              decoration: const InputDecoration(hintText: "名称"),
                              initialValue: record.name,
                              validator: (e) => e == null ? "名称不能为空" : null,
                              onSaved: (v) =>
                                  record = record.copyWith(name: v!))
                          : TextFormField(
                              decoration: InputDecoration(
                                  hintText: "名称",
                                  suffixText: ".${widget.zone.name}"),
                              initialValue: record.name
                                  .replaceAll(".${widget.zone.name}", ""),
                              validator: (e) => e == null ? "名称不能为空" : null,
                              onSaved: (v) => record = record.copyWith(
                                  name: v! + ".${widget.zone.name}")),
                      TextFormField(
                          decoration: const InputDecoration(hintText: "值"),
                          initialValue: record.content,
                          validator: (e) => e == null ? "值不能为空" : null,
                          onSaved: (v) =>
                              record = record.copyWith(content: v!)),
                      TextFormField(
                          decoration: const InputDecoration(hintText: "备注"),
                          initialValue: record.comment,
                          validator: (e) => e == null ? "备注不能为空" : null,
                          onSaved: (newValue) =>
                              record = record.copyWith(comment: newValue!)),
                      const SizedBox(height: 10),
                      Row(children: [
                        const Text("使用 Cloudflare 代理"),
                        const Spacer(),
                        Switch(
                            value: record.proxied,
                            onChanged: (v) => setState(() {
                                  record = record.copyWith(proxied: v);
                                }))
                      ])
                    ]),
                key: key)));
  }

  void commit() async {
    if (key.currentState!.validate()) {
      key.currentState!.save();
      debugPrint(record.toString());
      final res = isEdit
          ? await ref
              .read(dnsSettingDbProvider.notifier)
              .updateRecord(widget.zone.id, record)
          : await ref
              .read(dnsSettingDbProvider.notifier)
              .addRecord(widget.zone.id, record);
      if (await showSimpleMessage(context, content: res)) {
        Navigator.of(context).pop();
      }
    }
  }
}
