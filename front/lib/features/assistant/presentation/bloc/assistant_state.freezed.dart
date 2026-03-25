// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'assistant_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AssistantState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssistantState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AssistantState()';
}


}

/// @nodoc
class $AssistantStateCopyWith<$Res>  {
$AssistantStateCopyWith(AssistantState _, $Res Function(AssistantState) __);
}


/// Adds pattern-matching-related methods to [AssistantState].
extension AssistantStatePatterns on AssistantState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Idle value)?  idle,TResult Function( Listening value)?  listening,TResult Function( Processing value)?  processing,TResult Function( Speaking value)?  speaking,TResult Function( AssistantError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Idle() when idle != null:
return idle(_that);case Listening() when listening != null:
return listening(_that);case Processing() when processing != null:
return processing(_that);case Speaking() when speaking != null:
return speaking(_that);case AssistantError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Idle value)  idle,required TResult Function( Listening value)  listening,required TResult Function( Processing value)  processing,required TResult Function( Speaking value)  speaking,required TResult Function( AssistantError value)  error,}){
final _that = this;
switch (_that) {
case Idle():
return idle(_that);case Listening():
return listening(_that);case Processing():
return processing(_that);case Speaking():
return speaking(_that);case AssistantError():
return error(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Idle value)?  idle,TResult? Function( Listening value)?  listening,TResult? Function( Processing value)?  processing,TResult? Function( Speaking value)?  speaking,TResult? Function( AssistantError value)?  error,}){
final _that = this;
switch (_that) {
case Idle() when idle != null:
return idle(_that);case Listening() when listening != null:
return listening(_that);case Processing() when processing != null:
return processing(_that);case Speaking() when speaking != null:
return speaking(_that);case AssistantError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function( String interimTranscript,  List<PhoneCandidate>? pendingCandidates)?  listening,TResult Function( String userMessage)?  processing,TResult Function( String responseText,  String? pendingCallName,  bool awaitingDisambiguation,  List<PhoneCandidate>? pendingCandidates)?  speaking,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Idle() when idle != null:
return idle();case Listening() when listening != null:
return listening(_that.interimTranscript,_that.pendingCandidates);case Processing() when processing != null:
return processing(_that.userMessage);case Speaking() when speaking != null:
return speaking(_that.responseText,_that.pendingCallName,_that.awaitingDisambiguation,_that.pendingCandidates);case AssistantError() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function( String interimTranscript,  List<PhoneCandidate>? pendingCandidates)  listening,required TResult Function( String userMessage)  processing,required TResult Function( String responseText,  String? pendingCallName,  bool awaitingDisambiguation,  List<PhoneCandidate>? pendingCandidates)  speaking,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case Idle():
return idle();case Listening():
return listening(_that.interimTranscript,_that.pendingCandidates);case Processing():
return processing(_that.userMessage);case Speaking():
return speaking(_that.responseText,_that.pendingCallName,_that.awaitingDisambiguation,_that.pendingCandidates);case AssistantError():
return error(_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function( String interimTranscript,  List<PhoneCandidate>? pendingCandidates)?  listening,TResult? Function( String userMessage)?  processing,TResult? Function( String responseText,  String? pendingCallName,  bool awaitingDisambiguation,  List<PhoneCandidate>? pendingCandidates)?  speaking,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case Idle() when idle != null:
return idle();case Listening() when listening != null:
return listening(_that.interimTranscript,_that.pendingCandidates);case Processing() when processing != null:
return processing(_that.userMessage);case Speaking() when speaking != null:
return speaking(_that.responseText,_that.pendingCallName,_that.awaitingDisambiguation,_that.pendingCandidates);case AssistantError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class Idle implements AssistantState {
  const Idle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Idle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AssistantState.idle()';
}


}




/// @nodoc


class Listening implements AssistantState {
  const Listening({this.interimTranscript = '', final  List<PhoneCandidate>? pendingCandidates = null}): _pendingCandidates = pendingCandidates;
  

@JsonKey() final  String interimTranscript;
/// Pending candidates during a phone call disambiguation.
 final  List<PhoneCandidate>? _pendingCandidates;
/// Pending candidates during a phone call disambiguation.
@JsonKey() List<PhoneCandidate>? get pendingCandidates {
  final value = _pendingCandidates;
  if (value == null) return null;
  if (_pendingCandidates is EqualUnmodifiableListView) return _pendingCandidates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of AssistantState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListeningCopyWith<Listening> get copyWith => _$ListeningCopyWithImpl<Listening>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Listening&&(identical(other.interimTranscript, interimTranscript) || other.interimTranscript == interimTranscript)&&const DeepCollectionEquality().equals(other._pendingCandidates, _pendingCandidates));
}


@override
int get hashCode => Object.hash(runtimeType,interimTranscript,const DeepCollectionEquality().hash(_pendingCandidates));

@override
String toString() {
  return 'AssistantState.listening(interimTranscript: $interimTranscript, pendingCandidates: $pendingCandidates)';
}


}

/// @nodoc
abstract mixin class $ListeningCopyWith<$Res> implements $AssistantStateCopyWith<$Res> {
  factory $ListeningCopyWith(Listening value, $Res Function(Listening) _then) = _$ListeningCopyWithImpl;
@useResult
$Res call({
 String interimTranscript, List<PhoneCandidate>? pendingCandidates
});




}
/// @nodoc
class _$ListeningCopyWithImpl<$Res>
    implements $ListeningCopyWith<$Res> {
  _$ListeningCopyWithImpl(this._self, this._then);

  final Listening _self;
  final $Res Function(Listening) _then;

/// Create a copy of AssistantState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? interimTranscript = null,Object? pendingCandidates = freezed,}) {
  return _then(Listening(
interimTranscript: null == interimTranscript ? _self.interimTranscript : interimTranscript // ignore: cast_nullable_to_non_nullable
as String,pendingCandidates: freezed == pendingCandidates ? _self._pendingCandidates : pendingCandidates // ignore: cast_nullable_to_non_nullable
as List<PhoneCandidate>?,
  ));
}


}

/// @nodoc


class Processing implements AssistantState {
  const Processing({required this.userMessage});
  

 final  String userMessage;

/// Create a copy of AssistantState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProcessingCopyWith<Processing> get copyWith => _$ProcessingCopyWithImpl<Processing>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Processing&&(identical(other.userMessage, userMessage) || other.userMessage == userMessage));
}


@override
int get hashCode => Object.hash(runtimeType,userMessage);

@override
String toString() {
  return 'AssistantState.processing(userMessage: $userMessage)';
}


}

/// @nodoc
abstract mixin class $ProcessingCopyWith<$Res> implements $AssistantStateCopyWith<$Res> {
  factory $ProcessingCopyWith(Processing value, $Res Function(Processing) _then) = _$ProcessingCopyWithImpl;
@useResult
$Res call({
 String userMessage
});




}
/// @nodoc
class _$ProcessingCopyWithImpl<$Res>
    implements $ProcessingCopyWith<$Res> {
  _$ProcessingCopyWithImpl(this._self, this._then);

  final Processing _self;
  final $Res Function(Processing) _then;

/// Create a copy of AssistantState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? userMessage = null,}) {
  return _then(Processing(
userMessage: null == userMessage ? _self.userMessage : userMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class Speaking implements AssistantState {
  const Speaking({required this.responseText, this.pendingCallName = null, this.awaitingDisambiguation = false, final  List<PhoneCandidate>? pendingCandidates = null}): _pendingCandidates = pendingCandidates;
  

 final  String responseText;
/// Contact name to call after playback ends (null = no call).
@JsonKey() final  String? pendingCallName;
/// True if the current audio is a disambiguation question.
@JsonKey() final  bool awaitingDisambiguation;
/// Candidates to disambiguate (null when not in disambiguation).
 final  List<PhoneCandidate>? _pendingCandidates;
/// Candidates to disambiguate (null when not in disambiguation).
@JsonKey() List<PhoneCandidate>? get pendingCandidates {
  final value = _pendingCandidates;
  if (value == null) return null;
  if (_pendingCandidates is EqualUnmodifiableListView) return _pendingCandidates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of AssistantState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpeakingCopyWith<Speaking> get copyWith => _$SpeakingCopyWithImpl<Speaking>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Speaking&&(identical(other.responseText, responseText) || other.responseText == responseText)&&(identical(other.pendingCallName, pendingCallName) || other.pendingCallName == pendingCallName)&&(identical(other.awaitingDisambiguation, awaitingDisambiguation) || other.awaitingDisambiguation == awaitingDisambiguation)&&const DeepCollectionEquality().equals(other._pendingCandidates, _pendingCandidates));
}


@override
int get hashCode => Object.hash(runtimeType,responseText,pendingCallName,awaitingDisambiguation,const DeepCollectionEquality().hash(_pendingCandidates));

@override
String toString() {
  return 'AssistantState.speaking(responseText: $responseText, pendingCallName: $pendingCallName, awaitingDisambiguation: $awaitingDisambiguation, pendingCandidates: $pendingCandidates)';
}


}

/// @nodoc
abstract mixin class $SpeakingCopyWith<$Res> implements $AssistantStateCopyWith<$Res> {
  factory $SpeakingCopyWith(Speaking value, $Res Function(Speaking) _then) = _$SpeakingCopyWithImpl;
@useResult
$Res call({
 String responseText, String? pendingCallName, bool awaitingDisambiguation, List<PhoneCandidate>? pendingCandidates
});




}
/// @nodoc
class _$SpeakingCopyWithImpl<$Res>
    implements $SpeakingCopyWith<$Res> {
  _$SpeakingCopyWithImpl(this._self, this._then);

  final Speaking _self;
  final $Res Function(Speaking) _then;

/// Create a copy of AssistantState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? responseText = null,Object? pendingCallName = freezed,Object? awaitingDisambiguation = null,Object? pendingCandidates = freezed,}) {
  return _then(Speaking(
responseText: null == responseText ? _self.responseText : responseText // ignore: cast_nullable_to_non_nullable
as String,pendingCallName: freezed == pendingCallName ? _self.pendingCallName : pendingCallName // ignore: cast_nullable_to_non_nullable
as String?,awaitingDisambiguation: null == awaitingDisambiguation ? _self.awaitingDisambiguation : awaitingDisambiguation // ignore: cast_nullable_to_non_nullable
as bool,pendingCandidates: freezed == pendingCandidates ? _self._pendingCandidates : pendingCandidates // ignore: cast_nullable_to_non_nullable
as List<PhoneCandidate>?,
  ));
}


}

/// @nodoc


class AssistantError implements AssistantState {
  const AssistantError({required this.message});
  

 final  String message;

/// Create a copy of AssistantState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssistantErrorCopyWith<AssistantError> get copyWith => _$AssistantErrorCopyWithImpl<AssistantError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssistantError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AssistantState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $AssistantErrorCopyWith<$Res> implements $AssistantStateCopyWith<$Res> {
  factory $AssistantErrorCopyWith(AssistantError value, $Res Function(AssistantError) _then) = _$AssistantErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$AssistantErrorCopyWithImpl<$Res>
    implements $AssistantErrorCopyWith<$Res> {
  _$AssistantErrorCopyWithImpl(this._self, this._then);

  final AssistantError _self;
  final $Res Function(AssistantError) _then;

/// Create a copy of AssistantState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(AssistantError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
