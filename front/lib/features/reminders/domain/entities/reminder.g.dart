// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Reminder _$ReminderFromJson(Map<String, dynamic> json) => _Reminder(
  eventId: json['event_id'] as String,
  date: json['date'] as String,
  notifyAt: DateTime.parse(json['notify_at'] as String),
  title: json['title'] as String,
  body: json['body'] as String? ?? '',
);

Map<String, dynamic> _$ReminderToJson(_Reminder instance) => <String, dynamic>{
  'event_id': instance.eventId,
  'date': instance.date,
  'notify_at': instance.notifyAt.toIso8601String(),
  'title': instance.title,
  'body': instance.body,
};

_ReminderRef _$ReminderRefFromJson(Map<String, dynamic> json) => _ReminderRef(
  eventId: json['event_id'] as String,
  date: json['date'] as String,
);

Map<String, dynamic> _$ReminderRefToJson(_ReminderRef instance) =>
    <String, dynamic>{'event_id': instance.eventId, 'date': instance.date};
