import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:alzheimer_assistant/core/utils/app_logger.dart';

/// A position of the phone. [accuracyMeters] is the radius of uncertainty.
///
/// [headingDegrees] is the direction of the walk measured by the GPS (degrees
/// clockwise from north), not the compass: the phone may be in a pocket. It
/// and [speedMetersPerSecond] are `null` when the phone did not measure them.
class DevicePosition {
  const DevicePosition({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.headingDegrees,
    this.headingAccuracyDegrees,
    this.speedMetersPerSecond,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final double? headingDegrees;
  final double? headingAccuracyDegrees;
  final double? speedMetersPerSecond;
}

/// Position of the phone, used only during a walking guidance while the app is
/// in the foreground. Nothing is stored on the device.
abstract interface class LocationService {
  /// The current position, asking the permission if needed. `null` when the
  /// permission is refused or the position cannot be read.
  Future<DevicePosition?> current();

  /// Positions as the user walks. Empty when the permission is not granted.
  Stream<DevicePosition> positions();
}

class GeolocatorLocationService implements LocationService {
  GeolocatorLocationService({GeolocatorPlatform? geolocator})
      : _geolocator = geolocator ?? GeolocatorPlatform.instance;

  final GeolocatorPlatform _geolocator;

  static const _currentTimeout = Duration(seconds: 10);

  /// A new position every few metres walked.
  static const _streamSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 3,
  );

  final _logger = appLogger;

  Future<bool> _allowed({required bool ask}) async {
    if (!await _geolocator.isLocationServiceEnabled()) {
      _logger.w('[Location] location services are off');
      return false;
    }
    var permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied && ask) {
      permission = await _geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  @override
  Future<DevicePosition?> current() async {
    try {
      if (!await _allowed(ask: true)) return null;
      final position = await _geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _currentTimeout,
        ),
      );
      return _toDevicePosition(position);
    } catch (e) {
      _logger.w('[Location] current position unavailable: ${e.runtimeType}');
      return null;
    }
  }

  @override
  Stream<DevicePosition> positions() async* {
    if (!await _allowed(ask: false)) return;
    yield* _geolocator
        .getPositionStream(locationSettings: _streamSettings)
        .map(_toDevicePosition);
  }

  DevicePosition _toDevicePosition(Position position) {
    // iOS reports an invalid course as a negative value, or with a negative
    // accuracy; Android leaves out what it did not measure (0.0 placeholders).
    final headingAccuracyValid =
        !position.hasHeadingAccuracy || position.headingAccuracy >= 0;
    final headingValid =
        position.hasHeading && position.heading >= 0 && headingAccuracyValid;
    return DevicePosition(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      headingDegrees: headingValid ? position.heading : null,
      headingAccuracyDegrees:
          headingValid && position.hasHeadingAccuracy && position.headingAccuracy > 0
              ? position.headingAccuracy
              : null,
      speedMetersPerSecond:
          position.hasSpeed && position.speed >= 0 ? position.speed : null,
    );
  }
}
