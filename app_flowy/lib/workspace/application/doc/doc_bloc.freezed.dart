// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

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
}

/// @nodoc
const $DocEvent = _$DocEventTearOff();

/// @nodoc
mixin _$DocEvent {
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

abstract class Initial implements DocEvent {
  const factory Initial() = _$Initial;
}

/// @nodoc
class _$DocStateTearOff {
  const _$DocStateTearOff();

  _DocState call(
      {required Option<FlowyDoc> doc, required DocLoadState loadState}) {
    return _DocState(
      doc: doc,
      loadState: loadState,
    );
  }
}

/// @nodoc
const $DocState = _$DocStateTearOff();

/// @nodoc
mixin _$DocState {
  Option<FlowyDoc> get doc => throw _privateConstructorUsedError;
  DocLoadState get loadState => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $DocStateCopyWith<DocState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DocStateCopyWith<$Res> {
  factory $DocStateCopyWith(DocState value, $Res Function(DocState) then) =
      _$DocStateCopyWithImpl<$Res>;
  $Res call({Option<FlowyDoc> doc, DocLoadState loadState});

  $DocLoadStateCopyWith<$Res> get loadState;
}

/// @nodoc
class _$DocStateCopyWithImpl<$Res> implements $DocStateCopyWith<$Res> {
  _$DocStateCopyWithImpl(this._value, this._then);

  final DocState _value;
  // ignore: unused_field
  final $Res Function(DocState) _then;

  @override
  $Res call({
    Object? doc = freezed,
    Object? loadState = freezed,
  }) {
    return _then(_value.copyWith(
      doc: doc == freezed
          ? _value.doc
          : doc // ignore: cast_nullable_to_non_nullable
              as Option<FlowyDoc>,
      loadState: loadState == freezed
          ? _value.loadState
          : loadState // ignore: cast_nullable_to_non_nullable
              as DocLoadState,
    ));
  }

  @override
  $DocLoadStateCopyWith<$Res> get loadState {
    return $DocLoadStateCopyWith<$Res>(_value.loadState, (value) {
      return _then(_value.copyWith(loadState: value));
    });
  }
}

/// @nodoc
abstract class _$DocStateCopyWith<$Res> implements $DocStateCopyWith<$Res> {
  factory _$DocStateCopyWith(_DocState value, $Res Function(_DocState) then) =
      __$DocStateCopyWithImpl<$Res>;
  @override
  $Res call({Option<FlowyDoc> doc, DocLoadState loadState});

  @override
  $DocLoadStateCopyWith<$Res> get loadState;
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
    Object? doc = freezed,
    Object? loadState = freezed,
  }) {
    return _then(_DocState(
      doc: doc == freezed
          ? _value.doc
          : doc // ignore: cast_nullable_to_non_nullable
              as Option<FlowyDoc>,
      loadState: loadState == freezed
          ? _value.loadState
          : loadState // ignore: cast_nullable_to_non_nullable
              as DocLoadState,
    ));
  }
}

/// @nodoc

class _$_DocState implements _DocState {
  const _$_DocState({required this.doc, required this.loadState});

  @override
  final Option<FlowyDoc> doc;
  @override
  final DocLoadState loadState;

  @override
  String toString() {
    return 'DocState(doc: $doc, loadState: $loadState)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _DocState &&
            (identical(other.doc, doc) ||
                const DeepCollectionEquality().equals(other.doc, doc)) &&
            (identical(other.loadState, loadState) ||
                const DeepCollectionEquality()
                    .equals(other.loadState, loadState)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(doc) ^
      const DeepCollectionEquality().hash(loadState);

  @JsonKey(ignore: true)
  @override
  _$DocStateCopyWith<_DocState> get copyWith =>
      __$DocStateCopyWithImpl<_DocState>(this, _$identity);
}

abstract class _DocState implements DocState {
  const factory _DocState(
      {required Option<FlowyDoc> doc,
      required DocLoadState loadState}) = _$_DocState;

  @override
  Option<FlowyDoc> get doc => throw _privateConstructorUsedError;
  @override
  DocLoadState get loadState => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$DocStateCopyWith<_DocState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
class _$DocLoadStateTearOff {
  const _$DocLoadStateTearOff();

  _Loading loading() {
    return const _Loading();
  }

  _Finish finish(Either<FlowyDoc, WorkspaceError> successOrFail) {
    return _Finish(
      successOrFail,
    );
  }
}

/// @nodoc
const $DocLoadState = _$DocLoadStateTearOff();

/// @nodoc
mixin _$DocLoadState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(Either<FlowyDoc, WorkspaceError> successOrFail)
        finish,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(Either<FlowyDoc, WorkspaceError> successOrFail)? finish,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Loading value) loading,
    required TResult Function(_Finish value) finish,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Loading value)? loading,
    TResult Function(_Finish value)? finish,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DocLoadStateCopyWith<$Res> {
  factory $DocLoadStateCopyWith(
          DocLoadState value, $Res Function(DocLoadState) then) =
      _$DocLoadStateCopyWithImpl<$Res>;
}

/// @nodoc
class _$DocLoadStateCopyWithImpl<$Res> implements $DocLoadStateCopyWith<$Res> {
  _$DocLoadStateCopyWithImpl(this._value, this._then);

  final DocLoadState _value;
  // ignore: unused_field
  final $Res Function(DocLoadState) _then;
}

/// @nodoc
abstract class _$LoadingCopyWith<$Res> {
  factory _$LoadingCopyWith(_Loading value, $Res Function(_Loading) then) =
      __$LoadingCopyWithImpl<$Res>;
}

/// @nodoc
class __$LoadingCopyWithImpl<$Res> extends _$DocLoadStateCopyWithImpl<$Res>
    implements _$LoadingCopyWith<$Res> {
  __$LoadingCopyWithImpl(_Loading _value, $Res Function(_Loading) _then)
      : super(_value, (v) => _then(v as _Loading));

  @override
  _Loading get _value => super._value as _Loading;
}

/// @nodoc

class _$_Loading implements _Loading {
  const _$_Loading();

  @override
  String toString() {
    return 'DocLoadState.loading()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) || (other is _Loading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(Either<FlowyDoc, WorkspaceError> successOrFail)
        finish,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(Either<FlowyDoc, WorkspaceError> successOrFail)? finish,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Loading value) loading,
    required TResult Function(_Finish value) finish,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Loading value)? loading,
    TResult Function(_Finish value)? finish,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class _Loading implements DocLoadState {
  const factory _Loading() = _$_Loading;
}

/// @nodoc
abstract class _$FinishCopyWith<$Res> {
  factory _$FinishCopyWith(_Finish value, $Res Function(_Finish) then) =
      __$FinishCopyWithImpl<$Res>;
  $Res call({Either<FlowyDoc, WorkspaceError> successOrFail});
}

/// @nodoc
class __$FinishCopyWithImpl<$Res> extends _$DocLoadStateCopyWithImpl<$Res>
    implements _$FinishCopyWith<$Res> {
  __$FinishCopyWithImpl(_Finish _value, $Res Function(_Finish) _then)
      : super(_value, (v) => _then(v as _Finish));

  @override
  _Finish get _value => super._value as _Finish;

  @override
  $Res call({
    Object? successOrFail = freezed,
  }) {
    return _then(_Finish(
      successOrFail == freezed
          ? _value.successOrFail
          : successOrFail // ignore: cast_nullable_to_non_nullable
              as Either<FlowyDoc, WorkspaceError>,
    ));
  }
}

/// @nodoc

class _$_Finish implements _Finish {
  const _$_Finish(this.successOrFail);

  @override
  final Either<FlowyDoc, WorkspaceError> successOrFail;

  @override
  String toString() {
    return 'DocLoadState.finish(successOrFail: $successOrFail)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _Finish &&
            (identical(other.successOrFail, successOrFail) ||
                const DeepCollectionEquality()
                    .equals(other.successOrFail, successOrFail)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(successOrFail);

  @JsonKey(ignore: true)
  @override
  _$FinishCopyWith<_Finish> get copyWith =>
      __$FinishCopyWithImpl<_Finish>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(Either<FlowyDoc, WorkspaceError> successOrFail)
        finish,
  }) {
    return finish(successOrFail);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(Either<FlowyDoc, WorkspaceError> successOrFail)? finish,
    required TResult orElse(),
  }) {
    if (finish != null) {
      return finish(successOrFail);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Loading value) loading,
    required TResult Function(_Finish value) finish,
  }) {
    return finish(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Loading value)? loading,
    TResult Function(_Finish value)? finish,
    required TResult orElse(),
  }) {
    if (finish != null) {
      return finish(this);
    }
    return orElse();
  }
}

abstract class _Finish implements DocLoadState {
  const factory _Finish(Either<FlowyDoc, WorkspaceError> successOrFail) =
      _$_Finish;

  Either<FlowyDoc, WorkspaceError> get successOrFail =>
      throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  _$FinishCopyWith<_Finish> get copyWith => throw _privateConstructorUsedError;
}
