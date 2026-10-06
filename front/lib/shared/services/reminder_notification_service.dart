import 'dart:convert';

import 'package:alzheimer_assistant/core/utils/app_logger.dart';
import 'package:alzheimer_assistant/features/reminders/domain/entities/reminder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

const _channelId = 'reminders';
const _channelName = 'Rappels';
const _exactAlarmAskedKey = 'exact_alarm_permission_asked';

/// Thin wrapper around [FlutterLocalNotificationsPlugin] for event reminders.
///
/// Taps are delivered to [tapHandler]. A tap received before a handler is set
/// (e.g. the notification launched the app) is kept and delivered as soon as
/// one is set.
class ReminderNotificationService {
  ReminderNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _logger = appLogger;
  ReminderRef? _pendingTap;
  void Function(ReminderRef)? _tapHandler;
  bool _initialized = false;

  /// Must be called once, before [runApp].
  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permissions are requested by [requestPermissions], once signed in.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) => _onTap(response.payload),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Rappels des rendez-vous et activités',
            importance: Importance.high,
          ),
        );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _onTap(launch!.notificationResponse?.payload);
    }
    _initialized = true;
  }

  set tapHandler(void Function(ReminderRef)? handler) {
    _tapHandler = handler;
    final pending = _pendingTap;
    if (handler != null && pending != null) {
      _pendingTap = null;
      handler(pending);
    }
  }

  /// Asks for the notification permission (no-op once answered). On Android,
  /// also opens the "Alarms & reminders" setting once, so that reminders fire
  /// on time even when the phone is idle.
  Future<void> requestPermissions() async {
    if (!_initialized) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, sound: true);
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;
    await android.requestNotificationsPermission();
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_exactAlarmAskedKey) ?? false) &&
        !(await android.canScheduleExactNotifications() ?? true)) {
      await prefs.setBool(_exactAlarmAskedKey, true);
      await android.requestExactAlarmsPermission();
    }
  }

  /// Replaces every scheduled notification with [reminders].
  Future<void> replaceAll(List<Reminder> reminders) async {
    if (!_initialized) return;
    final canExact =
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.canScheduleExactNotifications() ??
        true;
    await _plugin.cancelAll();
    for (final reminder in reminders) {
      await _plugin.zonedSchedule(
        id: notificationId(reminder.ref),
        title: reminder.title,
        body: reminder.body,
        scheduledDate: tz.TZDateTime.from(reminder.notifyAt, tz.UTC),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
          ),
          iOS: DarwinNotificationDetails(
            // Breaks through Focus modes once the "Time Sensitive
            // Notifications" capability is enabled in Xcode.
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        androidScheduleMode: canExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: encodePayload(reminder.ref),
      );
    }
    _logger.i(
      '[Reminders] ${reminders.length} notification(s) scheduled (exact: $canExact)',
    );
  }

  void _onTap(String? payload) {
    final reminder = decodePayload(payload);
    if (reminder == null) return;
    _logger.i('[Reminders] Notification tapped: ${reminder.eventId}');
    final handler = _tapHandler;
    if (handler == null) {
      _pendingTap = reminder;
    } else {
      handler(reminder);
    }
  }

  /// Simulates a tap, for tests.
  @visibleForTesting
  void handleTap(String? payload) => _onTap(payload);

  @visibleForTesting
  static String encodePayload(ReminderRef reminder) =>
      jsonEncode(reminder.toJson());

  @visibleForTesting
  static ReminderRef? decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      return ReminderRef.fromJson(jsonDecode(payload) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Stable 31-bit id (FNV-1a) — [String.hashCode] differs between runs.
  @visibleForTesting
  static int notificationId(ReminderRef reminder) {
    var hash = 0x811c9dc5;
    for (final unit in utf8.encode('${reminder.eventId}|${reminder.date}')) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }
}
