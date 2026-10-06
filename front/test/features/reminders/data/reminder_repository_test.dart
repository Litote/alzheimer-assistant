import 'dart:convert';
import 'dart:io';

import 'package:alzheimer_assistant/features/reminders/data/reminder_repository.dart';
import 'package:alzheimer_assistant/features/reminders/domain/entities/reminder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fetchUpcoming() parses reminders with UTC notify_at', () async {
    Uri? capturedUri;
    Map<String, String>? capturedHeaders;
    final repo = ReminderRepository(
      fetchFn: (uri, headers) async {
        capturedUri = uri;
        capturedHeaders = headers;
        return jsonEncode([
          {
            'event_id': 'evt-1',
            'date': '2026-10-01',
            'notify_at': '2026-10-01T07:45:00Z',
            'title': 'Kiné',
            'body': 'À 10:00',
          },
        ]);
      },
      accessTokenProvider: () => 'jwt-123',
    );

    final reminders = await repo.fetchUpcoming(
      supabaseUserId: 'user-1',
      days: 3,
    );

    expect(capturedUri?.path, endsWith('/reminders/upcoming'));
    expect(capturedUri?.queryParameters, {
      'days': '3',
      'supabase_user_id': 'user-1',
    });
    expect(capturedHeaders, {'Authorization': 'Bearer jwt-123'});
    expect(reminders, [
      Reminder(
        eventId: 'evt-1',
        date: '2026-10-01',
        notifyAt: DateTime.utc(2026, 10, 1, 7, 45),
        title: 'Kiné',
        body: 'À 10:00',
      ),
    ]);
    expect(reminders.single.notifyAt.isUtc, isTrue);
    expect(
      reminders.single.ref,
      const ReminderRef(eventId: 'evt-1', date: '2026-10-01'),
    );
  });

  test(
    'fetchUpcoming() omits the user id and auth header when signed out',
    () async {
      Uri? capturedUri;
      Map<String, String>? capturedHeaders;
      final repo = ReminderRepository(
        fetchFn: (uri, headers) async {
          capturedUri = uri;
          capturedHeaders = headers;
          return '[]';
        },
      );

      expect(await repo.fetchUpcoming(), isEmpty);
      expect(capturedUri?.queryParameters, {'days': '7'});
      expect(capturedHeaders, isEmpty);
    },
  );

  test('fetchUpcoming() propagates server errors', () async {
    final repo = ReminderRepository(
      fetchFn: (uri, _) async =>
          throw HttpException('Server error 401', uri: uri),
    );

    expect(repo.fetchUpcoming(), throwsA(isA<HttpException>()));
  });
}
