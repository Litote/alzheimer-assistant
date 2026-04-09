import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Provides a stable, device-scoped anonymous identifier persisted via
/// [SharedPreferences].
///
/// The ID is generated once (UUID v4) and reused across app restarts and
/// LiveKit reconnections so the backend can maintain per-device session state.
class DeviceIdService {
  static const _key = 'device_id';

  /// Returns the persisted device ID, creating and storing a new UUID v4 on
  /// first call.
  Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null) return existing;
    final id = _generateUuidV4();
    await prefs.setString(_key, id);
    return id;
  }

  static String _generateUuidV4() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant
    final hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
