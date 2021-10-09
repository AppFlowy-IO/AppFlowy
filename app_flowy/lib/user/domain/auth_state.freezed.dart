// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'auth_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
class _$AuthStateTearOff {
  const _$AuthStateTearOff();

  Authenticated authenticated(UserProfile userProfile) {
    return Authenticated(
      userProfile,
    );
  }

  Unauthenticated unauthenticated(UserError error) {
    return Unauthenticated(
      error,
    );
  }

  _Initial initial() {
    return const _Initial();
  }
}

/// @nodoc
const $AuthState = _$AuthStateTearOff();

/// @nodoc
mixin _$AuthState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(UserProfile userProfile) authenticated,
    required TResult Function(UserError error) unauthenticated,
    required TResult Function() initial,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(UserProfile userProfile)? authenticated,
    TResult Function(UserError error)? unauthenticated,
    TResult Function()? initial,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Authenticated value) authenticated,
    required TResult Function(Unauthenticated value) unauthenticated,
    required TResult Function(_Initial value) initial,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Authenticated value)? authenticated,
    TResult Function(Unauthenticated value)? unauthenticated,
    TResult Function(_Initial value)? initial,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthStateCopyWith<$Res> {
  factory $AuthStateCopyWith(AuthState value, $Res Function(AuthState) then) =
      _$AuthStateCopyWithImpl<$Res>;
}

/// @nodoc
class _$AuthStateCopyWithImpl<$Res> implements $AuthStateCopyWith<$Res> {
  _$AuthStateCopyWithImpl(this._value, this._then);

  final AuthState _value;
  // ignore: unused_field
  final $Res Function(AuthState) _then;
}

/// @nodoc
abstract class $AuthenticatedCopyWith<$Res> {
  factory $AuthenticatedCopyWith(
          Authenticated value, $Res Function(Authenticated) then) =
      _$AuthenticatedCopyWithImpl<$Res>;
  $Res call({UserProfile userProfile});
}

/// @nodoc
class _$AuthenticatedCopyWithImpl<$Res> extends _$AuthStateCopyWithImpl<$Res>
    implements $AuthenticatedCopyWith<$Res> {
  _$AuthenticatedCopyWithImpl(
      Authenticated _value, $Res Function(Authenticated) _then)
      : super(_value, (v) => _then(v as Authenticated));

  @override
  Authenticated get _value => super._value as Authenticated;

  @override
  $Res call({
    Object? userProfile = freezed,
  }) {
    return _then(Authenticated(
      userProfile == freezed
          ? _value.userProfile
          : userProfile // ignore: cast_nullable_to_non_nullable
              as UserProfile,
    ));
  }
}

/// @nodoc

class _$Authenticated implements Authenticated {
  const _$Authenticated(this.userProfile);

  @override
  final UserProfile userProfile;

  @override
  String toString() {
    return 'AuthState.authenticated(userProfile: $userProfile)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is Authenticated &&
            (identical(other.userProfile, userProfile) ||
                const DeepCollectionEquality()
                    .equals(other.userProfile, userProfile)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(userProfile);

  @JsonKey(ignore: true)
  @override
  $AuthenticatedCopyWith<Authenticated> get copyWith =>
      _$AuthenticatedCopyWithImpl<Authenticated>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(UserProfile userProfile) authenticated,
    required TResult Function(UserError error) unauthenticated,
    required TResult Function() initial,
  }) {
    return authenticated(userProfile);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(UserProfile userProfile)? authenticated,
    TResult Function(UserError error)? unauthenticated,
    TResult Function()? initial,
    required TResult orElse(),
  }) {
    if (authenticated != null) {
      return authenticated(userProfile);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Authenticated value) authenticated,
    required TResult Function(Unauthenticated value) unauthenticated,
    required TResult Function(_Initial value) initial,
  }) {
    return authenticated(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Authenticated value)? authenticated,
    TResult Function(Unauthenticated value)? unauthenticated,
    TResult Function(_Initial value)? initial,
    required TResult orElse(),
  }) {
    if (authenticated != null) {
      return authenticated(this);
    }
    return orElse();
  }
}

abstract class Authenticated implements AuthState {
  const factory Authenticated(UserProfile userProfile) = _$Authenticated;

  UserProfile get userProfile => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AuthenticatedCopyWith<Authenticated> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UnauthenticatedCopyWith<$Res> {
  factory $UnauthenticatedCopyWith(
          Unauthenticated value, $Res Function(Unauthenticated) then) =
      _$UnauthenticatedCopyWithImpl<$Res>;
  $Res call({UserError error});
}

/// @nodoc
class _$UnauthenticatedCopyWithImpl<$Res> extends _$AuthStateCopyWithImpl<$Res>
    implements $UnauthenticatedCopyWith<$Res> {
  _$UnauthenticatedCopyWithImpl(
      Unauthenticated _value, $Res Function(Unauthenticated) _then)
      : super(_value, (v) => _then(v as Unauthenticated));

  @override
  Unauthenticated get _value => super._value as Unauthenticated;

  @override
  $Res call({
    Object? error = freezed,
  }) {
    return _then(Unauthenticated(
      error == freezed
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as UserError,
    ));
  }
}

/// @nodoc

class _$Unauthenticated implements Unauthenticated {
  const _$Unauthenticated(this.error);

  @override
  final UserError error;

  @override
  String toString() {
    return 'AuthState.unauthenticated(error: $error)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is Unauthenticated &&
            (identical(other.error, error) ||
                const DeepCollectionEquality().equals(other.error, error)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(error);

  @JsonKey(ignore: true)
  @override
  $UnauthenticatedCopyWith<Unauthenticated> get copyWith =>
      _$UnauthenticatedCopyWithImpl<Unauthenticated>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(UserProfile userProfile) authenticated,
    required TResult Function(UserError error) unauthenticated,
    required TResult Function() initial,
  }) {
    return unauthenticated(error);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(UserProfile userProfile)? authenticated,
    TResult Function(UserError error)? unauthenticated,
    TResult Function()? initial,
    required TResult orElse(),
  }) {
    if (unauthenticated != null) {
      return unauthenticated(error);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Authenticated value) authenticated,
    required TResult Function(Unauthenticated value) unauthenticated,
    required TResult Function(_Initial value) initial,
  }) {
    return unauthenticated(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Authenticated value)? authenticated,
    TResult Function(Unauthenticated value)? unauthenticated,
    TResult Function(_Initial value)? initial,
    required TResult orElse(),
  }) {
    if (unauthenticated != null) {
      return unauthenticated(this);
    }
    return orElse();
  }
}

abstract class Unauthenticated implements AuthState {
  const factory Unauthenticated(UserError error) = _$Unauthenticated;

  UserError get error => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UnauthenticatedCopyWith<Unauthenticated> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$InitialCopyWith<$Res> {
  factory _$InitialCopyWith(_Initial value, $Res Function(_Initial) then) =
      __$InitialCopyWithImpl<$Res>;
}

/// @nodoc
class __$InitialCopyWithImpl<$Res> extends _$AuthStateCopyWithImpl<$Res>
    implements _$InitialCopyWith<$Res> {
  __$InitialCopyWithImpl(_Initial _value, $Res Function(_Initial) _then)
      : super(_value, (v) => _then(v as _Initial));

  @override
  _Initial get _value => super._value as _Initial;
}

/// @nodoc

class _$_Initial implements _Initial {
  const _$_Initial();

  @override
  String toString() {
    return 'AuthState.initial()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) || (other is _Initial);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(UserProfile userProfile) authenticated,
    required TResult Function(UserError error) unauthenticated,
    required TResult Function() initial,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(UserProfile userProfile)? authenticated,
    TResult Function(UserError error)? unauthenticated,
    TResult Function()? initial,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Authenticated value) authenticated,
    required TResult Function(Unauthenticated value) unauthenticated,
    required TResult Function(_Initial value) initial,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Authenticated value)? authenticated,
    TResult Function(Unauthenticated value)? unauthenticated,
    TResult Function(_Initial value)? initial,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _Initial implements AuthState {
  const factory _Initial() = _$_Initial;
}
