// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'trash_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
class _$TrashEventTearOff {
  const _$TrashEventTearOff();

  Initial initial() {
    return const Initial();
  }
}

/// @nodoc
const $TrashEvent = _$TrashEventTearOff();

/// @nodoc
mixin _$TrashEvent {
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
abstract class $TrashEventCopyWith<$Res> {
  factory $TrashEventCopyWith(
          TrashEvent value, $Res Function(TrashEvent) then) =
      _$TrashEventCopyWithImpl<$Res>;
}

/// @nodoc
class _$TrashEventCopyWithImpl<$Res> implements $TrashEventCopyWith<$Res> {
  _$TrashEventCopyWithImpl(this._value, this._then);

  final TrashEvent _value;
  // ignore: unused_field
  final $Res Function(TrashEvent) _then;
}

/// @nodoc
abstract class $InitialCopyWith<$Res> {
  factory $InitialCopyWith(Initial value, $Res Function(Initial) then) =
      _$InitialCopyWithImpl<$Res>;
}

/// @nodoc
class _$InitialCopyWithImpl<$Res> extends _$TrashEventCopyWithImpl<$Res>
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
    return 'TrashEvent.initial()';
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

abstract class Initial implements TrashEvent {
  const factory Initial() = _$Initial;
}

/// @nodoc
class _$TrashStateTearOff {
  const _$TrashStateTearOff();

  _TrashState call(
      {required List<TrashObject> objects,
      required Either<Unit, WorkspaceError> successOrFailure}) {
    return _TrashState(
      objects: objects,
      successOrFailure: successOrFailure,
    );
  }
}

/// @nodoc
const $TrashState = _$TrashStateTearOff();

/// @nodoc
mixin _$TrashState {
  List<TrashObject> get objects => throw _privateConstructorUsedError;
  Either<Unit, WorkspaceError> get successOrFailure =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $TrashStateCopyWith<TrashState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrashStateCopyWith<$Res> {
  factory $TrashStateCopyWith(
          TrashState value, $Res Function(TrashState) then) =
      _$TrashStateCopyWithImpl<$Res>;
  $Res call(
      {List<TrashObject> objects,
      Either<Unit, WorkspaceError> successOrFailure});
}

/// @nodoc
class _$TrashStateCopyWithImpl<$Res> implements $TrashStateCopyWith<$Res> {
  _$TrashStateCopyWithImpl(this._value, this._then);

  final TrashState _value;
  // ignore: unused_field
  final $Res Function(TrashState) _then;

  @override
  $Res call({
    Object? objects = freezed,
    Object? successOrFailure = freezed,
  }) {
    return _then(_value.copyWith(
      objects: objects == freezed
          ? _value.objects
          : objects // ignore: cast_nullable_to_non_nullable
              as List<TrashObject>,
      successOrFailure: successOrFailure == freezed
          ? _value.successOrFailure
          : successOrFailure // ignore: cast_nullable_to_non_nullable
              as Either<Unit, WorkspaceError>,
    ));
  }
}

/// @nodoc
abstract class _$TrashStateCopyWith<$Res> implements $TrashStateCopyWith<$Res> {
  factory _$TrashStateCopyWith(
          _TrashState value, $Res Function(_TrashState) then) =
      __$TrashStateCopyWithImpl<$Res>;
  @override
  $Res call(
      {List<TrashObject> objects,
      Either<Unit, WorkspaceError> successOrFailure});
}

/// @nodoc
class __$TrashStateCopyWithImpl<$Res> extends _$TrashStateCopyWithImpl<$Res>
    implements _$TrashStateCopyWith<$Res> {
  __$TrashStateCopyWithImpl(
      _TrashState _value, $Res Function(_TrashState) _then)
      : super(_value, (v) => _then(v as _TrashState));

  @override
  _TrashState get _value => super._value as _TrashState;

  @override
  $Res call({
    Object? objects = freezed,
    Object? successOrFailure = freezed,
  }) {
    return _then(_TrashState(
      objects: objects == freezed
          ? _value.objects
          : objects // ignore: cast_nullable_to_non_nullable
              as List<TrashObject>,
      successOrFailure: successOrFailure == freezed
          ? _value.successOrFailure
          : successOrFailure // ignore: cast_nullable_to_non_nullable
              as Either<Unit, WorkspaceError>,
    ));
  }
}

/// @nodoc

class _$_TrashState implements _TrashState {
  const _$_TrashState({required this.objects, required this.successOrFailure});

  @override
  final List<TrashObject> objects;
  @override
  final Either<Unit, WorkspaceError> successOrFailure;

  @override
  String toString() {
    return 'TrashState(objects: $objects, successOrFailure: $successOrFailure)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _TrashState &&
            (identical(other.objects, objects) ||
                const DeepCollectionEquality()
                    .equals(other.objects, objects)) &&
            (identical(other.successOrFailure, successOrFailure) ||
                const DeepCollectionEquality()
                    .equals(other.successOrFailure, successOrFailure)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(objects) ^
      const DeepCollectionEquality().hash(successOrFailure);

  @JsonKey(ignore: true)
  @override
  _$TrashStateCopyWith<_TrashState> get copyWith =>
      __$TrashStateCopyWithImpl<_TrashState>(this, _$identity);
}

abstract class _TrashState implements TrashState {
  const factory _TrashState(
      {required List<TrashObject> objects,
      required Either<Unit, WorkspaceError> successOrFailure}) = _$_TrashState;

  @override
  List<TrashObject> get objects => throw _privateConstructorUsedError;
  @override
  Either<Unit, WorkspaceError> get successOrFailure =>
      throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$TrashStateCopyWith<_TrashState> get copyWith =>
      throw _privateConstructorUsedError;
}
