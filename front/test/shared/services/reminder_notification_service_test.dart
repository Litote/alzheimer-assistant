import 'package:alzheimer_assistant/features/reminders/domain/entities/reminder.dart';
import 'package:alzheimer_assistant/shared/services/reminder_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const reminder = ReminderRef(eventId: 'evt-1', date: '2026-10-01');

  test('payload round-trips and invalid payloads are ignored', () {
    final payload = ReminderNotificationService.encodePayload(reminder);

    expect(ReminderNotificationService.decodePayload(payload), reminder);
    expect(ReminderNotificationService.decodePayload(null), isNull);
    expect(ReminderNotificationService.decodePayload(''), isNull);
    expect(ReminderNotificationService.decodePayload('not json'), isNull);
    expect(
      ReminderNotificationService.decodePayload('{"event_id": 1}'),
      isNull,
    );
  });

  test(
    'notification ids are stable, positive 32-bit and differ per occurrence',
    () {
      final id = ReminderNotificationService.notificationId(reminder);

      expect(id, ReminderNotificationService.notificationId(reminder));
      expect(id, inInclusiveRange(0, 0x7fffffff));
      expect(
        ReminderNotificationService.notificationId(
          const ReminderRef(eventId: 'evt-1', date: '2026-10-02'),
        ),
        isNot(id),
      );
    },
  );

  test('a tap received before a handler is set is delivered once set', () {
    final service = ReminderNotificationService();
    final received = <ReminderRef>[];

    service.handleTap(ReminderNotificationService.encodePayload(reminder));
    service.tapHandler = received.add;
    service.tapHandler = received.add;

    expect(received, [reminder]);
  });

  test('taps go straight to the handler when one is set', () {
    final service = ReminderNotificationService();
    final received = <ReminderRef>[];
    service.tapHandler = received.add;

    service.handleTap(ReminderNotificationService.encodePayload(reminder));
    service.handleTap('garbage');

    expect(received, [reminder]);
  });
}
