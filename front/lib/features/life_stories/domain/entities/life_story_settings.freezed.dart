// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'life_story_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LifeStorySettings {

/// The memories told during voice sessions are kept.
@JsonKey(name: 'capture_enabled') bool get captureEnabled;/// The voice recording is kept too. Only meaningful with [captureEnabled].
@JsonKey(name: 'keep_audio') bool get keepAudio;
/// Create a copy of LifeStorySettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LifeStorySettingsCopyWith<LifeStorySettings> get copyWith => _$LifeStorySettingsCopyWithImpl<LifeStorySettings>(this as LifeStorySettings, _$identity);

  /// Serializes this LifeStorySettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LifeStorySettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LifeStorySettings&&(identical(other.captureEnabled, _this.captureEnabled) || other.captureEnabled == _this.captureEnabled)&&(identical(other.keepAudio, _this.keepAudio) || other.keepAudio == _this.keepAudio));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LifeStorySettings;
  return Object.hash(runtimeType,_this.captureEnabled,_this.keepAudio);
}

@override
String toString() {
  final _this = this as LifeStorySettings;
  return 'LifeStorySettings(captureEnabled: ${_this.captureEnabled}, keepAudio: ${_this.keepAudio})';
}


}

/// @nodoc
abstract mixin class $LifeStorySettingsCopyWith<$Res>  {
  factory $LifeStorySettingsCopyWith(LifeStorySettings value, $Res Function(LifeStorySettings) _then) = _$LifeStorySettingsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'capture_enabled') bool captureEnabled,@JsonKey(name: 'keep_audio') bool keepAudio
});




}
/// @nodoc
class _$LifeStorySettingsCopyWithImpl<$Res>
    implements $LifeStorySettingsCopyWith<$Res> {
  _$LifeStorySettingsCopyWithImpl(this._self, this._then);

  final LifeStorySettings _self;
  final $Res Function(LifeStorySettings) _then;

/// Create a copy of LifeStorySettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? captureEnabled = null,Object? keepAudio = null,}) {
  return _then(LifeStorySettings(
captureEnabled: null == captureEnabled ? _self.captureEnabled : captureEnabled // ignore: cast_nullable_to_non_nullable
as bool,keepAudio: null == keepAudio ? _self.keepAudio : keepAudio // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LifeStorySettings].
extension LifeStorySettingsPatterns on LifeStorySettings {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LifeStorySettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LifeStorySettings() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LifeStorySettings value)  $default,){
final _that = this;
switch (_that) {
case _LifeStorySettings():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LifeStorySettings value)?  $default,){
final _that = this;
switch (_that) {
case _LifeStorySettings() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'capture_enabled')  bool captureEnabled, @JsonKey(name: 'keep_audio')  bool keepAudio)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LifeStorySettings() when $default != null:
return $default(_that.captureEnabled,_that.keepAudio);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'capture_enabled')  bool captureEnabled, @JsonKey(name: 'keep_audio')  bool keepAudio)  $default,) {final _that = this;
switch (_that) {
case _LifeStorySettings():
return $default(_that.captureEnabled,_that.keepAudio);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'capture_enabled')  bool captureEnabled, @JsonKey(name: 'keep_audio')  bool keepAudio)?  $default,) {final _that = this;
switch (_that) {
case _LifeStorySettings() when $default != null:
return $default(_that.captureEnabled,_that.keepAudio);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LifeStorySettings implements LifeStorySettings {
  const _LifeStorySettings({@JsonKey(name: 'capture_enabled') this.captureEnabled = false, @JsonKey(name: 'keep_audio') this.keepAudio = false});
  factory _LifeStorySettings.fromJson(Map<String, dynamic> json) => _$LifeStorySettingsFromJson(json);

/// The memories told during voice sessions are kept.
@override@JsonKey(name: 'capture_enabled') final  bool captureEnabled;
/// The voice recording is kept too. Only meaningful with [captureEnabled].
@override@JsonKey(name: 'keep_audio') final  bool keepAudio;

/// Create a copy of LifeStorySettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LifeStorySettingsCopyWith<_LifeStorySettings> get copyWith => __$LifeStorySettingsCopyWithImpl<_LifeStorySettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LifeStorySettingsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LifeStorySettings&&(identical(other.captureEnabled, captureEnabled) || other.captureEnabled == captureEnabled)&&(identical(other.keepAudio, keepAudio) || other.keepAudio == keepAudio));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,captureEnabled,keepAudio);
}

@override
String toString() {
    return 'LifeStorySettings(captureEnabled: $captureEnabled, keepAudio: $keepAudio)';
}


}

/// @nodoc
abstract mixin class _$LifeStorySettingsCopyWith<$Res> implements $LifeStorySettingsCopyWith<$Res> {
  factory _$LifeStorySettingsCopyWith(_LifeStorySettings value, $Res Function(_LifeStorySettings) _then) = __$LifeStorySettingsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'capture_enabled') bool captureEnabled,@JsonKey(name: 'keep_audio') bool keepAudio
});




}
/// @nodoc
class __$LifeStorySettingsCopyWithImpl<$Res>
    implements _$LifeStorySettingsCopyWith<$Res> {
  __$LifeStorySettingsCopyWithImpl(this._self, this._then);

  final _LifeStorySettings _self;
  final $Res Function(_LifeStorySettings) _then;

/// Create a copy of LifeStorySettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? captureEnabled = null,Object? keepAudio = null,}) {
  return _then(_LifeStorySettings(
captureEnabled: null == captureEnabled ? _self.captureEnabled : captureEnabled // ignore: cast_nullable_to_non_nullable
as bool,keepAudio: null == keepAudio ? _self.keepAudio : keepAudio // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
