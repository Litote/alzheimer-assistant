import 'package:alzheimer_assistant/core/utils/app_logger.dart';
import 'package:alzheimer_assistant/features/reminders/data/reminder_repository.dart';
import 'package:alzheimer_assistant/shared/services/reminder_notification_service.dart';

/// Keeps the scheduled notifications in sync with the agenda.
///
/// Called when the user signs in and every time the app comes back to the
/// foreground: events added by the caregiver are only scheduled then.
class ReminderScheduler {
  ReminderScheduler({
    required ReminderRepository repository,
    required ReminderNotificationService notifications,
    required String Function() supabaseUserIdProvider,
  }) : _repository = repository,
       _notifications = notifications,
       _supabaseUserIdProvider = supabaseUserIdProvider;

  final ReminderRepository _repository;
  final ReminderNotificationService _notifications;
  final String Function() _supabaseUserIdProvider;
  final _logger = appLogger;
  Future<void>? _running;

  /// Concurrent calls share the sync in progress.
  Future<void> sync() =>
      _running ??= _sync().whenComplete(() => _running = null);

  Future<void> _sync() async {
    try {
      await _notifications.requestPermissions();
      final reminders = await _repository.fetchUpcoming(
        supabaseUserId: _supabaseUserIdProvider(),
      );
      await _notifications.replaceAll(reminders);
    } catch (e) {
      // Keep the notifications already scheduled (e.g. offline).
      _logger.w('[Reminders] Sync failed: $e');
    }
  }
}
