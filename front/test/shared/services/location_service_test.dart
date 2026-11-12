import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:alzheimer_assistant/shared/services/location_service.dart';

class MockGeolocator extends Mock implements GeolocatorPlatform {}

Position _position(double latitude, double longitude, {double accuracy = 8}) =>
    Position(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      timestamp: DateTime.utc(2026, 11, 12),
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  late MockGeolocator geolocator;
  late GeolocatorLocationService service;

  setUp(() {
    geolocator = MockGeolocator();
    service = GeolocatorLocationService(geolocator: geolocator);
    when(() => geolocator.isLocationServiceEnabled())
        .thenAnswer((_) async => true);
    when(() => geolocator.checkPermission())
        .thenAnswer((_) async => LocationPermission.whileInUse);
    when(() => geolocator.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        )).thenAnswer((_) async => _position(46.52, 6.63));
  });

  group('current', () {
    test('returns the position of the phone', () async {
      final position = await service.current();

      expect(position!.latitude, 46.52);
      expect(position.longitude, 6.63);
      expect(position.accuracyMeters, 8);
      verifyNever(() => geolocator.requestPermission());
    });

    test('asks the permission when it was never answered', () async {
      when(() => geolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.denied);
      when(() => geolocator.requestPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);

      expect(await service.current(), isNotNull);
      verify(() => geolocator.requestPermission()).called(1);
    });

    test('returns null when the permission is refused', () async {
      when(() => geolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.denied);
      when(() => geolocator.requestPermission())
          .thenAnswer((_) async => LocationPermission.deniedForever);

      expect(await service.current(), isNull);
      verifyNever(() => geolocator.getCurrentPosition(
            locationSettings: any(named: 'locationSettings'),
          ));
    });

    test('returns null when location services are off', () async {
      when(() => geolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => false);

      expect(await service.current(), isNull);
      verifyNever(() => geolocator.checkPermission());
    });

    test('returns null when the position cannot be read in time', () async {
      when(() => geolocator.getCurrentPosition(
            locationSettings: any(named: 'locationSettings'),
          )).thenThrow(TimeoutException('no fix'));

      expect(await service.current(), isNull);
    });
  });

  group('positions', () {
    test('streams the positions as the user walks', () async {
      when(() => geolocator.getPositionStream(
            locationSettings: any(named: 'locationSettings'),
          )).thenAnswer(
        (_) => Stream.fromIterable([_position(1, 2), _position(3, 4, accuracy: 20)]),
      );

      final positions = await service.positions().toList();

      expect(positions.map((p) => (p.latitude, p.longitude, p.accuracyMeters)),
          [(1.0, 2.0, 8.0), (3.0, 4.0, 20.0)]);
      final settings = verify(() => geolocator.getPositionStream(
            locationSettings: captureAny(named: 'locationSettings'),
          )).captured.single as LocationSettings;
      expect(settings.accuracy, LocationAccuracy.high);
      expect(settings.distanceFilter, 3);
    });

    test('is empty, without asking, when the permission is not granted',
        () async {
      when(() => geolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.denied);

      expect(await service.positions().toList(), isEmpty);
      verifyNever(() => geolocator.requestPermission());
      verifyNever(() => geolocator.getPositionStream(
            locationSettings: any(named: 'locationSettings'),
          ));
    });
  });
}
