import 'package:freezed_annotation/freezed_annotation.dart';

part 'reminder.freezed.dart';
part 'reminder.g.dart';

/// An upcoming event notification, as returned by `GET /reminders/upcoming`.
@freezed
abstract class Reminder with _$Reminder {
  const Reminder._();

  const factory Reminder({
    @JsonKey(name: 'event_id') required String eventId,

    /// Occurrence date (`YYYY-MM-DD`) — recurring events have one per day.
    required String date,

    /// When the notification must fire (UTC).
    @JsonKey(name: 'notify_at') required DateTime notifyAt,
    required String title,
    @Default('') String body,
  }) = _Reminder;

  factory Reminder.fromJson(Map<String, dynamic> json) =>
      _$ReminderFromJson(json);

  ReminderRef get ref => ReminderRef(eventId: eventId, date: date);
}

/// The event occurrence a tapped notification refers to. Sent to the agent
/// when opening the session so that it announces the event first.
@freezed
abstract class ReminderRef with _$ReminderRef {
  const factory ReminderRef({
    @JsonKey(name: 'event_id') required String eventId,
    required String date,
  }) = _ReminderRef;

  factory ReminderRef.fromJson(Map<String, dynamic> json) =>
      _$ReminderRefFromJson(json);
}
