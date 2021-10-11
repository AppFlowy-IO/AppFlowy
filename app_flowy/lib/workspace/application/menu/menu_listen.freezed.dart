// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'menu_listen.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
class _$MenuListenEventTearOff {
  const _$MenuListenEventTearOff();

  _Started started() {
    return const _Started();
  }

  AppsReceived appsReceived(Either<List<App>, WorkspaceError> appsOrFail) {
    return AppsReceived(
      appsOrFail,
    );
  }
}

/// @nodoc
const $MenuListenEvent = _$MenuListenEventTearOff();

/// @nodoc
mixin _$MenuListenEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(Either<List<App>, WorkspaceError> appsOrFail)
        appsReceived,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(Either<List<App>, WorkspaceError> appsOrFail)?
        appsReceived,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Started value) started,
    required TResult Function(AppsReceived value) appsReceived,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Started value)? started,
    TResult Function(AppsReceived value)? appsReceived,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MenuListenEventCopyWith<$Res> {
  factory $MenuListenEventCopyWith(
          MenuListenEvent value, $Res Function(MenuListenEvent) then) =
      _$MenuListenEventCopyWithImpl<$Res>;
}

/// @nodoc
class _$MenuListenEventCopyWithImpl<$Res>
    implements $MenuListenEventCopyWith<$Res> {
  _$MenuListenEventCopyWithImpl(this._value, this._then);

  final MenuListenEvent _value;
  // ignore: unused_field
  final $Res Function(MenuListenEvent) _then;
}

/// @nodoc
abstract class _$StartedCopyWith<$Res> {
  factory _$StartedCopyWith(_Started value, $Res Function(_Started) then) =
      __$StartedCopyWithImpl<$Res>;
}

/// @nodoc
class __$StartedCopyWithImpl<$Res> extends _$MenuListenEventCopyWithImpl<$Res>
    implements _$StartedCopyWith<$Res> {
  __$StartedCopyWithImpl(_Started _value, $Res Function(_Started) _then)
      : super(_value, (v) => _then(v as _Started));

  @override
  _Started get _value => super._value as _Started;
}

/// @nodoc

class _$_Started implements _Started {
  const _$_Started();

  @override
  String toString() {
    return 'MenuListenEvent.started()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) || (other is _Started);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(Either<List<App>, WorkspaceError> appsOrFail)
        appsReceived,
  }) {
    return started();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(Either<List<App>, WorkspaceError> appsOrFail)?
        appsReceived,
    required TResult orElse(),
  }) {
    if (started != null) {
      return started();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Started value) started,
    required TResult Function(AppsReceived value) appsReceived,
  }) {
    return started(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Started value)? started,
    TResult Function(AppsReceived value)? appsReceived,
    required TResult orElse(),
  }) {
    if (started != null) {
      return started(this);
    }
    return orElse();
  }
}

abstract class _Started implements MenuListenEvent {
  const factory _Started() = _$_Started;
}

/// @nodoc
abstract class $AppsReceivedCopyWith<$Res> {
  factory $AppsReceivedCopyWith(
          AppsReceived value, $Res Function(AppsReceived) then) =
      _$AppsReceivedCopyWithImpl<$Res>;
  $Res call({Either<List<App>, WorkspaceError> appsOrFail});
}

/// @nodoc
class _$AppsReceivedCopyWithImpl<$Res>
    extends _$MenuListenEventCopyWithImpl<$Res>
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
    return 'MenuListenEvent.appsReceived(appsOrFail: $appsOrFail)';
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
    required TResult Function() started,
    required TResult Function(Either<List<App>, WorkspaceError> appsOrFail)
        appsReceived,
  }) {
    return appsReceived(appsOrFail);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
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
    required TResult Function(_Started value) started,
    required TResult Function(AppsReceived value) appsReceived,
  }) {
    return appsReceived(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Started value)? started,
    TResult Function(AppsReceived value)? appsReceived,
    required TResult orElse(),
  }) {
    if (appsReceived != null) {
      return appsReceived(this);
    }
    return orElse();
  }
}

abstract class AppsReceived implements MenuListenEvent {
  const factory AppsReceived(Either<List<App>, WorkspaceError> appsOrFail) =
      _$AppsReceived;

  Either<List<App>, WorkspaceError> get appsOrFail =>
      throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AppsReceivedCopyWith<AppsReceived> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
class _$MenuListenStateTearOff {
  const _$MenuListenStateTearOff();

  _Initial initial() {
    return const _Initial();
  }

  _LoadApps loadApps(List<App> apps) {
    return _LoadApps(
      apps,
    );
  }

  _LoadFail loadFail(WorkspaceError error) {
    return _LoadFail(
      error,
    );
  }
}

/// @nodoc
const $MenuListenState = _$MenuListenStateTearOff();

/// @nodoc
mixin _$MenuListenState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(List<App> apps) loadApps,
    required TResult Function(WorkspaceError error) loadFail,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<App> apps)? loadApps,
    TResult Function(WorkspaceError error)? loadFail,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_LoadApps value) loadApps,
    required TResult Function(_LoadFail value) loadFail,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_LoadApps value)? loadApps,
    TResult Function(_LoadFail value)? loadFail,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MenuListenStateCopyWith<$Res> {
  factory $MenuListenStateCopyWith(
          MenuListenState value, $Res Function(MenuListenState) then) =
      _$MenuListenStateCopyWithImpl<$Res>;
}

/// @nodoc
class _$MenuListenStateCopyWithImpl<$Res>
    implements $MenuListenStateCopyWith<$Res> {
  _$MenuListenStateCopyWithImpl(this._value, this._then);

  final MenuListenState _value;
  // ignore: unused_field
  final $Res Function(MenuListenState) _then;
}

/// @nodoc
abstract class _$InitialCopyWith<$Res> {
  factory _$InitialCopyWith(_Initial value, $Res Function(_Initial) then) =
      __$InitialCopyWithImpl<$Res>;
}

/// @nodoc
class __$InitialCopyWithImpl<$Res> extends _$MenuListenStateCopyWithImpl<$Res>
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
    return 'MenuListenState.initial()';
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
    required TResult Function() initial,
    required TResult Function(List<App> apps) loadApps,
    required TResult Function(WorkspaceError error) loadFail,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<App> apps)? loadApps,
    TResult Function(WorkspaceError error)? loadFail,
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
    required TResult Function(_Initial value) initial,
    required TResult Function(_LoadApps value) loadApps,
    required TResult Function(_LoadFail value) loadFail,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_LoadApps value)? loadApps,
    TResult Function(_LoadFail value)? loadFail,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _Initial implements MenuListenState {
  const factory _Initial() = _$_Initial;
}

/// @nodoc
abstract class _$LoadAppsCopyWith<$Res> {
  factory _$LoadAppsCopyWith(_LoadApps value, $Res Function(_LoadApps) then) =
      __$LoadAppsCopyWithImpl<$Res>;
  $Res call({List<App> apps});
}

/// @nodoc
class __$LoadAppsCopyWithImpl<$Res> extends _$MenuListenStateCopyWithImpl<$Res>
    implements _$LoadAppsCopyWith<$Res> {
  __$LoadAppsCopyWithImpl(_LoadApps _value, $Res Function(_LoadApps) _then)
      : super(_value, (v) => _then(v as _LoadApps));

  @override
  _LoadApps get _value => super._value as _LoadApps;

  @override
  $Res call({
    Object? apps = freezed,
  }) {
    return _then(_LoadApps(
      apps == freezed
          ? _value.apps
          : apps // ignore: cast_nullable_to_non_nullable
              as List<App>,
    ));
  }
}

/// @nodoc

class _$_LoadApps implements _LoadApps {
  const _$_LoadApps(this.apps);

  @override
  final List<App> apps;

  @override
  String toString() {
    return 'MenuListenState.loadApps(apps: $apps)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _LoadApps &&
            (identical(other.apps, apps) ||
                const DeepCollectionEquality().equals(other.apps, apps)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(apps);

  @JsonKey(ignore: true)
  @override
  _$LoadAppsCopyWith<_LoadApps> get copyWith =>
      __$LoadAppsCopyWithImpl<_LoadApps>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(List<App> apps) loadApps,
    required TResult Function(WorkspaceError error) loadFail,
  }) {
    return loadApps(apps);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<App> apps)? loadApps,
    TResult Function(WorkspaceError error)? loadFail,
    required TResult orElse(),
  }) {
    if (loadApps != null) {
      return loadApps(apps);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_LoadApps value) loadApps,
    required TResult Function(_LoadFail value) loadFail,
  }) {
    return loadApps(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_LoadApps value)? loadApps,
    TResult Function(_LoadFail value)? loadFail,
    required TResult orElse(),
  }) {
    if (loadApps != null) {
      return loadApps(this);
    }
    return orElse();
  }
}

abstract class _LoadApps implements MenuListenState {
  const factory _LoadApps(List<App> apps) = _$_LoadApps;

  List<App> get apps => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  _$LoadAppsCopyWith<_LoadApps> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$LoadFailCopyWith<$Res> {
  factory _$LoadFailCopyWith(_LoadFail value, $Res Function(_LoadFail) then) =
      __$LoadFailCopyWithImpl<$Res>;
  $Res call({WorkspaceError error});
}

/// @nodoc
class __$LoadFailCopyWithImpl<$Res> extends _$MenuListenStateCopyWithImpl<$Res>
    implements _$LoadFailCopyWith<$Res> {
  __$LoadFailCopyWithImpl(_LoadFail _value, $Res Function(_LoadFail) _then)
      : super(_value, (v) => _then(v as _LoadFail));

  @override
  _LoadFail get _value => super._value as _LoadFail;

  @override
  $Res call({
    Object? error = freezed,
  }) {
    return _then(_LoadFail(
      error == freezed
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as WorkspaceError,
    ));
  }
}

/// @nodoc

class _$_LoadFail implements _LoadFail {
  const _$_LoadFail(this.error);

  @override
  final WorkspaceError error;

  @override
  String toString() {
    return 'MenuListenState.loadFail(error: $error)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _LoadFail &&
            (identical(other.error, error) ||
                const DeepCollectionEquality().equals(other.error, error)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(error);

  @JsonKey(ignore: true)
  @override
  _$LoadFailCopyWith<_LoadFail> get copyWith =>
      __$LoadFailCopyWithImpl<_LoadFail>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(List<App> apps) loadApps,
    required TResult Function(WorkspaceError error) loadFail,
  }) {
    return loadFail(error);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<App> apps)? loadApps,
    TResult Function(WorkspaceError error)? loadFail,
    required TResult orElse(),
  }) {
    if (loadFail != null) {
      return loadFail(error);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_LoadApps value) loadApps,
    required TResult Function(_LoadFail value) loadFail,
  }) {
    return loadFail(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_LoadApps value)? loadApps,
    TResult Function(_LoadFail value)? loadFail,
    required TResult orElse(),
  }) {
    if (loadFail != null) {
      return loadFail(this);
    }
    return orElse();
  }
}

abstract class _LoadFail implements MenuListenState {
  const factory _LoadFail(WorkspaceError error) = _$_LoadFail;

  WorkspaceError get error => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  _$LoadFailCopyWith<_LoadFail> get copyWith =>
      throw _privateConstructorUsedError;
}
