// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'guidance.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Guidance {

 String get destination; String get instruction; String get maneuver; int get distanceMeters;
/// Create a copy of Guidance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuidanceCopyWith<Guidance> get copyWith => _$GuidanceCopyWithImpl<Guidance>(this as Guidance, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Guidance;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Guidance&&(identical(other.destination, _this.destination) || other.destination == _this.destination)&&(identical(other.instruction, _this.instruction) || other.instruction == _this.instruction)&&(identical(other.maneuver, _this.maneuver) || other.maneuver == _this.maneuver)&&(identical(other.distanceMeters, _this.distanceMeters) || other.distanceMeters == _this.distanceMeters));
}


@override
int get hashCode {
  final _this = this as Guidance;
  return Object.hash(runtimeType,_this.destination,_this.instruction,_this.maneuver,_this.distanceMeters);
}

@override
String toString() {
  final _this = this as Guidance;
  return 'Guidance(destination: ${_this.destination}, instruction: ${_this.instruction}, maneuver: ${_this.maneuver}, distanceMeters: ${_this.distanceMeters})';
}


}

/// @nodoc
abstract mixin class $GuidanceCopyWith<$Res>  {
  factory $GuidanceCopyWith(Guidance value, $Res Function(Guidance) _then) = _$GuidanceCopyWithImpl;
@useResult
$Res call({
 String destination, String instruction, String maneuver, int distanceMeters
});




}
/// @nodoc
class _$GuidanceCopyWithImpl<$Res>
    implements $GuidanceCopyWith<$Res> {
  _$GuidanceCopyWithImpl(this._self, this._then);

  final Guidance _self;
  final $Res Function(Guidance) _then;

/// Create a copy of Guidance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? destination = null,Object? instruction = null,Object? maneuver = null,Object? distanceMeters = null,}) {
  return _then(Guidance(
destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String,instruction: null == instruction ? _self.instruction : instruction // ignore: cast_nullable_to_non_nullable
as String,maneuver: null == maneuver ? _self.maneuver : maneuver // ignore: cast_nullable_to_non_nullable
as String,distanceMeters: null == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Guidance].
extension GuidancePatterns on Guidance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Guidance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Guidance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Guidance value)  $default,){
final _that = this;
switch (_that) {
case _Guidance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Guidance value)?  $default,){
final _that = this;
switch (_that) {
case _Guidance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String destination,  String instruction,  String maneuver,  int distanceMeters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Guidance() when $default != null:
return $default(_that.destination,_that.instruction,_that.maneuver,_that.distanceMeters);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String destination,  String instruction,  String maneuver,  int distanceMeters)  $default,) {final _that = this;
switch (_that) {
case _Guidance():
return $default(_that.destination,_that.instruction,_that.maneuver,_that.distanceMeters);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String destination,  String instruction,  String maneuver,  int distanceMeters)?  $default,) {final _that = this;
switch (_that) {
case _Guidance() when $default != null:
return $default(_that.destination,_that.instruction,_that.maneuver,_that.distanceMeters);case _:
  return null;

}
}

}

/// @nodoc


class _Guidance implements Guidance {
  const _Guidance({required this.destination, required this.instruction, this.maneuver = '', this.distanceMeters = 0});
  

@override final  String destination;
@override final  String instruction;
@override@JsonKey() final  String maneuver;
@override@JsonKey() final  int distanceMeters;

/// Create a copy of Guidance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuidanceCopyWith<_Guidance> get copyWith => __$GuidanceCopyWithImpl<_Guidance>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Guidance&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.instruction, instruction) || other.instruction == instruction)&&(identical(other.maneuver, maneuver) || other.maneuver == maneuver)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters));
}


@override
int get hashCode {
    return Object.hash(runtimeType,destination,instruction,maneuver,distanceMeters);
}

@override
String toString() {
    return 'Guidance(destination: $destination, instruction: $instruction, maneuver: $maneuver, distanceMeters: $distanceMeters)';
}


}

/// @nodoc
abstract mixin class _$GuidanceCopyWith<$Res> implements $GuidanceCopyWith<$Res> {
  factory _$GuidanceCopyWith(_Guidance value, $Res Function(_Guidance) _then) = __$GuidanceCopyWithImpl;
@override @useResult
$Res call({
 String destination, String instruction, String maneuver, int distanceMeters
});




}
/// @nodoc
class __$GuidanceCopyWithImpl<$Res>
    implements _$GuidanceCopyWith<$Res> {
  __$GuidanceCopyWithImpl(this._self, this._then);

  final _Guidance _self;
  final $Res Function(_Guidance) _then;

/// Create a copy of Guidance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? destination = null,Object? instruction = null,Object? maneuver = null,Object? distanceMeters = null,}) {
  return _then(_Guidance(
destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String,instruction: null == instruction ? _self.instruction : instruction // ignore: cast_nullable_to_non_nullable
as String,maneuver: null == maneuver ? _self.maneuver : maneuver // ignore: cast_nullable_to_non_nullable
as String,distanceMeters: null == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
