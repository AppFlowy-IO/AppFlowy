// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides

part of 'welcome_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
class _$WelcomeEventTearOff {
  const _$WelcomeEventTearOff();

  _Check check() {
    return const _Check();
  }

  _AuthCheck authCheck() {
    return const _AuthCheck();
  }
}

/// @nodoc
const $WelcomeEvent = _$WelcomeEventTearOff();

/// @nodoc
mixin _$WelcomeEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() check,
    required TResult Function() authCheck,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? check,
    TResult Function()? authCheck,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Check value) check,
    required TResult Function(_AuthCheck value) authCheck,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Check value)? check,
    TResult Function(_AuthCheck value)? authCheck,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WelcomeEventCopyWith<$Res> {
  factory $WelcomeEventCopyWith(
          WelcomeEvent value, $Res Function(WelcomeEvent) then) =
      _$WelcomeEventCopyWithImpl<$Res>;
}

/// @nodoc
class _$WelcomeEventCopyWithImpl<$Res> implements $WelcomeEventCopyWith<$Res> {
  _$WelcomeEventCopyWithImpl(this._value, this._then);

  final WelcomeEvent _value;
  // ignore: unused_field
  final $Res Function(WelcomeEvent) _then;
}

/// @nodoc
abstract class _$CheckCopyWith<$Res> {
  factory _$CheckCopyWith(_Check value, $Res Function(_Check) then) =
      __$CheckCopyWithImpl<$Res>;
}

/// @nodoc
class __$CheckCopyWithImpl<$Res> extends _$WelcomeEventCopyWithImpl<$Res>
    implements _$CheckCopyWith<$Res> {
  __$CheckCopyWithImpl(_Check _value, $Res Function(_Check) _then)
      : super(_value, (v) => _then(v as _Check));

  @override
  _Check get _value => super._value as _Check;
}

/// @nodoc

class _$_Check implements _Check {
  const _$_Check();

  @override
  String toString() {
    return 'WelcomeEvent.check()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) || (other is _Check);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() check,
    required TResult Function() authCheck,
  }) {
    return check();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? check,
    TResult Function()? authCheck,
    required TResult orElse(),
  }) {
    if (check != null) {
      return check();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Check value) check,
    required TResult Function(_AuthCheck value) authCheck,
  }) {
    return check(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Check value)? check,
    TResult Function(_AuthCheck value)? authCheck,
    required TResult orElse(),
  }) {
    if (check != null) {
      return check(this);
    }
    return orElse();
  }
}

abstract class _Check implements WelcomeEvent {
  const factory _Check() = _$_Check;
}

/// @nodoc
abstract class _$AuthCheckCopyWith<$Res> {
  factory _$AuthCheckCopyWith(
          _AuthCheck value, $Res Function(_AuthCheck) then) =
      __$AuthCheckCopyWithImpl<$Res>;
}

/// @nodoc
class __$AuthCheckCopyWithImpl<$Res> extends _$WelcomeEventCopyWithImpl<$Res>
    implements _$AuthCheckCopyWith<$Res> {
  __$AuthCheckCopyWithImpl(_AuthCheck _value, $Res Function(_AuthCheck) _then)
      : super(_value, (v) => _then(v as _AuthCheck));

  @override
  _AuthCheck get _value => super._value as _AuthCheck;
}

/// @nodoc

class _$_AuthCheck implements _AuthCheck {
  const _$_AuthCheck();

  @override
  String toString() {
    return 'WelcomeEvent.authCheck()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) || (other is _AuthCheck);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() check,
    required TResult Function() authCheck,
  }) {
    return authCheck();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? check,
    TResult Function()? authCheck,
    required TResult orElse(),
  }) {
    if (authCheck != null) {
      return authCheck();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Check value) check,
    required TResult Function(_AuthCheck value) authCheck,
  }) {
    return authCheck(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Check value)? check,
    TResult Function(_AuthCheck value)? authCheck,
    required TResult orElse(),
  }) {
    if (authCheck != null) {
      return authCheck(this);
    }
    return orElse();
  }
}

abstract class _AuthCheck implements WelcomeEvent {
  const factory _AuthCheck() = _$_AuthCheck;
}

/// @nodoc
class _$WelcomeStateTearOff {
  const _$WelcomeStateTearOff();

  _WelcomeState call({required AuthState auth}) {
    return _WelcomeState(
      auth: auth,
    );
  }
}

/// @nodoc
const $WelcomeState = _$WelcomeStateTearOff();

/// @nodoc
mixin _$WelcomeState {
  AuthState get auth => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $WelcomeStateCopyWith<WelcomeState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WelcomeStateCopyWith<$Res> {
  factory $WelcomeStateCopyWith(
          WelcomeState value, $Res Function(WelcomeState) then) =
      _$WelcomeStateCopyWithImpl<$Res>;
  $Res call({AuthState auth});

  $AuthStateCopyWith<$Res> get auth;
}

/// @nodoc
class _$WelcomeStateCopyWithImpl<$Res> implements $WelcomeStateCopyWith<$Res> {
  _$WelcomeStateCopyWithImpl(this._value, this._then);

  final WelcomeState _value;
  // ignore: unused_field
  final $Res Function(WelcomeState) _then;

  @override
  $Res call({
    Object? auth = freezed,
  }) {
    return _then(_value.copyWith(
      auth: auth == freezed
          ? _value.auth
          : auth // ignore: cast_nullable_to_non_nullable
              as AuthState,
    ));
  }

  @override
  $AuthStateCopyWith<$Res> get auth {
    return $AuthStateCopyWith<$Res>(_value.auth, (value) {
      return _then(_value.copyWith(auth: value));
    });
  }
}

/// @nodoc
abstract class _$WelcomeStateCopyWith<$Res>
    implements $WelcomeStateCopyWith<$Res> {
  factory _$WelcomeStateCopyWith(
          _WelcomeState value, $Res Function(_WelcomeState) then) =
      __$WelcomeStateCopyWithImpl<$Res>;
  @override
  $Res call({AuthState auth});

  @override
  $AuthStateCopyWith<$Res> get auth;
}

/// @nodoc
class __$WelcomeStateCopyWithImpl<$Res> extends _$WelcomeStateCopyWithImpl<$Res>
    implements _$WelcomeStateCopyWith<$Res> {
  __$WelcomeStateCopyWithImpl(
      _WelcomeState _value, $Res Function(_WelcomeState) _then)
      : super(_value, (v) => _then(v as _WelcomeState));

  @override
  _WelcomeState get _value => super._value as _WelcomeState;

  @override
  $Res call({
    Object? auth = freezed,
  }) {
    return _then(_WelcomeState(
      auth: auth == freezed
          ? _value.auth
          : auth // ignore: cast_nullable_to_non_nullable
              as AuthState,
    ));
  }
}

/// @nodoc

class _$_WelcomeState implements _WelcomeState {
  const _$_WelcomeState({required this.auth});

  @override
  final AuthState auth;

  @override
  String toString() {
    return 'WelcomeState(auth: $auth)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _WelcomeState &&
            (identical(other.auth, auth) ||
                const DeepCollectionEquality().equals(other.auth, auth)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(auth);

  @JsonKey(ignore: true)
  @override
  _$WelcomeStateCopyWith<_WelcomeState> get copyWith =>
      __$WelcomeStateCopyWithImpl<_WelcomeState>(this, _$identity);
}

abstract class _WelcomeState implements WelcomeState {
  const factory _WelcomeState({required AuthState auth}) = _$_WelcomeState;

  @override
  AuthState get auth => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$WelcomeStateCopyWith<_WelcomeState> get copyWith =>
      throw _privateConstructorUsedError;
}
