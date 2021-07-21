// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides

part of 'app_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
class _$AppEventTearOff {
  const _$AppEventTearOff();

  AppsReceived appsReceived(Either<List<App>, WorkspaceError> appsOrFail) {
    return AppsReceived(
      appsOrFail,
    );
  }
}

/// @nodoc
const $AppEvent = _$AppEventTearOff();

/// @nodoc
mixin _$AppEvent {
  Either<List<App>, WorkspaceError> get appsOrFail =>
      throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Either<List<App>, WorkspaceError> appsOrFail)
        appsReceived,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Either<List<App>, WorkspaceError> appsOrFail)?
        appsReceived,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AppsReceived value) appsReceived,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AppsReceived value)? appsReceived,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $AppEventCopyWith<AppEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppEventCopyWith<$Res> {
  factory $AppEventCopyWith(AppEvent value, $Res Function(AppEvent) then) =
      _$AppEventCopyWithImpl<$Res>;
  $Res call({Either<List<App>, WorkspaceError> appsOrFail});
}

/// @nodoc
class _$AppEventCopyWithImpl<$Res> implements $AppEventCopyWith<$Res> {
  _$AppEventCopyWithImpl(this._value, this._then);

  final AppEvent _value;
  // ignore: unused_field
  final $Res Function(AppEvent) _then;

  @override
  $Res call({
    Object? appsOrFail = freezed,
  }) {
    return _then(_value.copyWith(
      appsOrFail: appsOrFail == freezed
          ? _value.appsOrFail
          : appsOrFail // ignore: cast_nullable_to_non_nullable
              as Either<List<App>, WorkspaceError>,
    ));
  }
}

/// @nodoc
abstract class $AppsReceivedCopyWith<$Res> implements $AppEventCopyWith<$Res> {
  factory $AppsReceivedCopyWith(
          AppsReceived value, $Res Function(AppsReceived) then) =
      _$AppsReceivedCopyWithImpl<$Res>;
  @override
  $Res call({Either<List<App>, WorkspaceError> appsOrFail});
}

/// @nodoc
class _$AppsReceivedCopyWithImpl<$Res> extends _$AppEventCopyWithImpl<$Res>
    implements $AppsReceivedCopyWith<$Res> {
  _$AppsReceivedCopyWithImpl(
      AppsReceived _value, $Res Function(AppsReceived) _then)
      : super(_value, (v) => _then(v as AppsReceived));

  @override
  AppsReceived get _value => super._value as AppsReceived;

  @override
  $Res call({
    Object? appsOrFail = freezed,
  }) {
    return _then(AppsReceived(
      appsOrFail == freezed
          ? _value.appsOrFail
          : appsOrFail // ignore: cast_nullable_to_non_nullable
              as Either<List<App>, WorkspaceError>,
    ));
  }
}

/// @nodoc

class _$AppsReceived implements AppsReceived {
  const _$AppsReceived(this.appsOrFail);

  @override
  final Either<List<App>, WorkspaceError> appsOrFail;

  @override
  String toString() {
    return 'AppEvent.appsReceived(appsOrFail: $appsOrFail)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is AppsReceived &&
            (identical(other.appsOrFail, appsOrFail) ||
                const DeepCollectionEquality()
                    .equals(other.appsOrFail, appsOrFail)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(appsOrFail);

  @JsonKey(ignore: true)
  @override
  $AppsReceivedCopyWith<AppsReceived> get copyWith =>
      _$AppsReceivedCopyWithImpl<AppsReceived>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Either<List<App>, WorkspaceError> appsOrFail)
        appsReceived,
  }) {
    return appsReceived(appsOrFail);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Either<List<App>, WorkspaceError> appsOrFail)?
        appsReceived,
    required TResult orElse(),
  }) {
    if (appsReceived != null) {
      return appsReceived(appsOrFail);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AppsReceived value) appsReceived,
  }) {
    return appsReceived(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AppsReceived value)? appsReceived,
    required TResult orElse(),
  }) {
    if (appsReceived != null) {
      return appsReceived(this);
    }
    return orElse();
  }
}

abstract class AppsReceived implements AppEvent {
  const factory AppsReceived(Either<List<App>, WorkspaceError> appsOrFail) =
      _$AppsReceived;

  @override
  Either<List<App>, WorkspaceError> get appsOrFail =>
      throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  $AppsReceivedCopyWith<AppsReceived> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
class _$AppStateTearOff {
  const _$AppStateTearOff();

  _AppState call(
      {required Option<List<App>> apps,
      required Either<Unit, WorkspaceError> successOrFailure}) {
    return _AppState(
      apps: apps,
      successOrFailure: successOrFailure,
    );
  }
}

/// @nodoc
const $AppState = _$AppStateTearOff();

/// @nodoc
mixin _$AppState {
  Option<List<App>> get apps => throw _privateConstructorUsedError;
  Either<Unit, WorkspaceError> get successOrFailure =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $AppStateCopyWith<AppState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppStateCopyWith<$Res> {
  factory $AppStateCopyWith(AppState value, $Res Function(AppState) then) =
      _$AppStateCopyWithImpl<$Res>;
  $Res call(
      {Option<List<App>> apps, Either<Unit, WorkspaceError> successOrFailure});
}

/// @nodoc
class _$AppStateCopyWithImpl<$Res> implements $AppStateCopyWith<$Res> {
  _$AppStateCopyWithImpl(this._value, this._then);

  final AppState _value;
  // ignore: unused_field
  final $Res Function(AppState) _then;

  @override
  $Res call({
    Object? apps = freezed,
    Object? successOrFailure = freezed,
  }) {
    return _then(_value.copyWith(
      apps: apps == freezed
          ? _value.apps
          : apps // ignore: cast_nullable_to_non_nullable
              as Option<List<App>>,
      successOrFailure: successOrFailure == freezed
          ? _value.successOrFailure
          : successOrFailure // ignore: cast_nullable_to_non_nullable
              as Either<Unit, WorkspaceError>,
    ));
  }
}

/// @nodoc
abstract class _$AppStateCopyWith<$Res> implements $AppStateCopyWith<$Res> {
  factory _$AppStateCopyWith(_AppState value, $Res Function(_AppState) then) =
      __$AppStateCopyWithImpl<$Res>;
  @override
  $Res call(
      {Option<List<App>> apps, Either<Unit, WorkspaceError> successOrFailure});
}

/// @nodoc
class __$AppStateCopyWithImpl<$Res> extends _$AppStateCopyWithImpl<$Res>
    implements _$AppStateCopyWith<$Res> {
  __$AppStateCopyWithImpl(_AppState _value, $Res Function(_AppState) _then)
      : super(_value, (v) => _then(v as _AppState));

  @override
  _AppState get _value => super._value as _AppState;

  @override
  $Res call({
    Object? apps = freezed,
    Object? successOrFailure = freezed,
  }) {
    return _then(_AppState(
      apps: apps == freezed
          ? _value.apps
          : apps // ignore: cast_nullable_to_non_nullable
              as Option<List<App>>,
      successOrFailure: successOrFailure == freezed
          ? _value.successOrFailure
          : successOrFailure // ignore: cast_nullable_to_non_nullable
              as Either<Unit, WorkspaceError>,
    ));
  }
}

/// @nodoc

class _$_AppState implements _AppState {
  const _$_AppState({required this.apps, required this.successOrFailure});

  @override
  final Option<List<App>> apps;
  @override
  final Either<Unit, WorkspaceError> successOrFailure;

  @override
  String toString() {
    return 'AppState(apps: $apps, successOrFailure: $successOrFailure)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _AppState &&
            (identical(other.apps, apps) ||
                const DeepCollectionEquality().equals(other.apps, apps)) &&
            (identical(other.successOrFailure, successOrFailure) ||
                const DeepCollectionEquality()
                    .equals(other.successOrFailure, successOrFailure)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(apps) ^
      const DeepCollectionEquality().hash(successOrFailure);

  @JsonKey(ignore: true)
  @override
  _$AppStateCopyWith<_AppState> get copyWith =>
      __$AppStateCopyWithImpl<_AppState>(this, _$identity);
}

abstract class _AppState implements AppState {
  const factory _AppState(
      {required Option<List<App>> apps,
      required Either<Unit, WorkspaceError> successOrFailure}) = _$_AppState;

  @override
  Option<List<App>> get apps => throw _privateConstructorUsedError;
  @override
  Either<Unit, WorkspaceError> get successOrFailure =>
      throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$AppStateCopyWith<_AppState> get copyWith =>
      throw _privateConstructorUsedError;
}
