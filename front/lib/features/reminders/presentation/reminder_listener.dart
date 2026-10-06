import 'dart:async';

import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_event.dart';
import 'package:alzheimer_assistant/shared/services/auth_service.dart';
import 'package:alzheimer_assistant/shared/services/reminder_notification_service.dart';
import 'package:alzheimer_assistant/shared/services/reminder_scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Schedules reminder notifications while signed in, and opens a session
/// announcing the event when one is tapped.
///
/// Notifications are re-synced on every auth change (sign-in, app start) and
/// every time the app comes back to the foreground.
class ReminderListener extends StatefulWidget {
  const ReminderListener({
    required this.authService,
    required this.notifications,
    required this.scheduler,
    required this.child,
    super.key,
  });

  final AuthService authService;
  final ReminderNotificationService notifications;
  final ReminderScheduler scheduler;
  final Widget child;

  @override
  State<ReminderListener> createState() => _ReminderListenerState();
}

class _ReminderListenerState extends State<ReminderListener>
    with WidgetsBindingObserver {
  StreamSubscription<dynamic>? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSubscription = widget.authService.authStateChanges.listen(
      (_) => _sync(),
    );
    widget.notifications.tapHandler = (reminder) {
      if (!widget.authService.isSignedIn) return;
      context.read<AssistantBloc>().add(
        AssistantEvent.reminderOpened(reminder),
      );
    };
    _sync();
  }

  @override
  void dispose() {
    widget.notifications.tapHandler = null;
    _authSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sync();
  }

  void _sync() {
    if (widget.authService.isSignedIn) widget.scheduler.sync().ignore();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
