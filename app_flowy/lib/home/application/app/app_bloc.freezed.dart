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

  _Initial initial() {
    return const _Initial();
  }

  ViewsReceived viewsReceived(Either<List<View>, WorkspaceError> appsOrFail) {
    return ViewsReceived(
      appsOrFail,
    );
  }
}

/// @nodoc
const $AppEvent = _$AppEventTearOff();

/// @nodoc
mixin _$AppEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(Either<List<View>, WorkspaceError> appsOrFail)
        viewsReceived,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(Either<List<View>, WorkspaceError> appsOrFail)?
        viewsReceived,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(ViewsReceived value) viewsReceived,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(ViewsReceived value)? viewsReceived,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppEventCopyWith<$Res> {
  factory $AppEventCopyWith(AppEvent value, $Res Function(AppEvent) then) =
      _$AppEventCopyWithImpl<$Res>;
}

/// @nodoc
class _$AppEventCopyWithImpl<$Res> implements $AppEventCopyWith<$Res> {
  _$AppEventCopyWithImpl(this._value, this._then);

  final AppEvent _value;
  // ignore: unused_field
  final $Res Function(AppEvent) _then;
}

/// @nodoc
abstract class _$InitialCopyWith<$Res> {
  factory _$InitialCopyWith(_Initial value, $Res Function(_Initial) then) =
      __$InitialCopyWithImpl<$Res>;
}

/// @nodoc
class __$InitialCopyWithImpl<$Res> extends _$AppEventCopyWithImpl<$Res>
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
    return 'AppEvent.initial()';
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
    required TResult Function(Either<List<View>, WorkspaceError> appsOrFail)
        viewsReceived,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(Either<List<View>, WorkspaceError> appsOrFail)?
        viewsReceived,
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
    required TResult Function(ViewsReceived value) viewsReceived,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(ViewsReceived value)? viewsReceived,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _Initial implements AppEvent {
  const factory _Initial() = _$_Initial;
}

/// @nodoc
abstract class $ViewsReceivedCopyWith<$Res> {
  factory $ViewsReceivedCopyWith(
          ViewsReceived value, $Res Function(ViewsReceived) then) =
      _$ViewsReceivedCopyWithImpl<$Res>;
  $Res call({Either<List<View>, WorkspaceError> appsOrFail});
}

/// @nodoc
class _$ViewsReceivedCopyWithImpl<$Res> extends _$AppEventCopyWithImpl<$Res>
    implements $ViewsReceivedCopyWith<$Res> {
  _$ViewsReceivedCopyWithImpl(
      ViewsReceived _value, $Res Function(ViewsReceived) _then)
      : super(_value, (v) => _then(v as ViewsReceived));

  @override
  ViewsReceived get _value => super._value as ViewsReceived;

  @override
  $Res call({
    Object? appsOrFail = freezed,
  }) {
    return _then(ViewsReceived(
      appsOrFail == freezed
          ? _value.appsOrFail
          : appsOrFail // ignore: cast_nullable_to_non_nullable
              as Either<List<View>, WorkspaceError>,
    ));
  }
}

/// @nodoc

class _$ViewsReceived implements ViewsReceived {
  const _$ViewsReceived(this.appsOrFail);

  @override
  final Either<List<View>, WorkspaceError> appsOrFail;

  @override
  String toString() {
    return 'AppEvent.viewsReceived(appsOrFail: $appsOrFail)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is ViewsReceived &&
            (identical(other.appsOrFail, appsOrFail) ||
                const DeepCollectionEquality()
                    .equals(other.appsOrFail, appsOrFail)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(appsOrFail);

  @JsonKey(ignore: true)
  @override
  $ViewsReceivedCopyWith<ViewsReceived> get copyWith =>
      _$ViewsReceivedCopyWithImpl<ViewsReceived>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(Either<List<View>, WorkspaceError> appsOrFail)
        viewsReceived,
  }) {
    return viewsReceived(appsOrFail);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(Either<List<View>, WorkspaceError> appsOrFail)?
        viewsReceived,
    required TResult orElse(),
  }) {
    if (viewsReceived != null) {
      return viewsReceived(appsOrFail);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(ViewsReceived value) viewsReceived,
  }) {
    return viewsReceived(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(ViewsReceived value)? viewsReceived,
    required TResult orElse(),
  }) {
    if (viewsReceived != null) {
      return viewsReceived(this);
    }
    return orElse();
  }
}

abstract class ViewsReceived implements AppEvent {
  const factory ViewsReceived(Either<List<View>, WorkspaceError> appsOrFail) =
      _$ViewsReceived;

  Either<List<View>, WorkspaceError> get appsOrFail =>
      throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ViewsReceivedCopyWith<ViewsReceived> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
class _$AppStateTearOff {
  const _$AppStateTearOff();

  _AppState call(
      {required bool isLoading,
      required Option<List<View>> views,
      required Either<Unit, WorkspaceError> successOrFailure}) {
    return _AppState(
      isLoading: isLoading,
      views: views,
      successOrFailure: successOrFailure,
    );
  }
}

/// @nodoc
const $AppState = _$AppStateTearOff();

/// @nodoc
mixin _$AppState {
  bool get isLoading => throw _privateConstructorUsedError;
  Option<List<View>> get views => throw _privateConstructorUsedError;
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
      {bool isLoading,
      Option<List<View>> views,
      Either<Unit, WorkspaceError> successOrFailure});
}

/// @nodoc
class _$AppStateCopyWithImpl<$Res> implements $AppStateCopyWith<$Res> {
  _$AppStateCopyWithImpl(this._value, this._then);

  final AppState _value;
  // ignore: unused_field
  final $Res Function(AppState) _then;

  @override
  $Res call({
    Object? isLoading = freezed,
    Object? views = freezed,
    Object? successOrFailure = freezed,
  }) {
    return _then(_value.copyWith(
      isLoading: isLoading == freezed
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      views: views == freezed
          ? _value.views
          : views // ignore: cast_nullable_to_non_nullable
              as Option<List<View>>,
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
      {bool isLoading,
      Option<List<View>> views,
      Either<Unit, WorkspaceError> successOrFailure});
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
    Object? isLoading = freezed,
    Object? views = freezed,
    Object? successOrFailure = freezed,
  }) {
    return _then(_AppState(
      isLoading: isLoading == freezed
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      views: views == freezed
          ? _value.views
          : views // ignore: cast_nullable_to_non_nullable
              as Option<List<View>>,
      successOrFailure: successOrFailure == freezed
          ? _value.successOrFailure
          : successOrFailure // ignore: cast_nullable_to_non_nullable
              as Either<Unit, WorkspaceError>,
    ));
  }
}

/// @nodoc

class _$_AppState implements _AppState {
  const _$_AppState(
      {required this.isLoading,
      required this.views,
      required this.successOrFailure});

  @override
  final bool isLoading;
  @override
  final Option<List<View>> views;
  @override
  final Either<Unit, WorkspaceError> successOrFailure;

  @override
  String toString() {
    return 'AppState(isLoading: $isLoading, views: $views, successOrFailure: $successOrFailure)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _AppState &&
            (identical(other.isLoading, isLoading) ||
                const DeepCollectionEquality()
                    .equals(other.isLoading, isLoading)) &&
            (identical(other.views, views) ||
                const DeepCollectionEquality().equals(other.views, views)) &&
            (identical(other.successOrFailure, successOrFailure) ||
                const DeepCollectionEquality()
                    .equals(other.successOrFailure, successOrFailure)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(isLoading) ^
      const DeepCollectionEquality().hash(views) ^
      const DeepCollectionEquality().hash(successOrFailure);

  @JsonKey(ignore: true)
  @override
  _$AppStateCopyWith<_AppState> get copyWith =>
      __$AppStateCopyWithImpl<_AppState>(this, _$identity);
}

abstract class _AppState implements AppState {
  const factory _AppState(
      {required bool isLoading,
      required Option<List<View>> views,
      required Either<Unit, WorkspaceError> successOrFailure}) = _$_AppState;

  @override
  bool get isLoading => throw _privateConstructorUsedError;
  @override
  Option<List<View>> get views => throw _privateConstructorUsedError;
  @override
  Either<Unit, WorkspaceError> get successOrFailure =>
      throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$AppStateCopyWith<_AppState> get copyWith =>
      throw _privateConstructorUsedError;
}
