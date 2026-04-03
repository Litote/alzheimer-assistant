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
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AssistantEvent);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AssistantEvent()';
  }
}

/// @nodoc
class $AssistantEventCopyWith<$Res> {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(StartListening value)? startListening,
    TResult Function(ErrorOccurred value)? errorOccurred,
    TResult Function(AppResumed value)? appResumed,
    TResult Function(LiveEventReceived value)? liveEventReceived,
    TResult Function(AudioPlaybackFinished value)? audioPlaybackFinished,
    TResult Function(SpeechRecognized value)? speechRecognized,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case StartListening() when startListening != null:
        return startListening(_that);
      case ErrorOccurred() when errorOccurred != null:
        return errorOccurred(_that);
      case AppResumed() when appResumed != null:
        return appResumed(_that);
      case LiveEventReceived() when liveEventReceived != null:
        return liveEventReceived(_that);
      case AudioPlaybackFinished() when audioPlaybackFinished != null:
        return audioPlaybackFinished(_that);
      case SpeechRecognized() when speechRecognized != null:
        return speechRecognized(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(StartListening value) startListening,
    required TResult Function(ErrorOccurred value) errorOccurred,
    required TResult Function(AppResumed value) appResumed,
    required TResult Function(LiveEventReceived value) liveEventReceived,
    required TResult Function(AudioPlaybackFinished value)
        audioPlaybackFinished,
    required TResult Function(SpeechRecognized value) speechRecognized,
  }) {
    final _that = this;
    switch (_that) {
      case StartListening():
        return startListening(_that);
      case ErrorOccurred():
        return errorOccurred(_that);
      case AppResumed():
        return appResumed(_that);
      case LiveEventReceived():
        return liveEventReceived(_that);
      case AudioPlaybackFinished():
        return audioPlaybackFinished(_that);
      case SpeechRecognized():
        return speechRecognized(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(StartListening value)? startListening,
    TResult? Function(ErrorOccurred value)? errorOccurred,
    TResult? Function(AppResumed value)? appResumed,
    TResult? Function(LiveEventReceived value)? liveEventReceived,
    TResult? Function(AudioPlaybackFinished value)? audioPlaybackFinished,
    TResult? Function(SpeechRecognized value)? speechRecognized,
  }) {
    final _that = this;
    switch (_that) {
      case StartListening() when startListening != null:
        return startListening(_that);
      case ErrorOccurred() when errorOccurred != null:
        return errorOccurred(_that);
      case AppResumed() when appResumed != null:
        return appResumed(_that);
      case LiveEventReceived() when liveEventReceived != null:
        return liveEventReceived(_that);
      case AudioPlaybackFinished() when audioPlaybackFinished != null:
        return audioPlaybackFinished(_that);
      case SpeechRecognized() when speechRecognized != null:
        return speechRecognized(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? startListening,
    TResult Function(String message)? errorOccurred,
    TResult Function()? appResumed,
    TResult Function(LiveEvent event)? liveEventReceived,
    TResult Function()? audioPlaybackFinished,
    TResult Function(String text)? speechRecognized,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case StartListening() when startListening != null:
        return startListening();
      case ErrorOccurred() when errorOccurred != null:
        return errorOccurred(_that.message);
      case AppResumed() when appResumed != null:
        return appResumed();
      case LiveEventReceived() when liveEventReceived != null:
        return liveEventReceived(_that.event);
      case AudioPlaybackFinished() when audioPlaybackFinished != null:
        return audioPlaybackFinished();
      case SpeechRecognized() when speechRecognized != null:
        return speechRecognized(_that.text);
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() startListening,
    required TResult Function(String message) errorOccurred,
    required TResult Function() appResumed,
    required TResult Function(LiveEvent event) liveEventReceived,
    required TResult Function() audioPlaybackFinished,
    required TResult Function(String text) speechRecognized,
  }) {
    final _that = this;
    switch (_that) {
      case StartListening():
        return startListening();
      case ErrorOccurred():
        return errorOccurred(_that.message);
      case AppResumed():
        return appResumed();
      case LiveEventReceived():
        return liveEventReceived(_that.event);
      case AudioPlaybackFinished():
        return audioPlaybackFinished();
      case SpeechRecognized():
        return speechRecognized(_that.text);
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? startListening,
    TResult? Function(String message)? errorOccurred,
    TResult? Function()? appResumed,
    TResult? Function(LiveEvent event)? liveEventReceived,
    TResult? Function()? audioPlaybackFinished,
    TResult? Function(String text)? speechRecognized,
  }) {
    final _that = this;
    switch (_that) {
      case StartListening() when startListening != null:
        return startListening();
      case ErrorOccurred() when errorOccurred != null:
        return errorOccurred(_that.message);
      case AppResumed() when appResumed != null:
        return appResumed();
      case LiveEventReceived() when liveEventReceived != null:
        return liveEventReceived(_that.event);
      case AudioPlaybackFinished() when audioPlaybackFinished != null:
        return audioPlaybackFinished();
      case SpeechRecognized() when speechRecognized != null:
        return speechRecognized(_that.text);
      case _:
        return null;
    }
  }
}

/// @nodoc

class StartListening implements AssistantEvent {
  const StartListening();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is StartListening);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AssistantEvent.startListening()';
  }
}

/// @nodoc

class ErrorOccurred implements AssistantEvent {
  const ErrorOccurred(this.message);

  final String message;

  /// Create a copy of AssistantEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ErrorOccurredCopyWith<ErrorOccurred> get copyWith =>
      _$ErrorOccurredCopyWithImpl<ErrorOccurred>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ErrorOccurred &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() {
    return 'AssistantEvent.errorOccurred(message: $message)';
  }
}

/// @nodoc
abstract mixin class $ErrorOccurredCopyWith<$Res>
    implements $AssistantEventCopyWith<$Res> {
  factory $ErrorOccurredCopyWith(
          ErrorOccurred value, $Res Function(ErrorOccurred) _then) =
      _$ErrorOccurredCopyWithImpl;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$ErrorOccurredCopyWithImpl<$Res>
    implements $ErrorOccurredCopyWith<$Res> {
  _$ErrorOccurredCopyWithImpl(this._self, this._then);

  final ErrorOccurred _self;
  final $Res Function(ErrorOccurred) _then;

  /// Create a copy of AssistantEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = null,
  }) {
    return _then(ErrorOccurred(
      null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class AppResumed implements AssistantEvent {
  const AppResumed();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AppResumed);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AssistantEvent.appResumed()';
  }
}

/// @nodoc

class LiveEventReceived implements AssistantEvent {
  const LiveEventReceived(this.event);

  final LiveEvent event;

  /// Create a copy of AssistantEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LiveEventReceivedCopyWith<LiveEventReceived> get copyWith =>
      _$LiveEventReceivedCopyWithImpl<LiveEventReceived>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LiveEventReceived &&
            (identical(other.event, event) || other.event == event));
  }

  @override
  int get hashCode => Object.hash(runtimeType, event);

  @override
  String toString() {
    return 'AssistantEvent.liveEventReceived(event: $event)';
  }
}

/// @nodoc
abstract mixin class $LiveEventReceivedCopyWith<$Res>
    implements $AssistantEventCopyWith<$Res> {
  factory $LiveEventReceivedCopyWith(
          LiveEventReceived value, $Res Function(LiveEventReceived) _then) =
      _$LiveEventReceivedCopyWithImpl;
  @useResult
  $Res call({LiveEvent event});

  $LiveEventCopyWith<$Res> get event;
}

/// @nodoc
class _$LiveEventReceivedCopyWithImpl<$Res>
    implements $LiveEventReceivedCopyWith<$Res> {
  _$LiveEventReceivedCopyWithImpl(this._self, this._then);

  final LiveEventReceived _self;
  final $Res Function(LiveEventReceived) _then;

  /// Create a copy of AssistantEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? event = null,
  }) {
    return _then(LiveEventReceived(
      null == event
          ? _self.event
          : event // ignore: cast_nullable_to_non_nullable
              as LiveEvent,
    ));
  }

  /// Create a copy of AssistantEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LiveEventCopyWith<$Res> get event {
    return $LiveEventCopyWith<$Res>(_self.event, (value) {
      return _then(_self.copyWith(event: value));
    });
  }
}

/// @nodoc

class AudioPlaybackFinished implements AssistantEvent {
  const AudioPlaybackFinished();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AudioPlaybackFinished);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AssistantEvent.audioPlaybackFinished()';
  }
}

/// @nodoc

class SpeechRecognized implements AssistantEvent {
  const SpeechRecognized(this.text);

  final String text;

  /// Create a copy of AssistantEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SpeechRecognizedCopyWith<SpeechRecognized> get copyWith =>
      _$SpeechRecognizedCopyWithImpl<SpeechRecognized>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SpeechRecognized &&
            (identical(other.text, text) || other.text == text));
  }

  @override
  int get hashCode => Object.hash(runtimeType, text);

  @override
  String toString() {
    return 'AssistantEvent.speechRecognized(text: $text)';
  }
}

/// @nodoc
abstract mixin class $SpeechRecognizedCopyWith<$Res>
    implements $AssistantEventCopyWith<$Res> {
  factory $SpeechRecognizedCopyWith(
          SpeechRecognized value, $Res Function(SpeechRecognized) _then) =
      _$SpeechRecognizedCopyWithImpl;
  @useResult
  $Res call({String text});
}

/// @nodoc
class _$SpeechRecognizedCopyWithImpl<$Res>
    implements $SpeechRecognizedCopyWith<$Res> {
  _$SpeechRecognizedCopyWithImpl(this._self, this._then);

  final SpeechRecognized _self;
  final $Res Function(SpeechRecognized) _then;

  /// Create a copy of AssistantEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? text = null,
  }) {
    return _then(SpeechRecognized(
      null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
