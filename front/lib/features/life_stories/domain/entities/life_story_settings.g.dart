// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'life_story_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LifeStorySettings _$LifeStorySettingsFromJson(Map<String, dynamic> json) =>
    _LifeStorySettings(
      captureEnabled: json['capture_enabled'] as bool? ?? false,
      keepAudio: json['keep_audio'] as bool? ?? false,
    );

Map<String, dynamic> _$LifeStorySettingsToJson(_LifeStorySettings instance) =>
    <String, dynamic>{
      'capture_enabled': instance.captureEnabled,
      'keep_audio': instance.keepAudio,
    };
