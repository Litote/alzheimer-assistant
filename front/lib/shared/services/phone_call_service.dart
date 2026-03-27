import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:logger/logger.dart';

typedef PhoneCandidate = ({String displayName, String number});

sealed class PhoneCallResult {}

class PhoneCallSuccess extends PhoneCallResult {}

class PhoneCallError extends PhoneCallResult {
  PhoneCallError(this.message);
  final String message;
}

class PhoneCallAmbiguous extends PhoneCallResult {
  PhoneCallAmbiguous(this.candidates);
  final List<PhoneCandidate> candidates;
}

class PhoneCallService {
  PhoneCallService({
    Future<PermissionStatus> Function()? requestPermission,
    Future<List<Contact>> Function()? getContacts,
    Future<bool?> Function(String)? callNumber,
  })  : _requestPermission = requestPermission ?? _defaultRequestPermission,
        _getContacts = getContacts ?? _defaultGetContacts,
        _callNumber = callNumber ?? FlutterPhoneDirectCaller.callNumber;

  static Future<PermissionStatus> _defaultRequestPermission() =>
      FlutterContacts.permissions.request(PermissionType.read);

  static Future<List<Contact>> _defaultGetContacts() =>
      FlutterContacts.getAll(properties: {ContactProperty.phone});

  final _logger = Logger();
  final Future<PermissionStatus> Function() _requestPermission;
  final Future<List<Contact>> Function() _getContacts;
  final Future<bool?> Function(String) _callNumber;

  /// Looks up [name] in contacts and initiates the call.
  ///
  /// When [exactMatch] is true, only contacts whose display name equals [name]
  /// (case-insensitive) are considered. If multiple exact matches exist the
  /// first one is used — this handles accented/unaccented variants that the
  /// substring search would conflate (e.g. "Fred" vs "Frederic").
  ///
  /// Returns [PhoneCallSuccess], [PhoneCallError] or [PhoneCallAmbiguous].
  Future<PhoneCallResult> callByName(String name, {bool exactMatch = false}) async {
    _logger.i('[Phone] Looking up contact: "$name"${exactMatch ? ' (exactMatch)' : ''}');

    final status = await _requestPermission();
    final hasPermission = status == PermissionStatus.granted;
    if (!hasPermission) {
      _logger.w('[Phone] Contacts permission denied');
      return PhoneCallError("Je n'ai pas la permission d'accéder aux contacts.");
    }

    final allContacts = await _getContacts();
    final nameLower = name.toLowerCase();
    final contacts = allContacts
        .where((c) {
          final displayLower = c.displayName?.toLowerCase() ?? '';
          return exactMatch
              ? displayLower == nameLower
              : displayLower.contains(nameLower);
        })
        .toList();

    if (contacts.isEmpty) {
      _logger.w('[Phone] No contact found for "$name"');
      return PhoneCallError("Je n'ai pas trouvé $name dans vos contacts.");
    }

    // With exactMatch, multiple hits mean the user said exactly the right name
    // but several contacts share it — take the first one rather than asking
    // for disambiguation again.
    if (contacts.length > 1 && !exactMatch) {
      final candidates = contacts
          .where((c) => c.phones.isNotEmpty)
          .map((c) => (
                displayName: c.displayName ?? c.phones.first.number,
                number: c.phones.first.number.replaceAll(RegExp(r'[\s\-.()\u00A0]'), ''),
              ))
          .toList();
      if (candidates.isEmpty) {
        return PhoneCallError("Les contacts trouvés n'ont pas de numéro enregistré.");
      }
      _logger.i('[Phone] ${candidates.length} contacts found for "$name"');
      return PhoneCallAmbiguous(candidates);
    }

    final contact = contacts.first;
    if (contact.phones.isEmpty) {
      _logger.w('[Phone] Contact found but has no number: ${contact.displayName}');
      return PhoneCallError("${contact.displayName} n'a pas de numéro de téléphone enregistré.");
    }

    final number = contact.phones.first.number.replaceAll(RegExp(r'[\s\-.()\u00A0]'), '');
    return callByNumber(number, displayName: contact.displayName);
  }

  /// Directly initiates a call to [number].
  Future<PhoneCallResult> callByNumber(String number, {String? displayName}) async {
    final label = displayName ?? number;
    _logger.i('[Phone] Calling $label → $number');
    final called = await _callNumber(number);
    if (called == true) {
      return PhoneCallSuccess();
    }
    _logger.e('[Phone] Failed to initiate call to $number');
    return PhoneCallError("Je n'ai pas pu lancer l'appel vers $label.");
  }
}
