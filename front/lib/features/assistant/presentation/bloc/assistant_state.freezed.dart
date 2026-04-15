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
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AssistantState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AssistantState()';
  }
}

/// @nodoc
class $AssistantStateCopyWith<$Res> {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(Starting value)? starting,
    TResult Function(Connecting value)? connecting,
    TResult Function(Listening value)? listening,
    TResult Function(Speaking value)? speaking,
    TResult Function(AssistantError value)? error,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case Idle() when idle != null:
        return idle(_that);
      case Starting() when starting != null:
        return starting(_that);
      case Connecting() when connecting != null:
        return connecting(_that);
      case Listening() when listening != null:
        return listening(_that);
      case Speaking() when speaking != null:
        return speaking(_that);
      case AssistantError() when error != null:
        return error(_that);
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
    required TResult Function(Idle value) idle,
    required TResult Function(Starting value) starting,
    required TResult Function(Connecting value) connecting,
    required TResult Function(Listening value) listening,
    required TResult Function(Speaking value) speaking,
    required TResult Function(AssistantError value) error,
  }) {
    final _that = this;
    switch (_that) {
      case Idle():
        return idle(_that);
      case Starting():
        return starting(_that);
      case Connecting():
        return connecting(_that);
      case Listening():
        return listening(_that);
      case Speaking():
        return speaking(_that);
      case AssistantError():
        return error(_that);
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
    TResult? Function(Idle value)? idle,
    TResult? Function(Starting value)? starting,
    TResult? Function(Connecting value)? connecting,
    TResult? Function(Listening value)? listening,
    TResult? Function(Speaking value)? speaking,
    TResult? Function(AssistantError value)? error,
  }) {
    final _that = this;
    switch (_that) {
      case Idle() when idle != null:
        return idle(_that);
      case Starting() when starting != null:
        return starting(_that);
      case Connecting() when connecting != null:
        return connecting(_that);
      case Listening() when listening != null:
        return listening(_that);
      case Speaking() when speaking != null:
        return speaking(_that);
      case AssistantError() when error != null:
        return error(_that);
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
    TResult Function(String imageUrl)? idle,
    TResult Function()? starting,
    TResult Function()? connecting,
    TResult Function(String interimTranscript, String statusLabel,
            String welcomeText, String imageUrl)?
        listening,
    TResult Function(
            String responseText, String userTranscript, String imageUrl)?
        speaking,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case Idle() when idle != null:
        return idle(_that.imageUrl);
      case Starting() when starting != null:
        return starting();
      case Connecting() when connecting != null:
        return connecting();
      case Listening() when listening != null:
        return listening(_that.interimTranscript, _that.statusLabel,
            _that.welcomeText, _that.imageUrl);
      case Speaking() when speaking != null:
        return speaking(
            _that.responseText, _that.userTranscript, _that.imageUrl);
      case AssistantError() when error != null:
        return error(_that.message);
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
    required TResult Function(String imageUrl) idle,
    required TResult Function() starting,
    required TResult Function() connecting,
    required TResult Function(String interimTranscript, String statusLabel,
            String welcomeText, String imageUrl)
        listening,
    required TResult Function(
            String responseText, String userTranscript, String imageUrl)
        speaking,
    required TResult Function(String message) error,
  }) {
    final _that = this;
    switch (_that) {
      case Idle():
        return idle(_that.imageUrl);
      case Starting():
        return starting();
      case Connecting():
        return connecting();
      case Listening():
        return listening(_that.interimTranscript, _that.statusLabel,
            _that.welcomeText, _that.imageUrl);
      case Speaking():
        return speaking(
            _that.responseText, _that.userTranscript, _that.imageUrl);
      case AssistantError():
        return error(_that.message);
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
    TResult? Function(String imageUrl)? idle,
    TResult? Function()? starting,
    TResult? Function()? connecting,
    TResult? Function(String interimTranscript, String statusLabel,
            String welcomeText, String imageUrl)?
        listening,
    TResult? Function(
            String responseText, String userTranscript, String imageUrl)?
        speaking,
    TResult? Function(String message)? error,
  }) {
    final _that = this;
    switch (_that) {
      case Idle() when idle != null:
        return idle(_that.imageUrl);
      case Starting() when starting != null:
        return starting();
      case Connecting() when connecting != null:
        return connecting();
      case Listening() when listening != null:
        return listening(_that.interimTranscript, _that.statusLabel,
            _that.welcomeText, _that.imageUrl);
      case Speaking() when speaking != null:
        return speaking(
            _that.responseText, _that.userTranscript, _that.imageUrl);
      case AssistantError() when error != null:
        return error(_that.message);
      case _:
        return null;
    }
  }
}

/// @nodoc

class Idle implements AssistantState {
  const Idle({this.imageUrl = ''});

  @JsonKey()
  final String imageUrl;

  /// Create a copy of AssistantState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $IdleCopyWith<Idle> get copyWith =>
      _$IdleCopyWithImpl<Idle>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Idle &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl));
  }

  @override
  int get hashCode => Object.hash(runtimeType, imageUrl);

  @override
  String toString() {
    return 'AssistantState.idle(imageUrl: $imageUrl)';
  }
}

/// @nodoc
abstract mixin class $IdleCopyWith<$Res>
    implements $AssistantStateCopyWith<$Res> {
  factory $IdleCopyWith(Idle value, $Res Function(Idle) _then) =
      _$IdleCopyWithImpl;
  @useResult
  $Res call({String imageUrl});
}

/// @nodoc
class _$IdleCopyWithImpl<$Res> implements $IdleCopyWith<$Res> {
  _$IdleCopyWithImpl(this._self, this._then);

  final Idle _self;
  final $Res Function(Idle) _then;

  /// Create a copy of AssistantState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? imageUrl = null,
  }) {
    return _then(Idle(
      imageUrl: null == imageUrl
          ? _self.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class Starting implements AssistantState {
  const Starting();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is Starting);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AssistantState.starting()';
  }
}

/// @nodoc

class Connecting implements AssistantState {
  const Connecting();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is Connecting);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AssistantState.connecting()';
  }
}

/// @nodoc

class Listening implements AssistantState {
  const Listening(
      {this.interimTranscript = '',
      this.statusLabel = '',
      this.welcomeText = '',
      this.imageUrl = ''});

  @JsonKey()
  final String interimTranscript;
  @JsonKey()
  final String statusLabel;
  @JsonKey()
  final String welcomeText;
  @JsonKey()
  final String imageUrl;

  /// Create a copy of AssistantState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ListeningCopyWith<Listening> get copyWith =>
      _$ListeningCopyWithImpl<Listening>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Listening &&
            (identical(other.interimTranscript, interimTranscript) ||
                other.interimTranscript == interimTranscript) &&
            (identical(other.statusLabel, statusLabel) ||
                other.statusLabel == statusLabel) &&
            (identical(other.welcomeText, welcomeText) ||
                other.welcomeText == welcomeText) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, interimTranscript, statusLabel, welcomeText, imageUrl);

  @override
  String toString() {
    return 'AssistantState.listening(interimTranscript: $interimTranscript, statusLabel: $statusLabel, welcomeText: $welcomeText, imageUrl: $imageUrl)';
  }
}

/// @nodoc
abstract mixin class $ListeningCopyWith<$Res>
    implements $AssistantStateCopyWith<$Res> {
  factory $ListeningCopyWith(Listening value, $Res Function(Listening) _then) =
      _$ListeningCopyWithImpl;
  @useResult
  $Res call(
      {String interimTranscript,
      String statusLabel,
      String welcomeText,
      String imageUrl});
}

/// @nodoc
class _$ListeningCopyWithImpl<$Res> implements $ListeningCopyWith<$Res> {
  _$ListeningCopyWithImpl(this._self, this._then);

  final Listening _self;
  final $Res Function(Listening) _then;

  /// Create a copy of AssistantState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? interimTranscript = null,
    Object? statusLabel = null,
    Object? welcomeText = null,
    Object? imageUrl = null,
  }) {
    return _then(Listening(
      interimTranscript: null == interimTranscript
          ? _self.interimTranscript
          : interimTranscript // ignore: cast_nullable_to_non_nullable
              as String,
      statusLabel: null == statusLabel
          ? _self.statusLabel
          : statusLabel // ignore: cast_nullable_to_non_nullable
              as String,
      welcomeText: null == welcomeText
          ? _self.welcomeText
          : welcomeText // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _self.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class Speaking implements AssistantState {
  const Speaking(
      {this.responseText = '', this.userTranscript = '', this.imageUrl = ''});

  @JsonKey()
  final String responseText;
  @JsonKey()
  final String userTranscript;
  @JsonKey()
  final String imageUrl;

  /// Create a copy of AssistantState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SpeakingCopyWith<Speaking> get copyWith =>
      _$SpeakingCopyWithImpl<Speaking>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Speaking &&
            (identical(other.responseText, responseText) ||
                other.responseText == responseText) &&
            (identical(other.userTranscript, userTranscript) ||
                other.userTranscript == userTranscript) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, responseText, userTranscript, imageUrl);

  @override
  String toString() {
    return 'AssistantState.speaking(responseText: $responseText, userTranscript: $userTranscript, imageUrl: $imageUrl)';
  }
}

/// @nodoc
abstract mixin class $SpeakingCopyWith<$Res>
    implements $AssistantStateCopyWith<$Res> {
  factory $SpeakingCopyWith(Speaking value, $Res Function(Speaking) _then) =
      _$SpeakingCopyWithImpl;
  @useResult
  $Res call({String responseText, String userTranscript, String imageUrl});
}

/// @nodoc
class _$SpeakingCopyWithImpl<$Res> implements $SpeakingCopyWith<$Res> {
  _$SpeakingCopyWithImpl(this._self, this._then);

  final Speaking _self;
  final $Res Function(Speaking) _then;

  /// Create a copy of AssistantState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? responseText = null,
    Object? userTranscript = null,
    Object? imageUrl = null,
  }) {
    return _then(Speaking(
      responseText: null == responseText
          ? _self.responseText
          : responseText // ignore: cast_nullable_to_non_nullable
              as String,
      userTranscript: null == userTranscript
          ? _self.userTranscript
          : userTranscript // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _self.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class AssistantError implements AssistantState {
  const AssistantError({required this.message});

  final String message;

  /// Create a copy of AssistantState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AssistantErrorCopyWith<AssistantError> get copyWith =>
      _$AssistantErrorCopyWithImpl<AssistantError>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AssistantError &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() {
    return 'AssistantState.error(message: $message)';
  }
}

/// @nodoc
abstract mixin class $AssistantErrorCopyWith<$Res>
    implements $AssistantStateCopyWith<$Res> {
  factory $AssistantErrorCopyWith(
          AssistantError value, $Res Function(AssistantError) _then) =
      _$AssistantErrorCopyWithImpl;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$AssistantErrorCopyWithImpl<$Res>
    implements $AssistantErrorCopyWith<$Res> {
  _$AssistantErrorCopyWithImpl(this._self, this._then);

  final AssistantError _self;
  final $Res Function(AssistantError) _then;

  /// Create a copy of AssistantState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = null,
  }) {
    return _then(AssistantError(
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
