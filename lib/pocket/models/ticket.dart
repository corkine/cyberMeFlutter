import 'package:json_annotation/json_annotation.dart';

part 'ticket.g.dart';

@JsonSerializable()
class Ticket {
  final String? message;
  final int? status;
  final List<Data>? data;

  const Ticket({
    this.message,
    this.status,
    this.data,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) => _$TicketFromJson(json);

  Map<String, dynamic> toJson() => _$TicketToJson(this);

  @override
  String toString() {
    return 'Ticket{message: $message, status: $status, data: $data}';
  }
}

@JsonSerializable()
class Data {
  final String? date;
  final String? start;
  final String? end;
  final String? trainNo;
  final String? siteNo;
  final bool? canceled;

  bool get isHistory {
    if (dateTime == null) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return dateTime!.isBefore(today);
  }

  String? get startPretty => start == null
      ? null
      : start!.endsWith("站")
          ? start!.substring(0, start!.length - 1)
          : start!;

  String? get endPretty => end == null
      ? null
      : end!.endsWith("站")
          ? end!.substring(0, end!.length - 1)
          : end!;

  DateTime? get dateTime => date == null ? null : DateTime.tryParse(date!);

  const Data(
      {this.date,
      this.start,
      this.end,
      this.trainNo,
      this.siteNo,
      this.canceled});

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);

  Map<String, dynamic> toJson() => _$DataToJson(this);

  @override
  String toString() {
    return 'Data{date: $date, start: $start, end: $end, trainNo: $trainNo, siteNo: $siteNo, canceled: $canceled}';
  }
}
