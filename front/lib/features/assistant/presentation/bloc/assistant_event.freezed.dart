// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'assistant_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AssistantEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssistantEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AssistantEvent()';
}


}

/// @nodoc
class $AssistantEventCopyWith<$Res>  {
$AssistantEventCopyWith(AssistantEvent _, $Res Function(AssistantEvent) __);
}


/// Adds pattern-matching-related methods to [AssistantEvent].
extension AssistantEventPatterns on AssistantEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StartListening value)?  startListening,TResult Function( InterimTranscript value)?  interimTranscript,TResult Function( SendMessage value)?  sendMessage,TResult Function( SpeakResponse value)?  speakResponse,TResult Function( AudioFinished value)?  audioFinished,TResult Function( ErrorOccurred value)?  errorOccurred,TResult Function( AppResumed value)?  appResumed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StartListening() when startListening != null:
return startListening(_that);case InterimTranscript() when interimTranscript != null:
return interimTranscript(_that);case SendMessage() when sendMessage != null:
return sendMessage(_that);case SpeakResponse() when speakResponse != null:
return speakResponse(_that);case AudioFinished() when audioFinished != null:
return audioFinished(_that);case ErrorOccurred() when errorOccurred != null:
return errorOccurred(_that);case AppResumed() when appResumed != null:
return appResumed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StartListening value)  startListening,required TResult Function( InterimTranscript value)  interimTranscript,required TResult Function( SendMessage value)  sendMessage,required TResult Function( SpeakResponse value)  speakResponse,required TResult Function( AudioFinished value)  audioFinished,required TResult Function( ErrorOccurred value)  errorOccurred,required TResult Function( AppResumed value)  appResumed,}){
final _that = this;
switch (_that) {
case StartListening():
return startListening(_that);case InterimTranscript():
return interimTranscript(_that);case SendMessage():
return sendMessage(_that);case SpeakResponse():
return speakResponse(_that);case AudioFinished():
return audioFinished(_that);case ErrorOccurred():
return errorOccurred(_that);case AppResumed():
return appResumed(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StartListening value)?  startListening,TResult? Function( InterimTranscript value)?  interimTranscript,TResult? Function( SendMessage value)?  sendMessage,TResult? Function( SpeakResponse value)?  speakResponse,TResult? Function( AudioFinished value)?  audioFinished,TResult? Function( ErrorOccurred value)?  errorOccurred,TResult? Function( AppResumed value)?  appResumed,}){
final _that = this;
switch (_that) {
case StartListening() when startListening != null:
return startListening(_that);case InterimTranscript() when interimTranscript != null:
return interimTranscript(_that);case SendMessage() when sendMessage != null:
return sendMessage(_that);case SpeakResponse() when speakResponse != null:
return speakResponse(_that);case AudioFinished() when audioFinished != null:
return audioFinished(_that);case ErrorOccurred() when errorOccurred != null:
return errorOccurred(_that);case AppResumed() when appResumed != null:
return appResumed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  startListening,TResult Function( String text)?  interimTranscript,TResult Function( String text)?  sendMessage,TResult Function( String text,  List<int> audioBytes)?  speakResponse,TResult Function()?  audioFinished,TResult Function( String message)?  errorOccurred,TResult Function()?  appResumed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StartListening() when startListening != null:
return startListening();case InterimTranscript() when interimTranscript != null:
return interimTranscript(_that.text);case SendMessage() when sendMessage != null:
return sendMessage(_that.text);case SpeakResponse() when speakResponse != null:
return speakResponse(_that.text,_that.audioBytes);case AudioFinished() when audioFinished != null:
return audioFinished();case ErrorOccurred() when errorOccurred != null:
return errorOccurred(_that.message);case AppResumed() when appResumed != null:
return appResumed();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  startListening,required TResult Function( String text)  interimTranscript,required TResult Function( String text)  sendMessage,required TResult Function( String text,  List<int> audioBytes)  speakResponse,required TResult Function()  audioFinished,required TResult Function( String message)  errorOccurred,required TResult Function()  appResumed,}) {final _that = this;
switch (_that) {
case StartListening():
return startListening();case InterimTranscript():
return interimTranscript(_that.text);case SendMessage():
return sendMessage(_that.text);case SpeakResponse():
return speakResponse(_that.text,_that.audioBytes);case AudioFinished():
return audioFinished();case ErrorOccurred():
return errorOccurred(_that.message);case AppResumed():
return appResumed();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  startListening,TResult? Function( String text)?  interimTranscript,TResult? Function( String text)?  sendMessage,TResult? Function( String text,  List<int> audioBytes)?  speakResponse,TResult? Function()?  audioFinished,TResult? Function( String message)?  errorOccurred,TResult? Function()?  appResumed,}) {final _that = this;
switch (_that) {
case StartListening() when startListening != null:
return startListening();case InterimTranscript() when interimTranscript != null:
return interimTranscript(_that.text);case SendMessage() when sendMessage != null:
return sendMessage(_that.text);case SpeakResponse() when speakResponse != null:
return speakResponse(_that.text,_that.audioBytes);case AudioFinished() when audioFinished != null:
return audioFinished();case ErrorOccurred() when errorOccurred != null:
return errorOccurred(_that.message);case AppResumed() when appResumed != null:
return appResumed();case _:
  return null;

}
}

}

/// @nodoc


class StartListening implements AssistantEvent {
  const StartListening();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StartListening);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AssistantEvent.startListening()';
}


}




/// @nodoc


class InterimTranscript implements AssistantEvent {
  const InterimTranscript(this.text);
  

 final  String text;

/// Create a copy of AssistantEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InterimTranscriptCopyWith<InterimTranscript> get copyWith => _$InterimTranscriptCopyWithImpl<InterimTranscript>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InterimTranscript&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'AssistantEvent.interimTranscript(text: $text)';
}


}

/// @nodoc
abstract mixin class $InterimTranscriptCopyWith<$Res> implements $AssistantEventCopyWith<$Res> {
  factory $InterimTranscriptCopyWith(InterimTranscript value, $Res Function(InterimTranscript) _then) = _$InterimTranscriptCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$InterimTranscriptCopyWithImpl<$Res>
    implements $InterimTranscriptCopyWith<$Res> {
  _$InterimTranscriptCopyWithImpl(this._self, this._then);

  final InterimTranscript _self;
  final $Res Function(InterimTranscript) _then;

/// Create a copy of AssistantEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(InterimTranscript(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SendMessage implements AssistantEvent {
  const SendMessage(this.text);
  

 final  String text;

/// Create a copy of AssistantEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SendMessageCopyWith<SendMessage> get copyWith => _$SendMessageCopyWithImpl<SendMessage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SendMessage&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'AssistantEvent.sendMessage(text: $text)';
}


}

/// @nodoc
abstract mixin class $SendMessageCopyWith<$Res> implements $AssistantEventCopyWith<$Res> {
  factory $SendMessageCopyWith(SendMessage value, $Res Function(SendMessage) _then) = _$SendMessageCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$SendMessageCopyWithImpl<$Res>
    implements $SendMessageCopyWith<$Res> {
  _$SendMessageCopyWithImpl(this._self, this._then);

  final SendMessage _self;
  final $Res Function(SendMessage) _then;

/// Create a copy of AssistantEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(SendMessage(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SpeakResponse implements AssistantEvent {
  const SpeakResponse({required this.text, required final  List<int> audioBytes}): _audioBytes = audioBytes;
  

 final  String text;
 final  List<int> _audioBytes;
 List<int> get audioBytes {
  if (_audioBytes is EqualUnmodifiableListView) return _audioBytes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_audioBytes);
}


/// Create a copy of AssistantEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpeakResponseCopyWith<SpeakResponse> get copyWith => _$SpeakResponseCopyWithImpl<SpeakResponse>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpeakResponse&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other._audioBytes, _audioBytes));
}


@override
int get hashCode => Object.hash(runtimeType,text,const DeepCollectionEquality().hash(_audioBytes));

@override
String toString() {
  return 'AssistantEvent.speakResponse(text: $text, audioBytes: $audioBytes)';
}


}

/// @nodoc
abstract mixin class $SpeakResponseCopyWith<$Res> implements $AssistantEventCopyWith<$Res> {
  factory $SpeakResponseCopyWith(SpeakResponse value, $Res Function(SpeakResponse) _then) = _$SpeakResponseCopyWithImpl;
@useResult
$Res call({
 String text, List<int> audioBytes
});




}
/// @nodoc
class _$SpeakResponseCopyWithImpl<$Res>
    implements $SpeakResponseCopyWith<$Res> {
  _$SpeakResponseCopyWithImpl(this._self, this._then);

  final SpeakResponse _self;
  final $Res Function(SpeakResponse) _then;

/// Create a copy of AssistantEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,Object? audioBytes = null,}) {
  return _then(SpeakResponse(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,audioBytes: null == audioBytes ? _self._audioBytes : audioBytes // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

/// @nodoc


class AudioFinished implements AssistantEvent {
  const AudioFinished();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AudioFinished);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AssistantEvent.audioFinished()';
}


}




/// @nodoc


class ErrorOccurred implements AssistantEvent {
  const ErrorOccurred(this.message);
  

 final  String message;

/// Create a copy of AssistantEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ErrorOccurredCopyWith<ErrorOccurred> get copyWith => _$ErrorOccurredCopyWithImpl<ErrorOccurred>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ErrorOccurred&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AssistantEvent.errorOccurred(message: $message)';
}


}

/// @nodoc
abstract mixin class $ErrorOccurredCopyWith<$Res> implements $AssistantEventCopyWith<$Res> {
  factory $ErrorOccurredCopyWith(ErrorOccurred value, $Res Function(ErrorOccurred) _then) = _$ErrorOccurredCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ErrorOccurredCopyWithImpl<$Res>
    implements $ErrorOccurredCopyWith<$Res> {
  _$ErrorOccurredCopyWithImpl(this._self, this._then);

  final ErrorOccurred _self;
  final $Res Function(ErrorOccurred) _then;

/// Create a copy of AssistantEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ErrorOccurred(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AppResumed implements AssistantEvent {
  const AppResumed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppResumed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AssistantEvent.appResumed()';
}


}




// dart format on
