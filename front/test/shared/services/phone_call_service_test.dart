import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alzheimer_assistant/shared/services/phone_call_service.dart';

// ── Helpers ─────────────────────────────────────────────────────────────────

PhoneCallService _makeService({
  Future<PermissionStatus> Function()? requestPermission,
  Future<List<Contact>> Function()? getContacts,
  Future<bool?> Function(String)? callNumber,
}) =>
    PhoneCallService(
      requestPermission: requestPermission,
      getContacts: getContacts,
      callNumber: callNumber,
    );

Future<PermissionStatus> _granted() async => PermissionStatus.granted;
Future<PermissionStatus> _denied() async => PermissionStatus.denied;
Future<bool?> _callSuccess(String _) async => true;
Future<bool?> _callFailure(String _) async => false;

Contact _contact(String name, [String number = '+33600000000']) =>
    Contact(displayName: name, phones: [Phone(number: number)]);

Contact _contactNoPhone(String name) => Contact(displayName: name);

void main() {
  // ── callByName: permission denied ──────────────────────────────────────────

  test('callByName: permission denied → PhoneCallError', () async {
    final service = _makeService(requestPermission: _denied);

    final result = await service.callByName('Maman');

    expect(result, isA<PhoneCallError>());
    expect(
      (result as PhoneCallError).message,
      "Je n'ai pas la permission d'accéder aux contacts.",
    );
  });

  // ── callByName: no contact found ──────────────────────────────────────────

  test('callByName: no contact found → PhoneCallError', () async {
    final service = _makeService(
      requestPermission: _granted,
      getContacts: () async => [],
    );

    final result = await service.callByName('Maman');

    expect(result, isA<PhoneCallError>());
    expect(
      (result as PhoneCallError).message,
      contains('Maman'),
    );
  });

  // ── callByName: one contact, no phone ─────────────────────────────────────

  test('callByName: contact has no phone → PhoneCallError', () async {
    final service = _makeService(
      requestPermission: _granted,
      getContacts: () async => [_contactNoPhone('Maman')],
    );

    final result = await service.callByName('Maman');

    expect(result, isA<PhoneCallError>());
    expect(
      (result as PhoneCallError).message,
      contains('numéro'),
    );
  });

  // ── callByName: one contact, call succeeds ────────────────────────────────

  test('callByName: one contact → calls number → PhoneCallSuccess', () async {
    final service = _makeService(
      requestPermission: _granted,
      getContacts: () async => [_contact('Maman', '+33612345678')],
      callNumber: _callSuccess,
    );

    final result = await service.callByName('Maman');

    expect(result, isA<PhoneCallSuccess>());
  });

  // ── callByName: one contact, call fails ───────────────────────────────────

  test('callByName: one contact → call fails → PhoneCallError', () async {
    final service = _makeService(
      requestPermission: _granted,
      getContacts: () async => [_contact('Maman', '+33612345678')],
      callNumber: _callFailure,
    );

    final result = await service.callByName('Maman');

    expect(result, isA<PhoneCallError>());
    expect((result as PhoneCallError).message, contains('appel'));
  });

  // ── callByName: multiple contacts with phones ─────────────────────────────

  test('callByName: multiple contacts with phones → PhoneCallAmbiguous', () async {
    final service = _makeService(
      requestPermission: _granted,
      getContacts: () async => [
        _contact('Martin Jean', '+33611111111'),
        _contact('Martin Paul', '+33622222222'),
      ],
    );

    final result = await service.callByName('Martin');

    expect(result, isA<PhoneCallAmbiguous>());
    final ambiguous = result as PhoneCallAmbiguous;
    expect(ambiguous.candidates.length, 2);
    expect(ambiguous.candidates[0].displayName, 'Martin Jean');
    expect(ambiguous.candidates[1].displayName, 'Martin Paul');
  });

  // ── callByName: multiple contacts but none have phones ────────────────────

  test('callByName: multiple contacts but no phones → PhoneCallError', () async {
    final service = _makeService(
      requestPermission: _granted,
      getContacts: () async => [
        _contactNoPhone('Martin Jean'),
        _contactNoPhone('Martin Paul'),
      ],
    );

    final result = await service.callByName('Martin');

    expect(result, isA<PhoneCallError>());
  });

  // ── callByName: phone number normalisation ────────────────────────────────

  test('callByName: number with spaces and dashes is normalised', () async {
    String? dialledNumber;
    final service = _makeService(
      requestPermission: _granted,
      getContacts: () async => [_contact('Maman', '06 12 34 56 78')],
      callNumber: (n) async {
        dialledNumber = n;
        return true;
      },
    );

    await service.callByName('Maman');

    expect(dialledNumber, '0612345678');
  });

  // ── callByName: exactMatch=true — exact name wins ─────────────────────────
  //
  // Scenario: contacts are "Fred" and "Frederic". User said "Fred" after
  // disambiguation. Agent sends call_phone(name:"Fred", exactMatch:true).
  // Substring search would return both; exact match returns only "Fred".

  test('callByName exactMatch: exact name selected among substring candidates', () async {
    final service = _makeService(
      requestPermission: _granted,
      getContacts: () async => [
        _contact('Fred', '+33611111111'),
        _contact('Frederic', '+33622222222'),
      ],
      callNumber: _callSuccess,
    );

    final result = await service.callByName('Fred', exactMatch: true);

    expect(result, isA<PhoneCallSuccess>());
  });

  test('callByName exactMatch: multiple exact-name contacts → first one called', () async {
    String? dialledNumber;
    final service = _makeService(
      requestPermission: _granted,
      getContacts: () async => [
        _contact('Fred', '+33611111111'),
        _contact('Fred', '+33622222222'),
      ],
      callNumber: (n) async {
        dialledNumber = n;
        return true;
      },
    );

    final result = await service.callByName('Fred', exactMatch: true);

    expect(result, isA<PhoneCallSuccess>());
    expect(dialledNumber, '+33611111111');
  });

  test('callByName exactMatch: no exact match → PhoneCallError', () async {
    final service = _makeService(
      requestPermission: _granted,
      getContacts: () async => [
        _contact('Frederic', '+33622222222'),
      ],
    );

    final result = await service.callByName('Fred', exactMatch: true);

    expect(result, isA<PhoneCallError>());
  });

  // ── callByNumber: success ─────────────────────────────────────────────────

  test('callByNumber: called returns true → PhoneCallSuccess', () async {
    final service = _makeService(callNumber: _callSuccess);

    final result = await service.callByNumber('+33612345678');

    expect(result, isA<PhoneCallSuccess>());
  });

  // ── callByNumber: failure ─────────────────────────────────────────────────

  test('callByNumber: called returns false → PhoneCallError', () async {
    final service = _makeService(callNumber: _callFailure);

    final result = await service.callByNumber('+33612345678', displayName: 'Maman');

    expect(result, isA<PhoneCallError>());
    expect((result as PhoneCallError).message, contains('Maman'));
  });
}
