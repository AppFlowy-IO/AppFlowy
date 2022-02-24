// coverage:ignore-file
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

  ReceiveTrash didReceiveTrash(List<Trash> trash) {
    return ReceiveTrash(
      trash,
    );
  }

  Putback putback(String trashId) {
    return Putback(
      trashId,
    );
  }

  Delete delete(Trash trash) {
    return Delete(
      trash,
    );
  }

  RestoreAll restoreAll() {
    return const RestoreAll();
  }

  DeleteAll deleteAll() {
    return const DeleteAll();
  }
}

/// @nodoc
const $TrashEvent = _$TrashEventTearOff();

/// @nodoc
mixin _$TrashEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(List<Trash> trash) didReceiveTrash,
    required TResult Function(String trashId) putback,
    required TResult Function(Trash trash) delete,
    required TResult Function() restoreAll,
    required TResult Function() deleteAll,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<Trash> trash)? didReceiveTrash,
    TResult Function(String trashId)? putback,
    TResult Function(Trash trash)? delete,
    TResult Function()? restoreAll,
    TResult Function()? deleteAll,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<Trash> trash)? didReceiveTrash,
    TResult Function(String trashId)? putback,
    TResult Function(Trash trash)? delete,
    TResult Function()? restoreAll,
    TResult Function()? deleteAll,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(ReceiveTrash value) didReceiveTrash,
    required TResult Function(Putback value) putback,
    required TResult Function(Delete value) delete,
    required TResult Function(RestoreAll value) restoreAll,
    required TResult Function(DeleteAll value) deleteAll,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(ReceiveTrash value)? didReceiveTrash,
    TResult Function(Putback value)? putback,
    TResult Function(Delete value)? delete,
    TResult Function(RestoreAll value)? restoreAll,
    TResult Function(DeleteAll value)? deleteAll,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(ReceiveTrash value)? didReceiveTrash,
    TResult Function(Putback value)? putback,
    TResult Function(Delete value)? delete,
    TResult Function(RestoreAll value)? restoreAll,
    TResult Function(DeleteAll value)? deleteAll,
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
    required TResult Function(List<Trash> trash) didReceiveTrash,
    required TResult Function(String trashId) putback,
    required TResult Function(Trash trash) delete,
    required TResult Function() restoreAll,
    required TResult Function() deleteAll,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<Trash> trash)? didReceiveTrash,
    TResult Function(String trashId)? putback,
    TResult Function(Trash trash)? delete,
    TResult Function()? restoreAll,
    TResult Function()? deleteAll,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<Trash> trash)? didReceiveTrash,
    TResult Function(String trashId)? putback,
    TResult Function(Trash trash)? delete,
    TResult Function()? restoreAll,
    TResult Function()? deleteAll,
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
    required TResult Function(ReceiveTrash value) didReceiveTrash,
    required TResult Function(Putback value) putback,
    required TResult Function(Delete value) delete,
    required TResult Function(RestoreAll value) restoreAll,
    required TResult Function(DeleteAll value) deleteAll,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(ReceiveTrash value)? didReceiveTrash,
    TResult Function(Putback value)? putback,
    TResult Function(Delete value)? delete,
    TResult Function(RestoreAll value)? restoreAll,
    TResult Function(DeleteAll value)? deleteAll,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(ReceiveTrash value)? didReceiveTrash,
    TResult Function(Putback value)? putback,
    TResult Function(Delete value)? delete,
    TResult Function(RestoreAll value)? restoreAll,
    TResult Function(DeleteAll value)? deleteAll,
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
abstract class $ReceiveTrashCopyWith<$Res> {
  factory $ReceiveTrashCopyWith(
          ReceiveTrash value, $Res Function(ReceiveTrash) then) =
      _$ReceiveTrashCopyWithImpl<$Res>;
  $Res call({List<Trash> trash});
}

/// @nodoc
class _$ReceiveTrashCopyWithImpl<$Res> extends _$TrashEventCopyWithImpl<$Res>
    implements $ReceiveTrashCopyWith<$Res> {
  _$ReceiveTrashCopyWithImpl(
      ReceiveTrash _value, $Res Function(ReceiveTrash) _then)
      : super(_value, (v) => _then(v as ReceiveTrash));

  @override
  ReceiveTrash get _value => super._value as ReceiveTrash;

  @override
  $Res call({
    Object? trash = freezed,
  }) {
    return _then(ReceiveTrash(
      trash == freezed
          ? _value.trash
          : trash // ignore: cast_nullable_to_non_nullable
              as List<Trash>,
    ));
  }
}

/// @nodoc

class _$ReceiveTrash implements ReceiveTrash {
  const _$ReceiveTrash(this.trash);

  @override
  final List<Trash> trash;

  @override
  String toString() {
    return 'TrashEvent.didReceiveTrash(trash: $trash)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is ReceiveTrash &&
            (identical(other.trash, trash) ||
                const DeepCollectionEquality().equals(other.trash, trash)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(trash);

  @JsonKey(ignore: true)
  @override
  $ReceiveTrashCopyWith<ReceiveTrash> get copyWith =>
      _$ReceiveTrashCopyWithImpl<ReceiveTrash>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(List<Trash> trash) didReceiveTrash,
    required TResult Function(String trashId) putback,
    required TResult Function(Trash trash) delete,
    required TResult Function() restoreAll,
    required TResult Function() deleteAll,
  }) {
    return didReceiveTrash(trash);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<Trash> trash)? didReceiveTrash,
    TResult Function(String trashId)? putback,
    TResult Function(Trash trash)? delete,
    TResult Function()? restoreAll,
    TResult Function()? deleteAll,
  }) {
    return didReceiveTrash?.call(trash);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<Trash> trash)? didReceiveTrash,
    TResult Function(String trashId)? putback,
    TResult Function(Trash trash)? delete,
    TResult Function()? restoreAll,
    TResult Function()? deleteAll,
    required TResult orElse(),
  }) {
    if (didReceiveTrash != null) {
      return didReceiveTrash(trash);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(ReceiveTrash value) didReceiveTrash,
    required TResult Function(Putback value) putback,
    required TResult Function(Delete value) delete,
    required TResult Function(RestoreAll value) restoreAll,
    required TResult Function(DeleteAll value) deleteAll,
  }) {
    return didReceiveTrash(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(ReceiveTrash value)? didReceiveTrash,
    TResult Function(Putback value)? putback,
    TResult Function(Delete value)? delete,
    TResult Function(RestoreAll value)? restoreAll,
    TResult Function(DeleteAll value)? deleteAll,
  }) {
    return didReceiveTrash?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(ReceiveTrash value)? didReceiveTrash,
    TResult Function(Putback value)? putback,
    TResult Function(Delete value)? delete,
    TResult Function(RestoreAll value)? restoreAll,
    TResult Function(DeleteAll value)? deleteAll,
    required TResult orElse(),
  }) {
    if (didReceiveTrash != null) {
      return didReceiveTrash(this);
    }
    return orElse();
  }
}

abstract class ReceiveTrash implements TrashEvent {
  const factory ReceiveTrash(List<Trash> trash) = _$ReceiveTrash;

  List<Trash> get trash => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ReceiveTrashCopyWith<ReceiveTrash> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PutbackCopyWith<$Res> {
  factory $PutbackCopyWith(Putback value, $Res Function(Putback) then) =
      _$PutbackCopyWithImpl<$Res>;
  $Res call({String trashId});
}

/// @nodoc
class _$PutbackCopyWithImpl<$Res> extends _$TrashEventCopyWithImpl<$Res>
    implements $PutbackCopyWith<$Res> {
  _$PutbackCopyWithImpl(Putback _value, $Res Function(Putback) _then)
      : super(_value, (v) => _then(v as Putback));

  @override
  Putback get _value => super._value as Putback;

  @override
  $Res call({
    Object? trashId = freezed,
  }) {
    return _then(Putback(
      trashId == freezed
          ? _value.trashId
          : trashId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$Putback implements Putback {
  const _$Putback(this.trashId);

  @override
  final String trashId;

  @override
  String toString() {
    return 'TrashEvent.putback(trashId: $trashId)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is Putback &&
            (identical(other.trashId, trashId) ||
                const DeepCollectionEquality().equals(other.trashId, trashId)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(trashId);

  @JsonKey(ignore: true)
  @override
  $PutbackCopyWith<Putback> get copyWith =>
      _$PutbackCopyWithImpl<Putback>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(List<Trash> trash) didReceiveTrash,
    required TResult Function(String trashId) putback,
    required TResult Function(Trash trash) delete,
    required TResult Function() restoreAll,
    required TResult Function() deleteAll,
  }) {
    return putback(trashId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<Trash> trash)? didReceiveTrash,
    TResult Function(String trashId)? putback,
    TResult Function(Trash trash)? delete,
    TResult Function()? restoreAll,
    TResult Function()? deleteAll,
  }) {
    return putback?.call(trashId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<Trash> trash)? didReceiveTrash,
    TResult Function(String trashId)? putback,
    TResult Function(Trash trash)? delete,
    TResult Function()? restoreAll,
    TResult Function()? deleteAll,
    required TResult orElse(),
  }) {
    if (putback != null) {
      return putback(trashId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(ReceiveTrash value) didReceiveTrash,
    required TResult Function(Putback value) putback,
    required TResult Function(Delete value) delete,
    required TResult Function(RestoreAll value) restoreAll,
    required TResult Function(DeleteAll value) deleteAll,
  }) {
    return putback(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(ReceiveTrash value)? didReceiveTrash,
    TResult Function(Putback value)? putback,
    TResult Function(Delete value)? delete,
    TResult Function(RestoreAll value)? restoreAll,
    TResult Function(DeleteAll value)? deleteAll,
  }) {
    return putback?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(ReceiveTrash value)? didReceiveTrash,
    TResult Function(Putback value)? putback,
    TResult Function(Delete value)? delete,
    TResult Function(RestoreAll value)? restoreAll,
    TResult Function(DeleteAll value)? deleteAll,
    required TResult orElse(),
  }) {
    if (putback != null) {
      return putback(this);
    }
    return orElse();
  }
}

abstract class Putback implements TrashEvent {
  const factory Putback(String trashId) = _$Putback;

  String get trashId => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PutbackCopyWith<Putback> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeleteCopyWith<$Res> {
  factory $DeleteCopyWith(Delete value, $Res Function(Delete) then) =
      _$DeleteCopyWithImpl<$Res>;
  $Res call({Trash trash});
}

/// @nodoc
class _$DeleteCopyWithImpl<$Res> extends _$TrashEventCopyWithImpl<$Res>
    implements $DeleteCopyWith<$Res> {
  _$DeleteCopyWithImpl(Delete _value, $Res Function(Delete) _then)
      : super(_value, (v) => _then(v as Delete));

  @override
  Delete get _value => super._value as Delete;

  @override
  $Res call({
    Object? trash = freezed,
  }) {
    return _then(Delete(
      trash == freezed
          ? _value.trash
          : trash // ignore: cast_nullable_to_non_nullable
              as Trash,
    ));
  }
}

/// @nodoc

class _$Delete implements Delete {
  const _$Delete(this.trash);

  @override
  final Trash trash;

  @override
  String toString() {
    return 'TrashEvent.delete(trash: $trash)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is Delete &&
            (identical(other.trash, trash) ||
                const DeepCollectionEquality().equals(other.trash, trash)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(trash);

  @JsonKey(ignore: true)
  @override
  $DeleteCopyWith<Delete> get copyWith =>
      _$DeleteCopyWithImpl<Delete>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(List<Trash> trash) didReceiveTrash,
    required TResult Function(String trashId) putback,
    required TResult Function(Trash trash) delete,
    required TResult Function() restoreAll,
    required TResult Function() deleteAll,
  }) {
    return delete(trash);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<Trash> trash)? didReceiveTrash,
    TResult Function(String trashId)? putback,
    TResult Function(Trash trash)? delete,
    TResult Function()? restoreAll,
    TResult Function()? deleteAll,
  }) {
    return delete?.call(trash);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<Trash> trash)? didReceiveTrash,
    TResult Function(String trashId)? putback,
    TResult Function(Trash trash)? delete,
    TResult Function()? restoreAll,
    TResult Function()? deleteAll,
    required TResult orElse(),
  }) {
    if (delete != null) {
      return delete(trash);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(ReceiveTrash value) didReceiveTrash,
    required TResult Function(Putback value) putback,
    required TResult Function(Delete value) delete,
    required TResult Function(RestoreAll value) restoreAll,
    required TResult Function(DeleteAll value) deleteAll,
  }) {
    return delete(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(ReceiveTrash value)? didReceiveTrash,
    TResult Function(Putback value)? putback,
    TResult Function(Delete value)? delete,
    TResult Function(RestoreAll value)? restoreAll,
    TResult Function(DeleteAll value)? deleteAll,
  }) {
    return delete?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(ReceiveTrash value)? didReceiveTrash,
    TResult Function(Putback value)? putback,
    TResult Function(Delete value)? delete,
    TResult Function(RestoreAll value)? restoreAll,
    TResult Function(DeleteAll value)? deleteAll,
    required TResult orElse(),
  }) {
    if (delete != null) {
      return delete(this);
    }
    return orElse();
  }
}

abstract class Delete implements TrashEvent {
  const factory Delete(Trash trash) = _$Delete;

  Trash get trash => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DeleteCopyWith<Delete> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RestoreAllCopyWith<$Res> {
  factory $RestoreAllCopyWith(
          RestoreAll value, $Res Function(RestoreAll) then) =
      _$RestoreAllCopyWithImpl<$Res>;
}

/// @nodoc
class _$RestoreAllCopyWithImpl<$Res> extends _$TrashEventCopyWithImpl<$Res>
    implements $RestoreAllCopyWith<$Res> {
  _$RestoreAllCopyWithImpl(RestoreAll _value, $Res Function(RestoreAll) _then)
      : super(_value, (v) => _then(v as RestoreAll));

  @override
  RestoreAll get _value => super._value as RestoreAll;
}

/// @nodoc

class _$RestoreAll implements RestoreAll {
  const _$RestoreAll();

  @override
  String toString() {
    return 'TrashEvent.restoreAll()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) || (other is RestoreAll);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(List<Trash> trash) didReceiveTrash,
    required TResult Function(String trashId) putback,
    required TResult Function(Trash trash) delete,
    required TResult Function() restoreAll,
    required TResult Function() deleteAll,
  }) {
    return restoreAll();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<Trash> trash)? didReceiveTrash,
    TResult Function(String trashId)? putback,
    TResult Function(Trash trash)? delete,
    TResult Function()? restoreAll,
    TResult Function()? deleteAll,
  }) {
    return restoreAll?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<Trash> trash)? didReceiveTrash,
    TResult Function(String trashId)? putback,
    TResult Function(Trash trash)? delete,
    TResult Function()? restoreAll,
    TResult Function()? deleteAll,
    required TResult orElse(),
  }) {
    if (restoreAll != null) {
      return restoreAll();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(ReceiveTrash value) didReceiveTrash,
    required TResult Function(Putback value) putback,
    required TResult Function(Delete value) delete,
    required TResult Function(RestoreAll value) restoreAll,
    required TResult Function(DeleteAll value) deleteAll,
  }) {
    return restoreAll(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(ReceiveTrash value)? didReceiveTrash,
    TResult Function(Putback value)? putback,
    TResult Function(Delete value)? delete,
    TResult Function(RestoreAll value)? restoreAll,
    TResult Function(DeleteAll value)? deleteAll,
  }) {
    return restoreAll?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(ReceiveTrash value)? didReceiveTrash,
    TResult Function(Putback value)? putback,
    TResult Function(Delete value)? delete,
    TResult Function(RestoreAll value)? restoreAll,
    TResult Function(DeleteAll value)? deleteAll,
    required TResult orElse(),
  }) {
    if (restoreAll != null) {
      return restoreAll(this);
    }
    return orElse();
  }
}

abstract class RestoreAll implements TrashEvent {
  const factory RestoreAll() = _$RestoreAll;
}

/// @nodoc
abstract class $DeleteAllCopyWith<$Res> {
  factory $DeleteAllCopyWith(DeleteAll value, $Res Function(DeleteAll) then) =
      _$DeleteAllCopyWithImpl<$Res>;
}

/// @nodoc
class _$DeleteAllCopyWithImpl<$Res> extends _$TrashEventCopyWithImpl<$Res>
    implements $DeleteAllCopyWith<$Res> {
  _$DeleteAllCopyWithImpl(DeleteAll _value, $Res Function(DeleteAll) _then)
      : super(_value, (v) => _then(v as DeleteAll));

  @override
  DeleteAll get _value => super._value as DeleteAll;
}

/// @nodoc

class _$DeleteAll implements DeleteAll {
  const _$DeleteAll();

  @override
  String toString() {
    return 'TrashEvent.deleteAll()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) || (other is DeleteAll);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(List<Trash> trash) didReceiveTrash,
    required TResult Function(String trashId) putback,
    required TResult Function(Trash trash) delete,
    required TResult Function() restoreAll,
    required TResult Function() deleteAll,
  }) {
    return deleteAll();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<Trash> trash)? didReceiveTrash,
    TResult Function(String trashId)? putback,
    TResult Function(Trash trash)? delete,
    TResult Function()? restoreAll,
    TResult Function()? deleteAll,
  }) {
    return deleteAll?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<Trash> trash)? didReceiveTrash,
    TResult Function(String trashId)? putback,
    TResult Function(Trash trash)? delete,
    TResult Function()? restoreAll,
    TResult Function()? deleteAll,
    required TResult orElse(),
  }) {
    if (deleteAll != null) {
      return deleteAll();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(ReceiveTrash value) didReceiveTrash,
    required TResult Function(Putback value) putback,
    required TResult Function(Delete value) delete,
    required TResult Function(RestoreAll value) restoreAll,
    required TResult Function(DeleteAll value) deleteAll,
  }) {
    return deleteAll(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(ReceiveTrash value)? didReceiveTrash,
    TResult Function(Putback value)? putback,
    TResult Function(Delete value)? delete,
    TResult Function(RestoreAll value)? restoreAll,
    TResult Function(DeleteAll value)? deleteAll,
  }) {
    return deleteAll?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(ReceiveTrash value)? didReceiveTrash,
    TResult Function(Putback value)? putback,
    TResult Function(Delete value)? delete,
    TResult Function(RestoreAll value)? restoreAll,
    TResult Function(DeleteAll value)? deleteAll,
    required TResult orElse(),
  }) {
    if (deleteAll != null) {
      return deleteAll(this);
    }
    return orElse();
  }
}

abstract class DeleteAll implements TrashEvent {
  const factory DeleteAll() = _$DeleteAll;
}

/// @nodoc
class _$TrashStateTearOff {
  const _$TrashStateTearOff();

  _TrashState call(
      {required List<Trash> objects,
      required Either<Unit, FlowyError> successOrFailure}) {
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
  List<Trash> get objects => throw _privateConstructorUsedError;
  Either<Unit, FlowyError> get successOrFailure =>
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
  $Res call({List<Trash> objects, Either<Unit, FlowyError> successOrFailure});
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
              as List<Trash>,
      successOrFailure: successOrFailure == freezed
          ? _value.successOrFailure
          : successOrFailure // ignore: cast_nullable_to_non_nullable
              as Either<Unit, FlowyError>,
    ));
  }
}

/// @nodoc
abstract class _$TrashStateCopyWith<$Res> implements $TrashStateCopyWith<$Res> {
  factory _$TrashStateCopyWith(
          _TrashState value, $Res Function(_TrashState) then) =
      __$TrashStateCopyWithImpl<$Res>;
  @override
  $Res call({List<Trash> objects, Either<Unit, FlowyError> successOrFailure});
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
              as List<Trash>,
      successOrFailure: successOrFailure == freezed
          ? _value.successOrFailure
          : successOrFailure // ignore: cast_nullable_to_non_nullable
              as Either<Unit, FlowyError>,
    ));
  }
}

/// @nodoc

class _$_TrashState implements _TrashState {
  const _$_TrashState({required this.objects, required this.successOrFailure});

  @override
  final List<Trash> objects;
  @override
  final Either<Unit, FlowyError> successOrFailure;

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
      {required List<Trash> objects,
      required Either<Unit, FlowyError> successOrFailure}) = _$_TrashState;

  @override
  List<Trash> get objects => throw _privateConstructorUsedError;
  @override
  Either<Unit, FlowyError> get successOrFailure =>
      throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$TrashStateCopyWith<_TrashState> get copyWith =>
      throw _privateConstructorUsedError;
}
