// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LiveEvent {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is LiveEvent);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'LiveEvent()';
  }
}

/// @nodoc
class $LiveEventCopyWith<$Res> {
  $LiveEventCopyWith(LiveEvent _, $Res Function(LiveEvent) __);
}

/// Adds pattern-matching-related methods to [LiveEvent].
extension LiveEventPatterns on LiveEvent {
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
    TResult Function(LiveAudioChunk value)? audioChunk,
    TResult Function(LiveTextDelta value)? textDelta,
    TResult Function(LiveCallPhone value)? callPhone,
    TResult Function(LiveTurnComplete value)? turnComplete,
    TResult Function(LiveInputTranscription value)? inputTranscription,
    TResult Function(LiveOutputTranscription value)? outputTranscription,
    TResult Function(LiveToolStatus value)? toolStatus,
    TResult Function(LiveSessionInfo value)? sessionInfo,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case LiveAudioChunk() when audioChunk != null:
        return audioChunk(_that);
      case LiveTextDelta() when textDelta != null:
        return textDelta(_that);
      case LiveCallPhone() when callPhone != null:
        return callPhone(_that);
      case LiveTurnComplete() when turnComplete != null:
        return turnComplete(_that);
      case LiveInputTranscription() when inputTranscription != null:
        return inputTranscription(_that);
      case LiveOutputTranscription() when outputTranscription != null:
        return outputTranscription(_that);
      case LiveToolStatus() when toolStatus != null:
        return toolStatus(_that);
      case LiveSessionInfo() when sessionInfo != null:
        return sessionInfo(_that);
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
    required TResult Function(LiveAudioChunk value) audioChunk,
    required TResult Function(LiveTextDelta value) textDelta,
    required TResult Function(LiveCallPhone value) callPhone,
    required TResult Function(LiveTurnComplete value) turnComplete,
    required TResult Function(LiveInputTranscription value) inputTranscription,
    required TResult Function(LiveOutputTranscription value)
        outputTranscription,
    required TResult Function(LiveToolStatus value) toolStatus,
    required TResult Function(LiveSessionInfo value) sessionInfo,
  }) {
    final _that = this;
    switch (_that) {
      case LiveAudioChunk():
        return audioChunk(_that);
      case LiveTextDelta():
        return textDelta(_that);
      case LiveCallPhone():
        return callPhone(_that);
      case LiveTurnComplete():
        return turnComplete(_that);
      case LiveInputTranscription():
        return inputTranscription(_that);
      case LiveOutputTranscription():
        return outputTranscription(_that);
      case LiveToolStatus():
        return toolStatus(_that);
      case LiveSessionInfo():
        return sessionInfo(_that);
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
    TResult? Function(LiveAudioChunk value)? audioChunk,
    TResult? Function(LiveTextDelta value)? textDelta,
    TResult? Function(LiveCallPhone value)? callPhone,
    TResult? Function(LiveTurnComplete value)? turnComplete,
    TResult? Function(LiveInputTranscription value)? inputTranscription,
    TResult? Function(LiveOutputTranscription value)? outputTranscription,
    TResult? Function(LiveToolStatus value)? toolStatus,
    TResult? Function(LiveSessionInfo value)? sessionInfo,
  }) {
    final _that = this;
    switch (_that) {
      case LiveAudioChunk() when audioChunk != null:
        return audioChunk(_that);
      case LiveTextDelta() when textDelta != null:
        return textDelta(_that);
      case LiveCallPhone() when callPhone != null:
        return callPhone(_that);
      case LiveTurnComplete() when turnComplete != null:
        return turnComplete(_that);
      case LiveInputTranscription() when inputTranscription != null:
        return inputTranscription(_that);
      case LiveOutputTranscription() when outputTranscription != null:
        return outputTranscription(_that);
      case LiveToolStatus() when toolStatus != null:
        return toolStatus(_that);
      case LiveSessionInfo() when sessionInfo != null:
        return sessionInfo(_that);
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
    TResult Function(Uint8List bytes)? audioChunk,
    TResult Function(String text)? textDelta,
    TResult Function(String callId, String contactName, bool exactMatch)?
        callPhone,
    TResult Function()? turnComplete,
    TResult Function(String text)? inputTranscription,
    TResult Function(String text)? outputTranscription,
    TResult Function(String label)? toolStatus,
    TResult Function(String welcome)? sessionInfo,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case LiveAudioChunk() when audioChunk != null:
        return audioChunk(_that.bytes);
      case LiveTextDelta() when textDelta != null:
        return textDelta(_that.text);
      case LiveCallPhone() when callPhone != null:
        return callPhone(_that.callId, _that.contactName, _that.exactMatch);
      case LiveTurnComplete() when turnComplete != null:
        return turnComplete();
      case LiveInputTranscription() when inputTranscription != null:
        return inputTranscription(_that.text);
      case LiveOutputTranscription() when outputTranscription != null:
        return outputTranscription(_that.text);
      case LiveToolStatus() when toolStatus != null:
        return toolStatus(_that.label);
      case LiveSessionInfo() when sessionInfo != null:
        return sessionInfo(_that.welcome);
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
    required TResult Function(Uint8List bytes) audioChunk,
    required TResult Function(String text) textDelta,
    required TResult Function(
            String callId, String contactName, bool exactMatch)
        callPhone,
    required TResult Function() turnComplete,
    required TResult Function(String text) inputTranscription,
    required TResult Function(String text) outputTranscription,
    required TResult Function(String label) toolStatus,
    required TResult Function(String welcome) sessionInfo,
  }) {
    final _that = this;
    switch (_that) {
      case LiveAudioChunk():
        return audioChunk(_that.bytes);
      case LiveTextDelta():
        return textDelta(_that.text);
      case LiveCallPhone():
        return callPhone(_that.callId, _that.contactName, _that.exactMatch);
      case LiveTurnComplete():
        return turnComplete();
      case LiveInputTranscription():
        return inputTranscription(_that.text);
      case LiveOutputTranscription():
        return outputTranscription(_that.text);
      case LiveToolStatus():
        return toolStatus(_that.label);
      case LiveSessionInfo():
        return sessionInfo(_that.welcome);
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
    TResult? Function(Uint8List bytes)? audioChunk,
    TResult? Function(String text)? textDelta,
    TResult? Function(String callId, String contactName, bool exactMatch)?
        callPhone,
    TResult? Function()? turnComplete,
    TResult? Function(String text)? inputTranscription,
    TResult? Function(String text)? outputTranscription,
    TResult? Function(String label)? toolStatus,
    TResult? Function(String welcome)? sessionInfo,
  }) {
    final _that = this;
    switch (_that) {
      case LiveAudioChunk() when audioChunk != null:
        return audioChunk(_that.bytes);
      case LiveTextDelta() when textDelta != null:
        return textDelta(_that.text);
      case LiveCallPhone() when callPhone != null:
        return callPhone(_that.callId, _that.contactName, _that.exactMatch);
      case LiveTurnComplete() when turnComplete != null:
        return turnComplete();
      case LiveInputTranscription() when inputTranscription != null:
        return inputTranscription(_that.text);
      case LiveOutputTranscription() when outputTranscription != null:
        return outputTranscription(_that.text);
      case LiveToolStatus() when toolStatus != null:
        return toolStatus(_that.label);
      case LiveSessionInfo() when sessionInfo != null:
        return sessionInfo(_that.welcome);
      case _:
        return null;
    }
  }
}

/// @nodoc

class LiveAudioChunk implements LiveEvent {
  const LiveAudioChunk(this.bytes);

  final Uint8List bytes;

  /// Create a copy of LiveEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LiveAudioChunkCopyWith<LiveAudioChunk> get copyWith =>
      _$LiveAudioChunkCopyWithImpl<LiveAudioChunk>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LiveAudioChunk &&
            const DeepCollectionEquality().equals(other.bytes, bytes));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(bytes));

  @override
  String toString() {
    return 'LiveEvent.audioChunk(bytes: $bytes)';
  }
}

/// @nodoc
abstract mixin class $LiveAudioChunkCopyWith<$Res>
    implements $LiveEventCopyWith<$Res> {
  factory $LiveAudioChunkCopyWith(
          LiveAudioChunk value, $Res Function(LiveAudioChunk) _then) =
      _$LiveAudioChunkCopyWithImpl;
  @useResult
  $Res call({Uint8List bytes});
}

/// @nodoc
class _$LiveAudioChunkCopyWithImpl<$Res>
    implements $LiveAudioChunkCopyWith<$Res> {
  _$LiveAudioChunkCopyWithImpl(this._self, this._then);

  final LiveAudioChunk _self;
  final $Res Function(LiveAudioChunk) _then;

  /// Create a copy of LiveEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? bytes = null,
  }) {
    return _then(LiveAudioChunk(
      null == bytes
          ? _self.bytes
          : bytes // ignore: cast_nullable_to_non_nullable
              as Uint8List,
    ));
  }
}

/// @nodoc

class LiveTextDelta implements LiveEvent {
  const LiveTextDelta(this.text);

  final String text;

  /// Create a copy of LiveEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LiveTextDeltaCopyWith<LiveTextDelta> get copyWith =>
      _$LiveTextDeltaCopyWithImpl<LiveTextDelta>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LiveTextDelta &&
            (identical(other.text, text) || other.text == text));
  }

  @override
  int get hashCode => Object.hash(runtimeType, text);

  @override
  String toString() {
    return 'LiveEvent.textDelta(text: $text)';
  }
}

/// @nodoc
abstract mixin class $LiveTextDeltaCopyWith<$Res>
    implements $LiveEventCopyWith<$Res> {
  factory $LiveTextDeltaCopyWith(
          LiveTextDelta value, $Res Function(LiveTextDelta) _then) =
      _$LiveTextDeltaCopyWithImpl;
  @useResult
  $Res call({String text});
}

/// @nodoc
class _$LiveTextDeltaCopyWithImpl<$Res>
    implements $LiveTextDeltaCopyWith<$Res> {
  _$LiveTextDeltaCopyWithImpl(this._self, this._then);

  final LiveTextDelta _self;
  final $Res Function(LiveTextDelta) _then;

  /// Create a copy of LiveEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? text = null,
  }) {
    return _then(LiveTextDelta(
      null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class LiveCallPhone implements LiveEvent {
  const LiveCallPhone(
      {required this.callId,
      required this.contactName,
      required this.exactMatch});

  final String callId;
  final String contactName;
  final bool exactMatch;

  /// Create a copy of LiveEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LiveCallPhoneCopyWith<LiveCallPhone> get copyWith =>
      _$LiveCallPhoneCopyWithImpl<LiveCallPhone>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LiveCallPhone &&
            (identical(other.callId, callId) || other.callId == callId) &&
            (identical(other.contactName, contactName) ||
                other.contactName == contactName) &&
            (identical(other.exactMatch, exactMatch) ||
                other.exactMatch == exactMatch));
  }

  @override
  int get hashCode => Object.hash(runtimeType, callId, contactName, exactMatch);

  @override
  String toString() {
    return 'LiveEvent.callPhone(callId: $callId, contactName: $contactName, exactMatch: $exactMatch)';
  }
}

/// @nodoc
abstract mixin class $LiveCallPhoneCopyWith<$Res>
    implements $LiveEventCopyWith<$Res> {
  factory $LiveCallPhoneCopyWith(
          LiveCallPhone value, $Res Function(LiveCallPhone) _then) =
      _$LiveCallPhoneCopyWithImpl;
  @useResult
  $Res call({String callId, String contactName, bool exactMatch});
}

/// @nodoc
class _$LiveCallPhoneCopyWithImpl<$Res>
    implements $LiveCallPhoneCopyWith<$Res> {
  _$LiveCallPhoneCopyWithImpl(this._self, this._then);

  final LiveCallPhone _self;
  final $Res Function(LiveCallPhone) _then;

  /// Create a copy of LiveEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? callId = null,
    Object? contactName = null,
    Object? exactMatch = null,
  }) {
    return _then(LiveCallPhone(
      callId: null == callId
          ? _self.callId
          : callId // ignore: cast_nullable_to_non_nullable
              as String,
      contactName: null == contactName
          ? _self.contactName
          : contactName // ignore: cast_nullable_to_non_nullable
              as String,
      exactMatch: null == exactMatch
          ? _self.exactMatch
          : exactMatch // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class LiveTurnComplete implements LiveEvent {
  const LiveTurnComplete();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is LiveTurnComplete);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'LiveEvent.turnComplete()';
  }
}

/// @nodoc

class LiveInputTranscription implements LiveEvent {
  const LiveInputTranscription(this.text);

  final String text;

  /// Create a copy of LiveEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LiveInputTranscriptionCopyWith<LiveInputTranscription> get copyWith =>
      _$LiveInputTranscriptionCopyWithImpl<LiveInputTranscription>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LiveInputTranscription &&
            (identical(other.text, text) || other.text == text));
  }

  @override
  int get hashCode => Object.hash(runtimeType, text);

  @override
  String toString() {
    return 'LiveEvent.inputTranscription(text: $text)';
  }
}

/// @nodoc
abstract mixin class $LiveInputTranscriptionCopyWith<$Res>
    implements $LiveEventCopyWith<$Res> {
  factory $LiveInputTranscriptionCopyWith(LiveInputTranscription value,
          $Res Function(LiveInputTranscription) _then) =
      _$LiveInputTranscriptionCopyWithImpl;
  @useResult
  $Res call({String text});
}

/// @nodoc
class _$LiveInputTranscriptionCopyWithImpl<$Res>
    implements $LiveInputTranscriptionCopyWith<$Res> {
  _$LiveInputTranscriptionCopyWithImpl(this._self, this._then);

  final LiveInputTranscription _self;
  final $Res Function(LiveInputTranscription) _then;

  /// Create a copy of LiveEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? text = null,
  }) {
    return _then(LiveInputTranscription(
      null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class LiveOutputTranscription implements LiveEvent {
  const LiveOutputTranscription(this.text);

  final String text;

  /// Create a copy of LiveEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LiveOutputTranscriptionCopyWith<LiveOutputTranscription> get copyWith =>
      _$LiveOutputTranscriptionCopyWithImpl<LiveOutputTranscription>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LiveOutputTranscription &&
            (identical(other.text, text) || other.text == text));
  }

  @override
  int get hashCode => Object.hash(runtimeType, text);

  @override
  String toString() {
    return 'LiveEvent.outputTranscription(text: $text)';
  }
}

/// @nodoc
abstract mixin class $LiveOutputTranscriptionCopyWith<$Res>
    implements $LiveEventCopyWith<$Res> {
  factory $LiveOutputTranscriptionCopyWith(LiveOutputTranscription value,
          $Res Function(LiveOutputTranscription) _then) =
      _$LiveOutputTranscriptionCopyWithImpl;
  @useResult
  $Res call({String text});
}

/// @nodoc
class _$LiveOutputTranscriptionCopyWithImpl<$Res>
    implements $LiveOutputTranscriptionCopyWith<$Res> {
  _$LiveOutputTranscriptionCopyWithImpl(this._self, this._then);

  final LiveOutputTranscription _self;
  final $Res Function(LiveOutputTranscription) _then;

  /// Create a copy of LiveEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? text = null,
  }) {
    return _then(LiveOutputTranscription(
      null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class LiveToolStatus implements LiveEvent {
  const LiveToolStatus(this.label);

  final String label;

  /// Create a copy of LiveEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LiveToolStatusCopyWith<LiveToolStatus> get copyWith =>
      _$LiveToolStatusCopyWithImpl<LiveToolStatus>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LiveToolStatus &&
            (identical(other.label, label) || other.label == label));
  }

  @override
  int get hashCode => Object.hash(runtimeType, label);

  @override
  String toString() {
    return 'LiveEvent.toolStatus(label: $label)';
  }
}

/// @nodoc
abstract mixin class $LiveToolStatusCopyWith<$Res>
    implements $LiveEventCopyWith<$Res> {
  factory $LiveToolStatusCopyWith(
          LiveToolStatus value, $Res Function(LiveToolStatus) _then) =
      _$LiveToolStatusCopyWithImpl;
  @useResult
  $Res call({String label});
}

/// @nodoc
class _$LiveToolStatusCopyWithImpl<$Res>
    implements $LiveToolStatusCopyWith<$Res> {
  _$LiveToolStatusCopyWithImpl(this._self, this._then);

  final LiveToolStatus _self;
  final $Res Function(LiveToolStatus) _then;

  /// Create a copy of LiveEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? label = null,
  }) {
    return _then(LiveToolStatus(
      null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class LiveSessionInfo implements LiveEvent {
  const LiveSessionInfo(this.welcome);

  final String welcome;

  /// Create a copy of LiveEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LiveSessionInfoCopyWith<LiveSessionInfo> get copyWith =>
      _$LiveSessionInfoCopyWithImpl<LiveSessionInfo>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LiveSessionInfo &&
            (identical(other.welcome, welcome) || other.welcome == welcome));
  }

  @override
  int get hashCode => Object.hash(runtimeType, welcome);

  @override
  String toString() {
    return 'LiveEvent.sessionInfo(welcome: $welcome)';
  }
}

/// @nodoc
abstract mixin class $LiveSessionInfoCopyWith<$Res>
    implements $LiveEventCopyWith<$Res> {
  factory $LiveSessionInfoCopyWith(
          LiveSessionInfo value, $Res Function(LiveSessionInfo) _then) =
      _$LiveSessionInfoCopyWithImpl;
  @useResult
  $Res call({String welcome});
}

/// @nodoc
class _$LiveSessionInfoCopyWithImpl<$Res>
    implements $LiveSessionInfoCopyWith<$Res> {
  _$LiveSessionInfoCopyWithImpl(this._self, this._then);

  final LiveSessionInfo _self;
  final $Res Function(LiveSessionInfo) _then;

  /// Create a copy of LiveEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? welcome = null,
  }) {
    return _then(LiveSessionInfo(
      null == welcome
          ? _self.welcome
          : welcome // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
