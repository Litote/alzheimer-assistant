import 'package:freezed_annotation/freezed_annotation.dart';

part 'guidance.freezed.dart';

/// A walking guidance in progress, as decided by the server.
///
/// [instruction] is the exact text of the routing service, shown as is: the
/// direction on screen never depends on what the model says.
@freezed
abstract class Guidance with _$Guidance {
  const factory Guidance({
    required String destination,
    required String instruction,
    @Default('') String maneuver,
    @Default(0) int distanceMeters,
  }) = _Guidance;
}
