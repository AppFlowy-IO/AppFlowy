// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides

part of 'view_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
class _$ViewEventTearOff {
  const _$ViewEventTearOff();

  Initial initial() {
    return const Initial();
  }
}

/// @nodoc
const $ViewEvent = _$ViewEventTearOff();

/// @nodoc
mixin _$ViewEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ViewEventCopyWith<$Res> {
  factory $ViewEventCopyWith(ViewEvent value, $Res Function(ViewEvent) then) =
      _$ViewEventCopyWithImpl<$Res>;
}

/// @nodoc
class _$ViewEventCopyWithImpl<$Res> implements $ViewEventCopyWith<$Res> {
  _$ViewEventCopyWithImpl(this._value, this._then);

  final ViewEvent _value;
  // ignore: unused_field
  final $Res Function(ViewEvent) _then;
}

/// @nodoc
abstract class $InitialCopyWith<$Res> {
  factory $InitialCopyWith(Initial value, $Res Function(Initial) then) =
      _$InitialCopyWithImpl<$Res>;
}

/// @nodoc
class _$InitialCopyWithImpl<$Res> extends _$ViewEventCopyWithImpl<$Res>
    implements $InitialCopyWith<$Res> {
  _$InitialCopyWithImpl(Initial _value, $Res Function(Initial) _then)
      : super(_value, (v) => _then(v as Initial));

  @override
  Initial get _value => super._value as Initial;
}

/// @nodoc

class _$Initial implements Initial {
  const _$Initial();

  @override
  String toString() {
    return 'ViewEvent.initial()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) || (other is Initial);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
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
    required TResult Function(Initial value) initial,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class Initial implements ViewEvent {
  const factory Initial() = _$Initial;
}

/// @nodoc
class _$ViewStateTearOff {
  const _$ViewStateTearOff();

  _ViewState call(
      {required bool isLoading,
      required Option<View> view,
      required Either<Unit, WorkspaceError> successOrFailure}) {
    return _ViewState(
      isLoading: isLoading,
      view: view,
      successOrFailure: successOrFailure,
    );
  }
}

/// @nodoc
const $ViewState = _$ViewStateTearOff();

/// @nodoc
mixin _$ViewState {
  bool get isLoading => throw _privateConstructorUsedError;
  Option<View> get view => throw _privateConstructorUsedError;
  Either<Unit, WorkspaceError> get successOrFailure =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ViewStateCopyWith<ViewState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ViewStateCopyWith<$Res> {
  factory $ViewStateCopyWith(ViewState value, $Res Function(ViewState) then) =
      _$ViewStateCopyWithImpl<$Res>;
  $Res call(
      {bool isLoading,
      Option<View> view,
      Either<Unit, WorkspaceError> successOrFailure});
}

/// @nodoc
class _$ViewStateCopyWithImpl<$Res> implements $ViewStateCopyWith<$Res> {
  _$ViewStateCopyWithImpl(this._value, this._then);

  final ViewState _value;
  // ignore: unused_field
  final $Res Function(ViewState) _then;

  @override
  $Res call({
    Object? isLoading = freezed,
    Object? view = freezed,
    Object? successOrFailure = freezed,
  }) {
    return _then(_value.copyWith(
      isLoading: isLoading == freezed
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      view: view == freezed
          ? _value.view
          : view // ignore: cast_nullable_to_non_nullable
              as Option<View>,
      successOrFailure: successOrFailure == freezed
          ? _value.successOrFailure
          : successOrFailure // ignore: cast_nullable_to_non_nullable
              as Either<Unit, WorkspaceError>,
    ));
  }
}

/// @nodoc
abstract class _$ViewStateCopyWith<$Res> implements $ViewStateCopyWith<$Res> {
  factory _$ViewStateCopyWith(
          _ViewState value, $Res Function(_ViewState) then) =
      __$ViewStateCopyWithImpl<$Res>;
  @override
  $Res call(
      {bool isLoading,
      Option<View> view,
      Either<Unit, WorkspaceError> successOrFailure});
}

/// @nodoc
class __$ViewStateCopyWithImpl<$Res> extends _$ViewStateCopyWithImpl<$Res>
    implements _$ViewStateCopyWith<$Res> {
  __$ViewStateCopyWithImpl(_ViewState _value, $Res Function(_ViewState) _then)
      : super(_value, (v) => _then(v as _ViewState));

  @override
  _ViewState get _value => super._value as _ViewState;

  @override
  $Res call({
    Object? isLoading = freezed,
    Object? view = freezed,
    Object? successOrFailure = freezed,
  }) {
    return _then(_ViewState(
      isLoading: isLoading == freezed
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      view: view == freezed
          ? _value.view
          : view // ignore: cast_nullable_to_non_nullable
              as Option<View>,
      successOrFailure: successOrFailure == freezed
          ? _value.successOrFailure
          : successOrFailure // ignore: cast_nullable_to_non_nullable
              as Either<Unit, WorkspaceError>,
    ));
  }
}

/// @nodoc

class _$_ViewState implements _ViewState {
  const _$_ViewState(
      {required this.isLoading,
      required this.view,
      required this.successOrFailure});

  @override
  final bool isLoading;
  @override
  final Option<View> view;
  @override
  final Either<Unit, WorkspaceError> successOrFailure;

  @override
  String toString() {
    return 'ViewState(isLoading: $isLoading, view: $view, successOrFailure: $successOrFailure)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _ViewState &&
            (identical(other.isLoading, isLoading) ||
                const DeepCollectionEquality()
                    .equals(other.isLoading, isLoading)) &&
            (identical(other.view, view) ||
                const DeepCollectionEquality().equals(other.view, view)) &&
            (identical(other.successOrFailure, successOrFailure) ||
                const DeepCollectionEquality()
                    .equals(other.successOrFailure, successOrFailure)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(isLoading) ^
      const DeepCollectionEquality().hash(view) ^
      const DeepCollectionEquality().hash(successOrFailure);

  @JsonKey(ignore: true)
  @override
  _$ViewStateCopyWith<_ViewState> get copyWith =>
      __$ViewStateCopyWithImpl<_ViewState>(this, _$identity);
}

abstract class _ViewState implements ViewState {
  const factory _ViewState(
      {required bool isLoading,
      required Option<View> view,
      required Either<Unit, WorkspaceError> successOrFailure}) = _$_ViewState;

  @override
  bool get isLoading => throw _privateConstructorUsedError;
  @override
  Option<View> get view => throw _privateConstructorUsedError;
  @override
  Either<Unit, WorkspaceError> get successOrFailure =>
      throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$ViewStateCopyWith<_ViewState> get copyWith =>
      throw _privateConstructorUsedError;
}
