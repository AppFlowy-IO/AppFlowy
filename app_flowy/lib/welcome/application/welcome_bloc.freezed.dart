// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

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

  _GetUser getUser() {
    return const _GetUser();
  }
}

/// @nodoc
const $WelcomeEvent = _$WelcomeEventTearOff();

/// @nodoc
mixin _$WelcomeEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() getUser,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? getUser,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_GetUser value) getUser,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_GetUser value)? getUser,
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
abstract class _$GetUserCopyWith<$Res> {
  factory _$GetUserCopyWith(_GetUser value, $Res Function(_GetUser) then) =
      __$GetUserCopyWithImpl<$Res>;
}

/// @nodoc
class __$GetUserCopyWithImpl<$Res> extends _$WelcomeEventCopyWithImpl<$Res>
    implements _$GetUserCopyWith<$Res> {
  __$GetUserCopyWithImpl(_GetUser _value, $Res Function(_GetUser) _then)
      : super(_value, (v) => _then(v as _GetUser));

  @override
  _GetUser get _value => super._value as _GetUser;
}

/// @nodoc

class _$_GetUser implements _GetUser {
  const _$_GetUser();

  @override
  String toString() {
    return 'WelcomeEvent.getUser()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) || (other is _GetUser);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() getUser,
  }) {
    return getUser();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? getUser,
    required TResult orElse(),
  }) {
    if (getUser != null) {
      return getUser();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_GetUser value) getUser,
  }) {
    return getUser(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_GetUser value)? getUser,
    required TResult orElse(),
  }) {
    if (getUser != null) {
      return getUser(this);
    }
    return orElse();
  }
}

abstract class _GetUser implements WelcomeEvent {
  const factory _GetUser() = _$_GetUser;
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
