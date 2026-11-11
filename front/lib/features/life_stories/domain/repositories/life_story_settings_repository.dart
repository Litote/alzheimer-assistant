import 'package:alzheimer_assistant/features/life_stories/domain/entities/life_story_settings.dart';

/// Reads and changes the life story consent of the signed-in user.
///
/// The caregiver back-office changes the same settings: always [fetch] before
/// showing them. Both methods throw when the server cannot be reached.
abstract interface class LifeStorySettingsRepository {
  Future<LifeStorySettings> fetch();

  /// Returns the settings as stored (the server turns the voice off when
  /// capture is off).
  Future<LifeStorySettings> save(LifeStorySettings settings);
}
