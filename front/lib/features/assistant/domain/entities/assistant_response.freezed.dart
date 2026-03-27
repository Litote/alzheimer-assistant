// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'assistant_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AssistantResponse {

 String get text; List<int> get audioBytes; String? get callPhoneName; bool get callPhoneExactMatch;
/// Create a copy of AssistantResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssistantResponseCopyWith<AssistantResponse> get copyWith => _$AssistantResponseCopyWithImpl<AssistantResponse>(this as AssistantResponse, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssistantResponse&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other.audioBytes, audioBytes)&&(identical(other.callPhoneName, callPhoneName) || other.callPhoneName == callPhoneName)&&(identical(other.callPhoneExactMatch, callPhoneExactMatch) || other.callPhoneExactMatch == callPhoneExactMatch));
}


@override
int get hashCode => Object.hash(runtimeType,text,const DeepCollectionEquality().hash(audioBytes),callPhoneName,callPhoneExactMatch);

@override
String toString() {
  return 'AssistantResponse(text: $text, audioBytes: $audioBytes, callPhoneName: $callPhoneName, callPhoneExactMatch: $callPhoneExactMatch)';
}


}

/// @nodoc
abstract mixin class $AssistantResponseCopyWith<$Res>  {
  factory $AssistantResponseCopyWith(AssistantResponse value, $Res Function(AssistantResponse) _then) = _$AssistantResponseCopyWithImpl;
@useResult
$Res call({
 String text, List<int> audioBytes, String? callPhoneName, bool callPhoneExactMatch
});




}
/// @nodoc
class _$AssistantResponseCopyWithImpl<$Res>
    implements $AssistantResponseCopyWith<$Res> {
  _$AssistantResponseCopyWithImpl(this._self, this._then);

  final AssistantResponse _self;
  final $Res Function(AssistantResponse) _then;

/// Create a copy of AssistantResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? audioBytes = null,Object? callPhoneName = freezed,Object? callPhoneExactMatch = null,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,audioBytes: null == audioBytes ? _self.audioBytes : audioBytes // ignore: cast_nullable_to_non_nullable
as List<int>,callPhoneName: freezed == callPhoneName ? _self.callPhoneName : callPhoneName // ignore: cast_nullable_to_non_nullable
as String?,callPhoneExactMatch: null == callPhoneExactMatch ? _self.callPhoneExactMatch : callPhoneExactMatch // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AssistantResponse].
extension AssistantResponsePatterns on AssistantResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssistantResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssistantResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssistantResponse value)  $default,){
final _that = this;
switch (_that) {
case _AssistantResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssistantResponse value)?  $default,){
final _that = this;
switch (_that) {
case _AssistantResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  List<int> audioBytes,  String? callPhoneName,  bool callPhoneExactMatch)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssistantResponse() when $default != null:
return $default(_that.text,_that.audioBytes,_that.callPhoneName,_that.callPhoneExactMatch);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  List<int> audioBytes,  String? callPhoneName,  bool callPhoneExactMatch)  $default,) {final _that = this;
switch (_that) {
case _AssistantResponse():
return $default(_that.text,_that.audioBytes,_that.callPhoneName,_that.callPhoneExactMatch);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  List<int> audioBytes,  String? callPhoneName,  bool callPhoneExactMatch)?  $default,) {final _that = this;
switch (_that) {
case _AssistantResponse() when $default != null:
return $default(_that.text,_that.audioBytes,_that.callPhoneName,_that.callPhoneExactMatch);case _:
  return null;

}
}

}

/// @nodoc


class _AssistantResponse implements AssistantResponse {
  const _AssistantResponse({required this.text, required final  List<int> audioBytes, this.callPhoneName, this.callPhoneExactMatch = false}): _audioBytes = audioBytes;
  

@override final  String text;
 final  List<int> _audioBytes;
@override List<int> get audioBytes {
  if (_audioBytes is EqualUnmodifiableListView) return _audioBytes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_audioBytes);
}

@override final  String? callPhoneName;
@override@JsonKey() final  bool callPhoneExactMatch;

/// Create a copy of AssistantResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssistantResponseCopyWith<_AssistantResponse> get copyWith => __$AssistantResponseCopyWithImpl<_AssistantResponse>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssistantResponse&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other._audioBytes, _audioBytes)&&(identical(other.callPhoneName, callPhoneName) || other.callPhoneName == callPhoneName)&&(identical(other.callPhoneExactMatch, callPhoneExactMatch) || other.callPhoneExactMatch == callPhoneExactMatch));
}


@override
int get hashCode => Object.hash(runtimeType,text,const DeepCollectionEquality().hash(_audioBytes),callPhoneName,callPhoneExactMatch);

@override
String toString() {
  return 'AssistantResponse(text: $text, audioBytes: $audioBytes, callPhoneName: $callPhoneName, callPhoneExactMatch: $callPhoneExactMatch)';
}


}

/// @nodoc
abstract mixin class _$AssistantResponseCopyWith<$Res> implements $AssistantResponseCopyWith<$Res> {
  factory _$AssistantResponseCopyWith(_AssistantResponse value, $Res Function(_AssistantResponse) _then) = __$AssistantResponseCopyWithImpl;
@override @useResult
$Res call({
 String text, List<int> audioBytes, String? callPhoneName, bool callPhoneExactMatch
});




}
/// @nodoc
class __$AssistantResponseCopyWithImpl<$Res>
    implements _$AssistantResponseCopyWith<$Res> {
  __$AssistantResponseCopyWithImpl(this._self, this._then);

  final _AssistantResponse _self;
  final $Res Function(_AssistantResponse) _then;

/// Create a copy of AssistantResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? audioBytes = null,Object? callPhoneName = freezed,Object? callPhoneExactMatch = null,}) {
  return _then(_AssistantResponse(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,audioBytes: null == audioBytes ? _self._audioBytes : audioBytes // ignore: cast_nullable_to_non_nullable
as List<int>,callPhoneName: freezed == callPhoneName ? _self.callPhoneName : callPhoneName // ignore: cast_nullable_to_non_nullable
as String?,callPhoneExactMatch: null == callPhoneExactMatch ? _self.callPhoneExactMatch : callPhoneExactMatch // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
