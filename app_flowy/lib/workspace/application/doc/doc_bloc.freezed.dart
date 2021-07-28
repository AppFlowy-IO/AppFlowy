// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides

part of 'doc_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
class _$DocEventTearOff {
  const _$DocEventTearOff();

  Initial initial() {
    return const Initial();
  }

  Close close() {
    return const Close();
  }
}

/// @nodoc
const $DocEvent = _$DocEventTearOff();

/// @nodoc
mixin _$DocEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() close,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? close,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(Close value) close,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(Close value)? close,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DocEventCopyWith<$Res> {
  factory $DocEventCopyWith(DocEvent value, $Res Function(DocEvent) then) =
      _$DocEventCopyWithImpl<$Res>;
}

/// @nodoc
class _$DocEventCopyWithImpl<$Res> implements $DocEventCopyWith<$Res> {
  _$DocEventCopyWithImpl(this._value, this._then);

  final DocEvent _value;
  // ignore: unused_field
  final $Res Function(DocEvent) _then;
}

/// @nodoc
abstract class $InitialCopyWith<$Res> {
  factory $InitialCopyWith(Initial value, $Res Function(Initial) then) =
      _$InitialCopyWithImpl<$Res>;
}

/// @nodoc
class _$InitialCopyWithImpl<$Res> extends _$DocEventCopyWithImpl<$Res>
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
    return 'DocEvent.initial()';
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
    required TResult Function() close,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? close,
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
    required TResult Function(Close value) close,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(Close value)? close,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class Initial implements DocEvent {
  const factory Initial() = _$Initial;
}

/// @nodoc
abstract class $CloseCopyWith<$Res> {
  factory $CloseCopyWith(Close value, $Res Function(Close) then) =
      _$CloseCopyWithImpl<$Res>;
}

/// @nodoc
class _$CloseCopyWithImpl<$Res> extends _$DocEventCopyWithImpl<$Res>
    implements $CloseCopyWith<$Res> {
  _$CloseCopyWithImpl(Close _value, $Res Function(Close) _then)
      : super(_value, (v) => _then(v as Close));

  @override
  Close get _value => super._value as Close;
}

/// @nodoc

class _$Close implements Close {
  const _$Close();

  @override
  String toString() {
    return 'DocEvent.close()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) || (other is Close);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() close,
  }) {
    return close();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? close,
    required TResult orElse(),
  }) {
    if (close != null) {
      return close();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(Close value) close,
  }) {
    return close(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(Close value)? close,
    required TResult orElse(),
  }) {
    if (close != null) {
      return close(this);
    }
    return orElse();
  }
}

abstract class Close implements DocEvent {
  const factory Close() = _$Close;
}

/// @nodoc
class _$DocStateTearOff {
  const _$DocStateTearOff();

  _DocState call({required bool isSaving}) {
    return _DocState(
      isSaving: isSaving,
    );
  }
}

/// @nodoc
const $DocState = _$DocStateTearOff();

/// @nodoc
mixin _$DocState {
  bool get isSaving => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $DocStateCopyWith<DocState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DocStateCopyWith<$Res> {
  factory $DocStateCopyWith(DocState value, $Res Function(DocState) then) =
      _$DocStateCopyWithImpl<$Res>;
  $Res call({bool isSaving});
}

/// @nodoc
class _$DocStateCopyWithImpl<$Res> implements $DocStateCopyWith<$Res> {
  _$DocStateCopyWithImpl(this._value, this._then);

  final DocState _value;
  // ignore: unused_field
  final $Res Function(DocState) _then;

  @override
  $Res call({
    Object? isSaving = freezed,
  }) {
    return _then(_value.copyWith(
      isSaving: isSaving == freezed
          ? _value.isSaving
          : isSaving // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
abstract class _$DocStateCopyWith<$Res> implements $DocStateCopyWith<$Res> {
  factory _$DocStateCopyWith(_DocState value, $Res Function(_DocState) then) =
      __$DocStateCopyWithImpl<$Res>;
  @override
  $Res call({bool isSaving});
}

/// @nodoc
class __$DocStateCopyWithImpl<$Res> extends _$DocStateCopyWithImpl<$Res>
    implements _$DocStateCopyWith<$Res> {
  __$DocStateCopyWithImpl(_DocState _value, $Res Function(_DocState) _then)
      : super(_value, (v) => _then(v as _DocState));

  @override
  _DocState get _value => super._value as _DocState;

  @override
  $Res call({
    Object? isSaving = freezed,
  }) {
    return _then(_DocState(
      isSaving: isSaving == freezed
          ? _value.isSaving
          : isSaving // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$_DocState implements _DocState {
  const _$_DocState({required this.isSaving});

  @override
  final bool isSaving;

  @override
  String toString() {
    return 'DocState(isSaving: $isSaving)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _DocState &&
            (identical(other.isSaving, isSaving) ||
                const DeepCollectionEquality()
                    .equals(other.isSaving, isSaving)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(isSaving);

  @JsonKey(ignore: true)
  @override
  _$DocStateCopyWith<_DocState> get copyWith =>
      __$DocStateCopyWithImpl<_DocState>(this, _$identity);
}

abstract class _DocState implements DocState {
  const factory _DocState({required bool isSaving}) = _$_DocState;

  @override
  bool get isSaving => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$DocStateCopyWith<_DocState> get copyWith =>
      throw _privateConstructorUsedError;
}
