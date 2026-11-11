import 'package:freezed_annotation/freezed_annotation.dart';

part 'life_story_settings.freezed.dart';
part 'life_story_settings.g.dart';

/// Consent for the "life stories" feature (`/life-stories/settings`): whether
/// the agent keeps the memories the user tells, and their voice with them.
@freezed
abstract class LifeStorySettings with _$LifeStorySettings {
  const factory LifeStorySettings({
    /// The memories told during voice sessions are kept.
    @JsonKey(name: 'capture_enabled') @Default(false) bool captureEnabled,

    /// The voice recording is kept too. Only meaningful with [captureEnabled].
    @JsonKey(name: 'keep_audio') @Default(false) bool keepAudio,
  }) = _LifeStorySettings;

  factory LifeStorySettings.fromJson(Map<String, dynamic> json) =>
      _$LifeStorySettingsFromJson(json);
}
