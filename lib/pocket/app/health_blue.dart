import 'package:flutter/material.dart';
import 'package:health_kit_reporter/health_kit_reporter.dart';
import 'package:health_kit_reporter/model/payload/category.dart';
import 'package:health_kit_reporter/model/payload/source.dart';
import 'package:health_kit_reporter/model/payload/source_revision.dart';
import 'package:health_kit_reporter/model/predicate.dart';
import 'package:health_kit_reporter/model/type/category_type.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class SexualActivityView extends ConsumerStatefulWidget {
  const SexualActivityView({super.key});

  @override
  _SexualActivityViewState createState() => _SexualActivityViewState();
}

class _SexualActivityViewState extends ConsumerState<SexualActivityView> {
  List<Category> _activities = [];

  @override
  void initState() {
    super.initState();
    _requestAuthorizationAndFetch();
  }

  Future<String> _requestAuthorizationAndFetch() async {
    try {
      final readTypes = <String>[CategoryType.sexualActivity.identifier];
      final writeTypes = <String>[CategoryType.sexualActivity.identifier];
      final isRequested =
          await HealthKitReporter.requestAuthorization(readTypes, writeTypes);
      if (isRequested) {
        await _fetchSexualActivities();
        return "";
      } else {
        return "Authorization not requested";
      }
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
    }
    return "Error";
  }

  Future<void> _fetchSexualActivities() async {
    final now = DateTime.now();
    final threeMonthsAgo = now.subtract(const Duration(days: 90));

    try {
      final activities = await HealthKitReporter.categoryQuery(
          CategoryType.sexualActivity, Predicate(threeMonthsAgo, now));
      setState(() {
        _activities = activities;
      });
    } catch (e) {
      debugPrint('Error fetching sexual activities: $e');
    }
  }

  Future<void> _addSexualActivity(DateTime dateTime) async {
    try {
      final canWrite = await HealthKitReporter.isAuthorizedToWrite(
          CategoryType.sexualActivity.identifier);
      if (canWrite) {
        const _source = Source('CyberMe', 'com.mazhangjing.cyberme');
        const _operatingSystem = OperatingSystem(1, 2, 3);
        const _sourceRevision =
            SourceRevision(_source, null, null, "1.0", _operatingSystem);
        const harmonized = CategoryHarmonized(
            0, "", "", {"HKMetadataKeySexualActivityProtectionUsed": null});
        final data = Category(
            const Uuid().v4(),
            CategoryType.sexualActivity.identifier,
            dateTime.millisecondsSinceEpoch,
            dateTime.millisecondsSinceEpoch,
            null,
            _sourceRevision,
            harmonized);
        debugPrint('try to save: ${data.map}');
        final saved = await HealthKitReporter.save(data);
        debugPrint('data saved: $saved');
      } else {
        debugPrint('error canWrite steps: $canWrite');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _showAddDialog() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final defaultDateTime =
        DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 0);

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text('Add Sexual Activity'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Select date and time:'),
                const SizedBox(height: 20),
                ElevatedButton(
                    child: Text(
                        DateFormat('yyyy-MM-dd HH:mm').format(defaultDateTime)),
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: defaultDateTime,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        final TimeOfDay? timePicked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(defaultDateTime),
                        );
                        if (timePicked != null) {
                          final DateTime selectedDateTime = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            timePicked.hour,
                            timePicked.minute,
                          );
                          Navigator.of(context).pop();
                          _addSexualActivity(selectedDateTime);
                        }
                      }
                    })
              ]));
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Sexual Activity'), actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog)
        ]),
        body: ListView.builder(
            itemCount: _activities.length,
            itemBuilder: (context, index) {
              final activity = _activities[index];
              return ListTile(
                  title: Text(DateFormat('yyyy-MM-dd HH:mm').format(
                      DateTime.fromMillisecondsSinceEpoch(
                          activity.startTimestamp as int))));
            }));
  }
}
