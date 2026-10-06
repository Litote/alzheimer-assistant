import 'dart:async';

import 'package:alzheimer_assistant/features/reminders/data/reminder_repository.dart';
import 'package:alzheimer_assistant/features/reminders/domain/entities/reminder.dart';
import 'package:alzheimer_assistant/shared/services/reminder_notification_service.dart';
import 'package:alzheimer_assistant/shared/services/reminder_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements ReminderRepository {}

class _MockNotifications extends Mock implements ReminderNotificationService {}

final _reminder = Reminder(
  eventId: 'evt-1',
  date: '2026-10-01',
  notifyAt: DateTime.utc(2026, 10, 1, 7, 45),
  title: 'Kiné',
);

void main() {
  late _MockRepository repository;
  late _MockNotifications notifications;
  late ReminderScheduler scheduler;

  setUp(() {
    repository = _MockRepository();
    notifications = _MockNotifications();
    when(() => notifications.requestPermissions()).thenAnswer((_) async {});
    when(() => notifications.replaceAll(any())).thenAnswer((_) async {});
    scheduler = ReminderScheduler(
      repository: repository,
      notifications: notifications,
      supabaseUserIdProvider: () => 'user-1',
    );
  });

  test(
    'sync() asks permissions then replaces notifications with the agenda',
    () async {
      when(
        () => repository.fetchUpcoming(supabaseUserId: 'user-1'),
      ).thenAnswer((_) async => [_reminder]);

      await scheduler.sync();

      verifyInOrder([
        () => notifications.requestPermissions(),
        () => repository.fetchUpcoming(supabaseUserId: 'user-1'),
        () => notifications.replaceAll([_reminder]),
      ]);
    },
  );

  test(
    'sync() keeps scheduled notifications when the agenda is unreachable',
    () async {
      when(
        () => repository.fetchUpcoming(supabaseUserId: 'user-1'),
      ).thenThrow(Exception('offline'));

      await scheduler.sync();

      verifyNever(() => notifications.replaceAll(any()));
    },
  );

  test('concurrent sync() calls share the same run', () async {
    final pending = Completer<List<Reminder>>();
    when(
      () => repository.fetchUpcoming(supabaseUserId: 'user-1'),
    ).thenAnswer((_) => pending.future);

    final first = scheduler.sync();
    final second = scheduler.sync();
    pending.complete([_reminder]);
    await Future.wait([first, second]);

    verify(() => repository.fetchUpcoming(supabaseUserId: 'user-1')).called(1);
    verify(() => notifications.replaceAll([_reminder])).called(1);
  });
}
