// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'doc_edit_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
class _$DocEditEventTearOff {
  const _$DocEditEventTearOff();

  Initial initial() {
    return const Initial();
  }

  Changeset changeset(String data) {
    return Changeset(
      data,
    );
  }

  Save save(String data) {
    return Save(
      data,
    );
  }

  Close close() {
    return const Close();
  }
}

/// @nodoc
const $DocEditEvent = _$DocEditEventTearOff();

/// @nodoc
mixin _$DocEditEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(String data) changeset,
    required TResult Function(String data) save,
    required TResult Function() close,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String data)? changeset,
    TResult Function(String data)? save,
    TResult Function()? close,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(Changeset value) changeset,
    required TResult Function(Save value) save,
    required TResult Function(Close value) close,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(Changeset value)? changeset,
    TResult Function(Save value)? save,
    TResult Function(Close value)? close,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DocEditEventCopyWith<$Res> {
  factory $DocEditEventCopyWith(
          DocEditEvent value, $Res Function(DocEditEvent) then) =
      _$DocEditEventCopyWithImpl<$Res>;
}

/// @nodoc
class _$DocEditEventCopyWithImpl<$Res> implements $DocEditEventCopyWith<$Res> {
  _$DocEditEventCopyWithImpl(this._value, this._then);

  final DocEditEvent _value;
  // ignore: unused_field
  final $Res Function(DocEditEvent) _then;
}

/// @nodoc
abstract class $InitialCopyWith<$Res> {
  factory $InitialCopyWith(Initial value, $Res Function(Initial) then) =
      _$InitialCopyWithImpl<$Res>;
}

/// @nodoc
class _$InitialCopyWithImpl<$Res> extends _$DocEditEventCopyWithImpl<$Res>
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
    return 'DocEditEvent.initial()';
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
    required TResult Function(String data) changeset,
    required TResult Function(String data) save,
    required TResult Function() close,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String data)? changeset,
    TResult Function(String data)? save,
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
    required TResult Function(Changeset value) changeset,
    required TResult Function(Save value) save,
    required TResult Function(Close value) close,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(Changeset value)? changeset,
    TResult Function(Save value)? save,
    TResult Function(Close value)? close,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class Initial implements DocEditEvent {
  const factory Initial() = _$Initial;
}

/// @nodoc
abstract class $ChangesetCopyWith<$Res> {
  factory $ChangesetCopyWith(Changeset value, $Res Function(Changeset) then) =
      _$ChangesetCopyWithImpl<$Res>;
  $Res call({String data});
}

/// @nodoc
class _$ChangesetCopyWithImpl<$Res> extends _$DocEditEventCopyWithImpl<$Res>
    implements $ChangesetCopyWith<$Res> {
  _$ChangesetCopyWithImpl(Changeset _value, $Res Function(Changeset) _then)
      : super(_value, (v) => _then(v as Changeset));

  @override
  Changeset get _value => super._value as Changeset;

  @override
  $Res call({
    Object? data = freezed,
  }) {
    return _then(Changeset(
      data == freezed
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$Changeset implements Changeset {
  const _$Changeset(this.data);

  @override
  final String data;

  @override
  String toString() {
    return 'DocEditEvent.changeset(data: $data)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is Changeset &&
            (identical(other.data, data) ||
                const DeepCollectionEquality().equals(other.data, data)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(data);

  @JsonKey(ignore: true)
  @override
  $ChangesetCopyWith<Changeset> get copyWith =>
      _$ChangesetCopyWithImpl<Changeset>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(String data) changeset,
    required TResult Function(String data) save,
    required TResult Function() close,
  }) {
    return changeset(data);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String data)? changeset,
    TResult Function(String data)? save,
    TResult Function()? close,
    required TResult orElse(),
  }) {
    if (changeset != null) {
      return changeset(data);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(Changeset value) changeset,
    required TResult Function(Save value) save,
    required TResult Function(Close value) close,
  }) {
    return changeset(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(Changeset value)? changeset,
    TResult Function(Save value)? save,
    TResult Function(Close value)? close,
    required TResult orElse(),
  }) {
    if (changeset != null) {
      return changeset(this);
    }
    return orElse();
  }
}

abstract class Changeset implements DocEditEvent {
  const factory Changeset(String data) = _$Changeset;

  String get data => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ChangesetCopyWith<Changeset> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SaveCopyWith<$Res> {
  factory $SaveCopyWith(Save value, $Res Function(Save) then) =
      _$SaveCopyWithImpl<$Res>;
  $Res call({String data});
}

/// @nodoc
class _$SaveCopyWithImpl<$Res> extends _$DocEditEventCopyWithImpl<$Res>
    implements $SaveCopyWith<$Res> {
  _$SaveCopyWithImpl(Save _value, $Res Function(Save) _then)
      : super(_value, (v) => _then(v as Save));

  @override
  Save get _value => super._value as Save;

  @override
  $Res call({
    Object? data = freezed,
  }) {
    return _then(Save(
      data == freezed
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$Save implements Save {
  const _$Save(this.data);

  @override
  final String data;

  @override
  String toString() {
    return 'DocEditEvent.save(data: $data)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is Save &&
            (identical(other.data, data) ||
                const DeepCollectionEquality().equals(other.data, data)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(data);

  @JsonKey(ignore: true)
  @override
  $SaveCopyWith<Save> get copyWith =>
      _$SaveCopyWithImpl<Save>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(String data) changeset,
    required TResult Function(String data) save,
    required TResult Function() close,
  }) {
    return save(data);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String data)? changeset,
    TResult Function(String data)? save,
    TResult Function()? close,
    required TResult orElse(),
  }) {
    if (save != null) {
      return save(data);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(Changeset value) changeset,
    required TResult Function(Save value) save,
    required TResult Function(Close value) close,
  }) {
    return save(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(Changeset value)? changeset,
    TResult Function(Save value)? save,
    TResult Function(Close value)? close,
    required TResult orElse(),
  }) {
    if (save != null) {
      return save(this);
    }
    return orElse();
  }
}

abstract class Save implements DocEditEvent {
  const factory Save(String data) = _$Save;

  String get data => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SaveCopyWith<Save> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CloseCopyWith<$Res> {
  factory $CloseCopyWith(Close value, $Res Function(Close) then) =
      _$CloseCopyWithImpl<$Res>;
}

/// @nodoc
class _$CloseCopyWithImpl<$Res> extends _$DocEditEventCopyWithImpl<$Res>
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
    return 'DocEditEvent.close()';
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
    required TResult Function(String data) changeset,
    required TResult Function(String data) save,
    required TResult Function() close,
  }) {
    return close();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String data)? changeset,
    TResult Function(String data)? save,
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
    required TResult Function(Changeset value) changeset,
    required TResult Function(Save value) save,
    required TResult Function(Close value) close,
  }) {
    return close(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(Changeset value)? changeset,
    TResult Function(Save value)? save,
    TResult Function(Close value)? close,
    required TResult orElse(),
  }) {
    if (close != null) {
      return close(this);
    }
    return orElse();
  }
}

abstract class Close implements DocEditEvent {
  const factory Close() = _$Close;
}

/// @nodoc
class _$DocEditStateTearOff {
  const _$DocEditStateTearOff();

  _DocEditState call({required bool isSaving}) {
    return _DocEditState(
      isSaving: isSaving,
    );
  }
}

/// @nodoc
const $DocEditState = _$DocEditStateTearOff();

/// @nodoc
mixin _$DocEditState {
  bool get isSaving => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $DocEditStateCopyWith<DocEditState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DocEditStateCopyWith<$Res> {
  factory $DocEditStateCopyWith(
          DocEditState value, $Res Function(DocEditState) then) =
      _$DocEditStateCopyWithImpl<$Res>;
  $Res call({bool isSaving});
}

/// @nodoc
class _$DocEditStateCopyWithImpl<$Res> implements $DocEditStateCopyWith<$Res> {
  _$DocEditStateCopyWithImpl(this._value, this._then);

  final DocEditState _value;
  // ignore: unused_field
  final $Res Function(DocEditState) _then;

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
abstract class _$DocEditStateCopyWith<$Res>
    implements $DocEditStateCopyWith<$Res> {
  factory _$DocEditStateCopyWith(
          _DocEditState value, $Res Function(_DocEditState) then) =
      __$DocEditStateCopyWithImpl<$Res>;
  @override
  $Res call({bool isSaving});
}

/// @nodoc
class __$DocEditStateCopyWithImpl<$Res> extends _$DocEditStateCopyWithImpl<$Res>
    implements _$DocEditStateCopyWith<$Res> {
  __$DocEditStateCopyWithImpl(
      _DocEditState _value, $Res Function(_DocEditState) _then)
      : super(_value, (v) => _then(v as _DocEditState));

  @override
  _DocEditState get _value => super._value as _DocEditState;

  @override
  $Res call({
    Object? isSaving = freezed,
  }) {
    return _then(_DocEditState(
      isSaving: isSaving == freezed
          ? _value.isSaving
          : isSaving // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$_DocEditState implements _DocEditState {
  const _$_DocEditState({required this.isSaving});

  @override
  final bool isSaving;

  @override
  String toString() {
    return 'DocEditState(isSaving: $isSaving)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _DocEditState &&
            (identical(other.isSaving, isSaving) ||
                const DeepCollectionEquality()
                    .equals(other.isSaving, isSaving)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(isSaving);

  @JsonKey(ignore: true)
  @override
  _$DocEditStateCopyWith<_DocEditState> get copyWith =>
      __$DocEditStateCopyWithImpl<_DocEditState>(this, _$identity);
}

abstract class _DocEditState implements DocEditState {
  const factory _DocEditState({required bool isSaving}) = _$_DocEditState;

  @override
  bool get isSaving => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$DocEditStateCopyWith<_DocEditState> get copyWith =>
      throw _privateConstructorUsedError;
}
