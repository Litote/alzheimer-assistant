import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alzheimer_assistant/shared/services/device_id_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('getOrCreate returns a non-empty string', () async {
    final id = await DeviceIdService().getOrCreate();
    expect(id, isNotEmpty);
  });

  test('getOrCreate returns a valid UUID v4 format', () async {
    final id = await DeviceIdService().getOrCreate();
    final uuidPattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    expect(uuidPattern.hasMatch(id), isTrue, reason: 'Expected UUID v4, got: $id');
  });

  test('getOrCreate returns the same ID on subsequent calls', () async {
    final service = DeviceIdService();
    final first = await service.getOrCreate();
    final second = await service.getOrCreate();
    expect(second, equals(first));
  });

  test('ID is stable across separate DeviceIdService instances', () async {
    final id1 = await DeviceIdService().getOrCreate();
    final id2 = await DeviceIdService().getOrCreate();
    expect(id2, equals(id1));
  });

  test('generates distinct IDs when storage is cleared between calls', () async {
    final id1 = await DeviceIdService().getOrCreate();
    SharedPreferences.setMockInitialValues({});
    final id2 = await DeviceIdService().getOrCreate();
    expect(id2, isNot(equals(id1)));
  });
}
