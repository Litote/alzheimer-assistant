// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reminder.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Reminder {

@JsonKey(name: 'event_id') String get eventId;/// Occurrence date (`YYYY-MM-DD`) — recurring events have one per day.
 String get date;/// When the notification must fire (UTC).
@JsonKey(name: 'notify_at') DateTime get notifyAt; String get title; String get body;
/// Create a copy of Reminder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReminderCopyWith<Reminder> get copyWith => _$ReminderCopyWithImpl<Reminder>(this as Reminder, _$identity);

  /// Serializes this Reminder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Reminder;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Reminder&&(identical(other.eventId, _this.eventId) || other.eventId == _this.eventId)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.notifyAt, _this.notifyAt) || other.notifyAt == _this.notifyAt)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.body, _this.body) || other.body == _this.body));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Reminder;
  return Object.hash(runtimeType,_this.eventId,_this.date,_this.notifyAt,_this.title,_this.body);
}

@override
String toString() {
  final _this = this as Reminder;
  return 'Reminder(eventId: ${_this.eventId}, date: ${_this.date}, notifyAt: ${_this.notifyAt}, title: ${_this.title}, body: ${_this.body})';
}


}

/// @nodoc
abstract mixin class $ReminderCopyWith<$Res>  {
  factory $ReminderCopyWith(Reminder value, $Res Function(Reminder) _then) = _$ReminderCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'event_id') String eventId, String date,@JsonKey(name: 'notify_at') DateTime notifyAt, String title, String body
});




}
/// @nodoc
class _$ReminderCopyWithImpl<$Res>
    implements $ReminderCopyWith<$Res> {
  _$ReminderCopyWithImpl(this._self, this._then);

  final Reminder _self;
  final $Res Function(Reminder) _then;

/// Create a copy of Reminder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventId = null,Object? date = null,Object? notifyAt = null,Object? title = null,Object? body = null,}) {
  return _then(Reminder(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,notifyAt: null == notifyAt ? _self.notifyAt : notifyAt // ignore: cast_nullable_to_non_nullable
as DateTime,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Reminder].
extension ReminderPatterns on Reminder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Reminder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Reminder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Reminder value)  $default,){
final _that = this;
switch (_that) {
case _Reminder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Reminder value)?  $default,){
final _that = this;
switch (_that) {
case _Reminder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'event_id')  String eventId,  String date, @JsonKey(name: 'notify_at')  DateTime notifyAt,  String title,  String body)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Reminder() when $default != null:
return $default(_that.eventId,_that.date,_that.notifyAt,_that.title,_that.body);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'event_id')  String eventId,  String date, @JsonKey(name: 'notify_at')  DateTime notifyAt,  String title,  String body)  $default,) {final _that = this;
switch (_that) {
case _Reminder():
return $default(_that.eventId,_that.date,_that.notifyAt,_that.title,_that.body);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'event_id')  String eventId,  String date, @JsonKey(name: 'notify_at')  DateTime notifyAt,  String title,  String body)?  $default,) {final _that = this;
switch (_that) {
case _Reminder() when $default != null:
return $default(_that.eventId,_that.date,_that.notifyAt,_that.title,_that.body);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Reminder extends Reminder {
  const _Reminder({@JsonKey(name: 'event_id') required this.eventId, required this.date, @JsonKey(name: 'notify_at') required this.notifyAt, required this.title, this.body = ''}): super._();
  factory _Reminder.fromJson(Map<String, dynamic> json) => _$ReminderFromJson(json);

@override@JsonKey(name: 'event_id') final  String eventId;
/// Occurrence date (`YYYY-MM-DD`) — recurring events have one per day.
@override final  String date;
/// When the notification must fire (UTC).
@override@JsonKey(name: 'notify_at') final  DateTime notifyAt;
@override final  String title;
@override@JsonKey() final  String body;

/// Create a copy of Reminder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReminderCopyWith<_Reminder> get copyWith => __$ReminderCopyWithImpl<_Reminder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReminderToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Reminder&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.date, date) || other.date == date)&&(identical(other.notifyAt, notifyAt) || other.notifyAt == notifyAt)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,eventId,date,notifyAt,title,body);
}

@override
String toString() {
    return 'Reminder(eventId: $eventId, date: $date, notifyAt: $notifyAt, title: $title, body: $body)';
}


}

/// @nodoc
abstract mixin class _$ReminderCopyWith<$Res> implements $ReminderCopyWith<$Res> {
  factory _$ReminderCopyWith(_Reminder value, $Res Function(_Reminder) _then) = __$ReminderCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'event_id') String eventId, String date,@JsonKey(name: 'notify_at') DateTime notifyAt, String title, String body
});




}
/// @nodoc
class __$ReminderCopyWithImpl<$Res>
    implements _$ReminderCopyWith<$Res> {
  __$ReminderCopyWithImpl(this._self, this._then);

  final _Reminder _self;
  final $Res Function(_Reminder) _then;

/// Create a copy of Reminder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventId = null,Object? date = null,Object? notifyAt = null,Object? title = null,Object? body = null,}) {
  return _then(_Reminder(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,notifyAt: null == notifyAt ? _self.notifyAt : notifyAt // ignore: cast_nullable_to_non_nullable
as DateTime,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ReminderRef {

@JsonKey(name: 'event_id') String get eventId; String get date;
/// Create a copy of ReminderRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReminderRefCopyWith<ReminderRef> get copyWith => _$ReminderRefCopyWithImpl<ReminderRef>(this as ReminderRef, _$identity);

  /// Serializes this ReminderRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ReminderRef;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReminderRef&&(identical(other.eventId, _this.eventId) || other.eventId == _this.eventId)&&(identical(other.date, _this.date) || other.date == _this.date));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ReminderRef;
  return Object.hash(runtimeType,_this.eventId,_this.date);
}

@override
String toString() {
  final _this = this as ReminderRef;
  return 'ReminderRef(eventId: ${_this.eventId}, date: ${_this.date})';
}


}

/// @nodoc
abstract mixin class $ReminderRefCopyWith<$Res>  {
  factory $ReminderRefCopyWith(ReminderRef value, $Res Function(ReminderRef) _then) = _$ReminderRefCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'event_id') String eventId, String date
});




}
/// @nodoc
class _$ReminderRefCopyWithImpl<$Res>
    implements $ReminderRefCopyWith<$Res> {
  _$ReminderRefCopyWithImpl(this._self, this._then);

  final ReminderRef _self;
  final $Res Function(ReminderRef) _then;

/// Create a copy of ReminderRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventId = null,Object? date = null,}) {
  return _then(ReminderRef(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ReminderRef].
extension ReminderRefPatterns on ReminderRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReminderRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReminderRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReminderRef value)  $default,){
final _that = this;
switch (_that) {
case _ReminderRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReminderRef value)?  $default,){
final _that = this;
switch (_that) {
case _ReminderRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'event_id')  String eventId,  String date)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReminderRef() when $default != null:
return $default(_that.eventId,_that.date);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'event_id')  String eventId,  String date)  $default,) {final _that = this;
switch (_that) {
case _ReminderRef():
return $default(_that.eventId,_that.date);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'event_id')  String eventId,  String date)?  $default,) {final _that = this;
switch (_that) {
case _ReminderRef() when $default != null:
return $default(_that.eventId,_that.date);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReminderRef implements ReminderRef {
  const _ReminderRef({@JsonKey(name: 'event_id') required this.eventId, required this.date});
  factory _ReminderRef.fromJson(Map<String, dynamic> json) => _$ReminderRefFromJson(json);

@override@JsonKey(name: 'event_id') final  String eventId;
@override final  String date;

/// Create a copy of ReminderRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReminderRefCopyWith<_ReminderRef> get copyWith => __$ReminderRefCopyWithImpl<_ReminderRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReminderRefToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReminderRef&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.date, date) || other.date == date));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,eventId,date);
}

@override
String toString() {
    return 'ReminderRef(eventId: $eventId, date: $date)';
}


}

/// @nodoc
abstract mixin class _$ReminderRefCopyWith<$Res> implements $ReminderRefCopyWith<$Res> {
  factory _$ReminderRefCopyWith(_ReminderRef value, $Res Function(_ReminderRef) _then) = __$ReminderRefCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'event_id') String eventId, String date
});




}
/// @nodoc
class __$ReminderRefCopyWithImpl<$Res>
    implements _$ReminderRefCopyWith<$Res> {
  __$ReminderRefCopyWithImpl(this._self, this._then);

  final _ReminderRef _self;
  final $Res Function(_ReminderRef) _then;

/// Create a copy of ReminderRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventId = null,Object? date = null,}) {
  return _then(_ReminderRef(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
