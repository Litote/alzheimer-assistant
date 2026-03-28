import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionService {
  static const _onboardingKey = 'onboarding_done';

  PermissionService({
    Future<Map<Permission, PermissionStatus>> Function()? requestPermissions,
  }) : _requestPermissions =
           requestPermissions ?? _defaultRequestPermissions;

  final Future<Map<Permission, PermissionStatus>> Function() _requestPermissions;

  // iOS needs speech recognition instead of phone-dialer permission (not applicable on iOS).
  static final _permissions = Platform.isIOS
      ? [Permission.microphone, Permission.contacts, Permission.speech]
      : [Permission.microphone, Permission.contacts, Permission.phone];

  static Future<Map<Permission, PermissionStatus>> _defaultRequestPermissions() =>
      _permissions.request();

  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> markOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  Future<Map<Permission, PermissionStatus>> requestAll() =>
      _requestPermissions();
}
