// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Ticket _$TicketFromJson(Map<String, dynamic> json) => Ticket(
      message: json['message'] as String?,
      status: (json['status'] as num?)?.toInt(),
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => Data.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TicketToJson(Ticket instance) => <String, dynamic>{
      'message': instance.message,
      'status': instance.status,
      'data': instance.data,
    };

Data _$DataFromJson(Map<String, dynamic> json) => Data(
      date: json['date'] as String?,
      start: json['start'] as String?,
      end: json['end'] as String?,
      trainNo: json['trainNo'] as String?,
      siteNo: json['siteNo'] as String?,
      canceled: json['canceled?'] as bool?,
    );

Map<String, dynamic> _$DataToJson(Data instance) => <String, dynamic>{
      'date': instance.date,
      'start': instance.start,
      'end': instance.end,
      'trainNo': instance.trainNo,
      'siteNo': instance.siteNo,
      'canceled?': instance.canceled,
    };
