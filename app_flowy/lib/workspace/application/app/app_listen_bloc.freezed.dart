// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'app_listen_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
class _$AppListenEventTearOff {
  const _$AppListenEventTearOff();

  _Started started() {
    return const _Started();
  }

  ViewsReceived didReceiveViews(
      Either<List<View>, WorkspaceError> viewsOrFail) {
    return ViewsReceived(
      viewsOrFail,
    );
  }
}

/// @nodoc
const $AppListenEvent = _$AppListenEventTearOff();

/// @nodoc
mixin _$AppListenEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(Either<List<View>, WorkspaceError> viewsOrFail)
        didReceiveViews,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(Either<List<View>, WorkspaceError> viewsOrFail)?
        didReceiveViews,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Started value) started,
    required TResult Function(ViewsReceived value) didReceiveViews,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Started value)? started,
    TResult Function(ViewsReceived value)? didReceiveViews,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppListenEventCopyWith<$Res> {
  factory $AppListenEventCopyWith(
          AppListenEvent value, $Res Function(AppListenEvent) then) =
      _$AppListenEventCopyWithImpl<$Res>;
}

/// @nodoc
class _$AppListenEventCopyWithImpl<$Res>
    implements $AppListenEventCopyWith<$Res> {
  _$AppListenEventCopyWithImpl(this._value, this._then);

  final AppListenEvent _value;
  // ignore: unused_field
  final $Res Function(AppListenEvent) _then;
}

/// @nodoc
abstract class _$StartedCopyWith<$Res> {
  factory _$StartedCopyWith(_Started value, $Res Function(_Started) then) =
      __$StartedCopyWithImpl<$Res>;
}

/// @nodoc
class __$StartedCopyWithImpl<$Res> extends _$AppListenEventCopyWithImpl<$Res>
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
    return 'AppListenEvent.started()';
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
    required TResult Function(Either<List<View>, WorkspaceError> viewsOrFail)
        didReceiveViews,
  }) {
    return started();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(Either<List<View>, WorkspaceError> viewsOrFail)?
        didReceiveViews,
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
    required TResult Function(ViewsReceived value) didReceiveViews,
  }) {
    return started(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Started value)? started,
    TResult Function(ViewsReceived value)? didReceiveViews,
    required TResult orElse(),
  }) {
    if (started != null) {
      return started(this);
    }
    return orElse();
  }
}

abstract class _Started implements AppListenEvent {
  const factory _Started() = _$_Started;
}

/// @nodoc
abstract class $ViewsReceivedCopyWith<$Res> {
  factory $ViewsReceivedCopyWith(
          ViewsReceived value, $Res Function(ViewsReceived) then) =
      _$ViewsReceivedCopyWithImpl<$Res>;
  $Res call({Either<List<View>, WorkspaceError> viewsOrFail});
}

/// @nodoc
class _$ViewsReceivedCopyWithImpl<$Res>
    extends _$AppListenEventCopyWithImpl<$Res>
    implements $ViewsReceivedCopyWith<$Res> {
  _$ViewsReceivedCopyWithImpl(
      ViewsReceived _value, $Res Function(ViewsReceived) _then)
      : super(_value, (v) => _then(v as ViewsReceived));

  @override
  ViewsReceived get _value => super._value as ViewsReceived;

  @override
  $Res call({
    Object? viewsOrFail = freezed,
  }) {
    return _then(ViewsReceived(
      viewsOrFail == freezed
          ? _value.viewsOrFail
          : viewsOrFail // ignore: cast_nullable_to_non_nullable
              as Either<List<View>, WorkspaceError>,
    ));
  }
}

/// @nodoc

class _$ViewsReceived implements ViewsReceived {
  const _$ViewsReceived(this.viewsOrFail);

  @override
  final Either<List<View>, WorkspaceError> viewsOrFail;

  @override
  String toString() {
    return 'AppListenEvent.didReceiveViews(viewsOrFail: $viewsOrFail)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is ViewsReceived &&
            (identical(other.viewsOrFail, viewsOrFail) ||
                const DeepCollectionEquality()
                    .equals(other.viewsOrFail, viewsOrFail)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(viewsOrFail);

  @JsonKey(ignore: true)
  @override
  $ViewsReceivedCopyWith<ViewsReceived> get copyWith =>
      _$ViewsReceivedCopyWithImpl<ViewsReceived>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(Either<List<View>, WorkspaceError> viewsOrFail)
        didReceiveViews,
  }) {
    return didReceiveViews(viewsOrFail);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(Either<List<View>, WorkspaceError> viewsOrFail)?
        didReceiveViews,
    required TResult orElse(),
  }) {
    if (didReceiveViews != null) {
      return didReceiveViews(viewsOrFail);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Started value) started,
    required TResult Function(ViewsReceived value) didReceiveViews,
  }) {
    return didReceiveViews(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Started value)? started,
    TResult Function(ViewsReceived value)? didReceiveViews,
    required TResult orElse(),
  }) {
    if (didReceiveViews != null) {
      return didReceiveViews(this);
    }
    return orElse();
  }
}

abstract class ViewsReceived implements AppListenEvent {
  const factory ViewsReceived(Either<List<View>, WorkspaceError> viewsOrFail) =
      _$ViewsReceived;

  Either<List<View>, WorkspaceError> get viewsOrFail =>
      throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ViewsReceivedCopyWith<ViewsReceived> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
class _$AppListenStateTearOff {
  const _$AppListenStateTearOff();

  _Initial initial() {
    return const _Initial();
  }

  _LoadViews didReceiveViews(List<View> views) {
    return _LoadViews(
      views,
    );
  }

  _LoadFail loadFail(WorkspaceError error) {
    return _LoadFail(
      error,
    );
  }
}

/// @nodoc
const $AppListenState = _$AppListenStateTearOff();

/// @nodoc
mixin _$AppListenState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(List<View> views) didReceiveViews,
    required TResult Function(WorkspaceError error) loadFail,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<View> views)? didReceiveViews,
    TResult Function(WorkspaceError error)? loadFail,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_LoadViews value) didReceiveViews,
    required TResult Function(_LoadFail value) loadFail,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_LoadViews value)? didReceiveViews,
    TResult Function(_LoadFail value)? loadFail,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppListenStateCopyWith<$Res> {
  factory $AppListenStateCopyWith(
          AppListenState value, $Res Function(AppListenState) then) =
      _$AppListenStateCopyWithImpl<$Res>;
}

/// @nodoc
class _$AppListenStateCopyWithImpl<$Res>
    implements $AppListenStateCopyWith<$Res> {
  _$AppListenStateCopyWithImpl(this._value, this._then);

  final AppListenState _value;
  // ignore: unused_field
  final $Res Function(AppListenState) _then;
}

/// @nodoc
abstract class _$InitialCopyWith<$Res> {
  factory _$InitialCopyWith(_Initial value, $Res Function(_Initial) then) =
      __$InitialCopyWithImpl<$Res>;
}

/// @nodoc
class __$InitialCopyWithImpl<$Res> extends _$AppListenStateCopyWithImpl<$Res>
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
    return 'AppListenState.initial()';
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
    required TResult Function(List<View> views) didReceiveViews,
    required TResult Function(WorkspaceError error) loadFail,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<View> views)? didReceiveViews,
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
    required TResult Function(_LoadViews value) didReceiveViews,
    required TResult Function(_LoadFail value) loadFail,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_LoadViews value)? didReceiveViews,
    TResult Function(_LoadFail value)? loadFail,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _Initial implements AppListenState {
  const factory _Initial() = _$_Initial;
}

/// @nodoc
abstract class _$LoadViewsCopyWith<$Res> {
  factory _$LoadViewsCopyWith(
          _LoadViews value, $Res Function(_LoadViews) then) =
      __$LoadViewsCopyWithImpl<$Res>;
  $Res call({List<View> views});
}

/// @nodoc
class __$LoadViewsCopyWithImpl<$Res> extends _$AppListenStateCopyWithImpl<$Res>
    implements _$LoadViewsCopyWith<$Res> {
  __$LoadViewsCopyWithImpl(_LoadViews _value, $Res Function(_LoadViews) _then)
      : super(_value, (v) => _then(v as _LoadViews));

  @override
  _LoadViews get _value => super._value as _LoadViews;

  @override
  $Res call({
    Object? views = freezed,
  }) {
    return _then(_LoadViews(
      views == freezed
          ? _value.views
          : views // ignore: cast_nullable_to_non_nullable
              as List<View>,
    ));
  }
}

/// @nodoc

class _$_LoadViews implements _LoadViews {
  const _$_LoadViews(this.views);

  @override
  final List<View> views;

  @override
  String toString() {
    return 'AppListenState.didReceiveViews(views: $views)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _LoadViews &&
            (identical(other.views, views) ||
                const DeepCollectionEquality().equals(other.views, views)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(views);

  @JsonKey(ignore: true)
  @override
  _$LoadViewsCopyWith<_LoadViews> get copyWith =>
      __$LoadViewsCopyWithImpl<_LoadViews>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(List<View> views) didReceiveViews,
    required TResult Function(WorkspaceError error) loadFail,
  }) {
    return didReceiveViews(views);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<View> views)? didReceiveViews,
    TResult Function(WorkspaceError error)? loadFail,
    required TResult orElse(),
  }) {
    if (didReceiveViews != null) {
      return didReceiveViews(views);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_LoadViews value) didReceiveViews,
    required TResult Function(_LoadFail value) loadFail,
  }) {
    return didReceiveViews(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_LoadViews value)? didReceiveViews,
    TResult Function(_LoadFail value)? loadFail,
    required TResult orElse(),
  }) {
    if (didReceiveViews != null) {
      return didReceiveViews(this);
    }
    return orElse();
  }
}

abstract class _LoadViews implements AppListenState {
  const factory _LoadViews(List<View> views) = _$_LoadViews;

  List<View> get views => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  _$LoadViewsCopyWith<_LoadViews> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$LoadFailCopyWith<$Res> {
  factory _$LoadFailCopyWith(_LoadFail value, $Res Function(_LoadFail) then) =
      __$LoadFailCopyWithImpl<$Res>;
  $Res call({WorkspaceError error});
}

/// @nodoc
class __$LoadFailCopyWithImpl<$Res> extends _$AppListenStateCopyWithImpl<$Res>
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
    return 'AppListenState.loadFail(error: $error)';
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
    required TResult Function(List<View> views) didReceiveViews,
    required TResult Function(WorkspaceError error) loadFail,
  }) {
    return loadFail(error);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<View> views)? didReceiveViews,
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
    required TResult Function(_LoadViews value) didReceiveViews,
    required TResult Function(_LoadFail value) loadFail,
  }) {
    return loadFail(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_LoadViews value)? didReceiveViews,
    TResult Function(_LoadFail value)? loadFail,
    required TResult orElse(),
  }) {
    if (loadFail != null) {
      return loadFail(this);
    }
    return orElse();
  }
}

abstract class _LoadFail implements AppListenState {
  const factory _LoadFail(WorkspaceError error) = _$_LoadFail;

  WorkspaceError get error => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  _$LoadFailCopyWith<_LoadFail> get copyWith =>
      throw _privateConstructorUsedError;
}
