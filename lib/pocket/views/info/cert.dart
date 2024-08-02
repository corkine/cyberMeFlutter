import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:uuid/uuid.dart';
import '../../viewmodels/cert.dart';

class CertConfigView extends ConsumerStatefulWidget {
  const CertConfigView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CertConfigViewState();
}

class _CertConfigViewState extends ConsumerState<CertConfigView> {
  @override
  Widget build(BuildContext context) {
    final certsAsyncValue = ref.watch(certsProvider);
    return Scaffold(
        appBar: AppBar(title: const Text('证书管理')),
        body: certsAsyncValue.when(
          data: (certConfigs) => ListView(children: [
            for (var entry in certConfigs.certs.entries)
              ListTile(
                  title: Text(entry.value.name),
                  subtitle: Text(entry.value.domain),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editCert(context, entry.value)),
                    IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteCert(context, ref, entry.key))
                  ]),
                  onTap: () => _showCertDetails(context, ref, entry.value))
          ]),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
        floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add), onPressed: () => _addCert(context)));
  }

  void _showCertDetails(BuildContext context, WidgetRef ref, CertConfig cert) {
    Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (context) => CertDetailView(cert.id)));
  }

  void _addCert(BuildContext context) async {
    final newCert = await _showCertForm(context);
    if (newCert != null && newCert.id.isNotEmpty) {
      try {
        await ref.read(certsProvider.notifier).set(newCert);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Certificate added successfully')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding certificate: $e')));
      }
    }
  }

  void _editCert(BuildContext context, CertConfig cert) async {
    final updatedCert = await _showCertForm(context, cert);
    if (updatedCert != null) {
      try {
        await ref.read(certsProvider.notifier).set(updatedCert);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Certificate updated successfully')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating certificate: $e')));
      }
    }
  }

  void _deleteCert(BuildContext context, WidgetRef ref, String certName) async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Confirm Deletion'),
                content: const Text(
                    'Are you sure you want to delete this certificate?'),
                actions: [
                  TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(false)),
                  TextButton(
                      child: const Text('Delete'),
                      onPressed: () => Navigator.of(context).pop(true))
                ]));

    if (confirm == true) {
      try {
        await ref.read(certsProvider.notifier).remove(certName);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Certificate deleted successfully')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting certificate: $e')));
      }
    }
  }

  Future<CertConfig?> _showCertForm(BuildContext context,
      [CertConfig? existingCert]) async {
    final nameController =
        TextEditingController(text: existingCert?.name ?? '');
    final domainController =
        TextEditingController(text: existingCert?.domain ?? '');
    final noteController =
        TextEditingController(text: existingCert?.note ?? '');
    final publicKeyController =
        TextEditingController(text: existingCert?.publicKey ?? '');
    final privateKeyController =
        TextEditingController(text: existingCert?.privateKey ?? '');

    DateTime? selectedDate = existingCert?.expired != null
        ? DateTime.fromMillisecondsSinceEpoch(existingCert!.expired * 1000)
        : null;

    final res = await showModalBottomSheet<CertConfig>(
        context: context,
        isScrollControlled: true,
        builder: (context) => SizedBox(
            height: 500,
            child: StatefulBuilder(
                builder: (context, setState) => Scaffold(
                    appBar: AppBar(
                        title: Text(existingCert != null ? "编辑证书" : "添加证书")),
                    body: SingleChildScrollView(
                        child: Padding(
                            padding: const EdgeInsets.only(left: 10, right: 10),
                            child: ListBody(children: [
                              TextField(
                                  controller: nameController,
                                  decoration:
                                      const InputDecoration(labelText: 'Name')),
                              TextField(
                                  controller: domainController,
                                  decoration: const InputDecoration(
                                      labelText: 'Domain')),
                              Padding(
                                  padding:
                                      const EdgeInsets.only(top: 15, bottom: 0),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text('Expiry Date'),
                                              Text(selectedDate != null
                                                  ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                                                  : 'Not set')
                                            ]),
                                        IconButton(
                                            icon: const Icon(
                                                Icons.calendar_today),
                                            onPressed: () async {
                                              final DateTime? picked =
                                                  await showDatePicker(
                                                context: context,
                                                initialDate: selectedDate ??
                                                    DateTime.now(),
                                                firstDate: DateTime.now(),
                                                lastDate: DateTime(2101),
                                              );
                                              if (picked != null &&
                                                  picked != selectedDate) {
                                                setState(() {
                                                  selectedDate = picked;
                                                });
                                              }
                                            })
                                      ])),
                              TextField(
                                  controller: noteController,
                                  decoration:
                                      const InputDecoration(labelText: 'Note')),
                              TextField(
                                controller: publicKeyController,
                                decoration: const InputDecoration(
                                    labelText: 'Public Key'),
                                maxLines: 3,
                              ),
                              TextField(
                                controller: privateKeyController,
                                decoration: const InputDecoration(
                                    labelText: 'Private Key'),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                  child: const Text('Save'),
                                  onPressed: () {
                                    final cert = CertConfig(
                                      name: nameController.text,
                                      domain: domainController.text,
                                      expired: selectedDate != null
                                          ? DateTime(
                                                      selectedDate!.year,
                                                      selectedDate!.month,
                                                      selectedDate!.day)
                                                  .millisecondsSinceEpoch ~/
                                              1000
                                          : 0,
                                      note: noteController.text,
                                      publicKey: publicKeyController.text,
                                      privateKey: privateKeyController.text,
                                      deploys: existingCert?.deploys ?? [],
                                      id: const Uuid().v4(),
                                      updateAt: DateTime.now()
                                              .millisecondsSinceEpoch ~/
                                          1000,
                                    );
                                    Navigator.of(context).pop(cert);
                                  }),
                              const SizedBox(height: 20)
                            ])))))));
    return res;
  }
}

class CertDetailView extends ConsumerStatefulWidget {
  final String certId;
  const CertDetailView(this.certId, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CertDetailViewState();
}

class _CertDetailViewState extends ConsumerState<CertDetailView> {
  late String certId = widget.certId;
  late CertConfig cert;
  @override
  Widget build(BuildContext context) {
    cert = ref.watch(certsProvider).value?.certs[certId] ?? CertConfig();
    return Scaffold(
        appBar: AppBar(title: const Text('证书详情')),
        floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () => _showDeployForm(context)),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildDetailItem('Id', cert.id),
              _buildDetailItem('Name', cert.name),
              _buildDetailItem('Domain', cert.domain),
              _buildDetailItem('Expired', _formatDate(cert.expired)),
              _buildDetailItem('Note', cert.note),
              _buildCopyableDetailItem(context, 'Public Key', cert.publicKey),
              _buildCopyableDetailItem(context, 'Private Key', cert.privateKey),
              const Text('Deployments',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...cert.deploys
                  .map((deploy) => _buildDeployItem(context, deploy))
                  .toList(),
              const SizedBox(height: 46)
            ])));
  }

  Widget _buildDeployItem(BuildContext context, CertDeploy deploy) {
    return Tooltip(
      message: deploy.address + "\n" + deploy.id,
      waitDuration: const Duration(seconds: 1),
      child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.only(left: 10, right: 5),
          onTap: () => launchUrlString(deploy.address),
          title: Text(deploy.name),
          subtitle: Text(deploy.note),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showDeployForm(context, deploy)),
            IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _confirmDeleteDeploy(context, deploy))
          ])),
    );
  }

  Future<void> _showDeployForm(BuildContext context,
      [CertDeploy? existingDeploy]) async {
    final nameController =
        TextEditingController(text: existingDeploy?.name ?? '');
    final addressController =
        TextEditingController(text: existingDeploy?.address ?? '');
    final noteController =
        TextEditingController(text: existingDeploy?.note ?? '');

    final result = await showDialog<CertDeploy>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(existingDeploy == null
                    ? 'Add Deployment'
                    : 'Edit Deployment'),
                content: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name')),
                  TextField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Address')),
                  TextField(
                      controller: noteController,
                      decoration: const InputDecoration(labelText: 'Note'),
                      maxLines: 3)
                ])),
                actions: [
                  TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop()),
                  TextButton(
                      child: const Text('Save'),
                      onPressed: () {
                        final deploy = CertDeploy(
                          name: nameController.text,
                          address: addressController.text,
                          note: noteController.text,
                        );
                        Navigator.of(context).pop(deploy);
                      })
                ]));

    if (result != null) {
      final updatedDeploys = List<CertDeploy>.from(cert.deploys);
      if (existingDeploy != null) {
        final index = updatedDeploys.indexOf(existingDeploy);
        updatedDeploys[index] = result;
      } else {
        updatedDeploys.add(result);
      }

      await ref
          .read(certsProvider.notifier)
          .set(cert.copyWith(deploys: updatedDeploys));
    }
  }

  Future<void> _confirmDeleteDeploy(
      BuildContext context, CertDeploy deploy) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Confirm Delete'),
                content: const Text(
                    'Are you sure you want to delete this deployment?'),
                actions: [
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  TextButton(
                      child: const Text('Delete'),
                      onPressed: () => Navigator.of(context).pop(true))
                ]));

    if (confirmed == true) {
      final updatedDeploys = List<CertDeploy>.from(cert.deploys)
        ..remove(deploy);
      await ref
          .read(certsProvider.notifier)
          .set(cert.copyWith(deploys: updatedDeploys));
    }
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value)
        ]));
  }

  Widget _buildCopyableDetailItem(
      BuildContext context, String label, String value) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(
              child: Text(value, maxLines: 3, overflow: TextOverflow.ellipsis),
            ),
            IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$label copied to clipboard')),
                  );
                })
          ])
        ]));
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
