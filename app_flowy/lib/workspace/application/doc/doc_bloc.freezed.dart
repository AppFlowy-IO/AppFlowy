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

  LoadDoc loadDoc() {
    return const LoadDoc();
  }
}

/// @nodoc
const $DocEvent = _$DocEventTearOff();

/// @nodoc
mixin _$DocEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadDoc,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadDoc,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadDoc value) loadDoc,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadDoc value)? loadDoc,
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
abstract class $LoadDocCopyWith<$Res> {
  factory $LoadDocCopyWith(LoadDoc value, $Res Function(LoadDoc) then) =
      _$LoadDocCopyWithImpl<$Res>;
}

/// @nodoc
class _$LoadDocCopyWithImpl<$Res> extends _$DocEventCopyWithImpl<$Res>
    implements $LoadDocCopyWith<$Res> {
  _$LoadDocCopyWithImpl(LoadDoc _value, $Res Function(LoadDoc) _then)
      : super(_value, (v) => _then(v as LoadDoc));

  @override
  LoadDoc get _value => super._value as LoadDoc;
}

/// @nodoc

class _$LoadDoc implements LoadDoc {
  const _$LoadDoc();

  @override
  String toString() {
    return 'DocEvent.loadDoc()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) || (other is LoadDoc);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadDoc,
  }) {
    return loadDoc();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadDoc,
    required TResult orElse(),
  }) {
    if (loadDoc != null) {
      return loadDoc();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadDoc value) loadDoc,
  }) {
    return loadDoc(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadDoc value)? loadDoc,
    required TResult orElse(),
  }) {
    if (loadDoc != null) {
      return loadDoc(this);
    }
    return orElse();
  }
}

abstract class LoadDoc implements DocEvent {
  const factory LoadDoc() = _$LoadDoc;
}

/// @nodoc
class _$DocStateTearOff {
  const _$DocStateTearOff();

  Loading loading() {
    return const Loading();
  }

  LoadedDoc loadDoc(FlowyDoc doc) {
    return LoadedDoc(
      doc,
    );
  }

  LoadFail loadFail(WorkspaceError error) {
    return LoadFail(
      error,
    );
  }
}

/// @nodoc
const $DocState = _$DocStateTearOff();

/// @nodoc
mixin _$DocState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(FlowyDoc doc) loadDoc,
    required TResult Function(WorkspaceError error) loadFail,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(FlowyDoc doc)? loadDoc,
    TResult Function(WorkspaceError error)? loadFail,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Loading value) loading,
    required TResult Function(LoadedDoc value) loadDoc,
    required TResult Function(LoadFail value) loadFail,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Loading value)? loading,
    TResult Function(LoadedDoc value)? loadDoc,
    TResult Function(LoadFail value)? loadFail,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DocStateCopyWith<$Res> {
  factory $DocStateCopyWith(DocState value, $Res Function(DocState) then) =
      _$DocStateCopyWithImpl<$Res>;
}

/// @nodoc
class _$DocStateCopyWithImpl<$Res> implements $DocStateCopyWith<$Res> {
  _$DocStateCopyWithImpl(this._value, this._then);

  final DocState _value;
  // ignore: unused_field
  final $Res Function(DocState) _then;
}

/// @nodoc
abstract class $LoadingCopyWith<$Res> {
  factory $LoadingCopyWith(Loading value, $Res Function(Loading) then) =
      _$LoadingCopyWithImpl<$Res>;
}

/// @nodoc
class _$LoadingCopyWithImpl<$Res> extends _$DocStateCopyWithImpl<$Res>
    implements $LoadingCopyWith<$Res> {
  _$LoadingCopyWithImpl(Loading _value, $Res Function(Loading) _then)
      : super(_value, (v) => _then(v as Loading));

  @override
  Loading get _value => super._value as Loading;
}

/// @nodoc

class _$Loading implements Loading {
  const _$Loading();

  @override
  String toString() {
    return 'DocState.loading()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) || (other is Loading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(FlowyDoc doc) loadDoc,
    required TResult Function(WorkspaceError error) loadFail,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(FlowyDoc doc)? loadDoc,
    TResult Function(WorkspaceError error)? loadFail,
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
    required TResult Function(Loading value) loading,
    required TResult Function(LoadedDoc value) loadDoc,
    required TResult Function(LoadFail value) loadFail,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Loading value)? loading,
    TResult Function(LoadedDoc value)? loadDoc,
    TResult Function(LoadFail value)? loadFail,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class Loading implements DocState {
  const factory Loading() = _$Loading;
}

/// @nodoc
abstract class $LoadedDocCopyWith<$Res> {
  factory $LoadedDocCopyWith(LoadedDoc value, $Res Function(LoadedDoc) then) =
      _$LoadedDocCopyWithImpl<$Res>;
  $Res call({FlowyDoc doc});
}

/// @nodoc
class _$LoadedDocCopyWithImpl<$Res> extends _$DocStateCopyWithImpl<$Res>
    implements $LoadedDocCopyWith<$Res> {
  _$LoadedDocCopyWithImpl(LoadedDoc _value, $Res Function(LoadedDoc) _then)
      : super(_value, (v) => _then(v as LoadedDoc));

  @override
  LoadedDoc get _value => super._value as LoadedDoc;

  @override
  $Res call({
    Object? doc = freezed,
  }) {
    return _then(LoadedDoc(
      doc == freezed
          ? _value.doc
          : doc // ignore: cast_nullable_to_non_nullable
              as FlowyDoc,
    ));
  }
}

/// @nodoc

class _$LoadedDoc implements LoadedDoc {
  const _$LoadedDoc(this.doc);

  @override
  final FlowyDoc doc;

  @override
  String toString() {
    return 'DocState.loadDoc(doc: $doc)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is LoadedDoc &&
            (identical(other.doc, doc) ||
                const DeepCollectionEquality().equals(other.doc, doc)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(doc);

  @JsonKey(ignore: true)
  @override
  $LoadedDocCopyWith<LoadedDoc> get copyWith =>
      _$LoadedDocCopyWithImpl<LoadedDoc>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(FlowyDoc doc) loadDoc,
    required TResult Function(WorkspaceError error) loadFail,
  }) {
    return loadDoc(doc);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(FlowyDoc doc)? loadDoc,
    TResult Function(WorkspaceError error)? loadFail,
    required TResult orElse(),
  }) {
    if (loadDoc != null) {
      return loadDoc(doc);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Loading value) loading,
    required TResult Function(LoadedDoc value) loadDoc,
    required TResult Function(LoadFail value) loadFail,
  }) {
    return loadDoc(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Loading value)? loading,
    TResult Function(LoadedDoc value)? loadDoc,
    TResult Function(LoadFail value)? loadFail,
    required TResult orElse(),
  }) {
    if (loadDoc != null) {
      return loadDoc(this);
    }
    return orElse();
  }
}

abstract class LoadedDoc implements DocState {
  const factory LoadedDoc(FlowyDoc doc) = _$LoadedDoc;

  FlowyDoc get doc => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LoadedDocCopyWith<LoadedDoc> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LoadFailCopyWith<$Res> {
  factory $LoadFailCopyWith(LoadFail value, $Res Function(LoadFail) then) =
      _$LoadFailCopyWithImpl<$Res>;
  $Res call({WorkspaceError error});
}

/// @nodoc
class _$LoadFailCopyWithImpl<$Res> extends _$DocStateCopyWithImpl<$Res>
    implements $LoadFailCopyWith<$Res> {
  _$LoadFailCopyWithImpl(LoadFail _value, $Res Function(LoadFail) _then)
      : super(_value, (v) => _then(v as LoadFail));

  @override
  LoadFail get _value => super._value as LoadFail;

  @override
  $Res call({
    Object? error = freezed,
  }) {
    return _then(LoadFail(
      error == freezed
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as WorkspaceError,
    ));
  }
}

/// @nodoc

class _$LoadFail implements LoadFail {
  const _$LoadFail(this.error);

  @override
  final WorkspaceError error;

  @override
  String toString() {
    return 'DocState.loadFail(error: $error)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is LoadFail &&
            (identical(other.error, error) ||
                const DeepCollectionEquality().equals(other.error, error)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(error);

  @JsonKey(ignore: true)
  @override
  $LoadFailCopyWith<LoadFail> get copyWith =>
      _$LoadFailCopyWithImpl<LoadFail>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(FlowyDoc doc) loadDoc,
    required TResult Function(WorkspaceError error) loadFail,
  }) {
    return loadFail(error);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(FlowyDoc doc)? loadDoc,
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
    required TResult Function(Loading value) loading,
    required TResult Function(LoadedDoc value) loadDoc,
    required TResult Function(LoadFail value) loadFail,
  }) {
    return loadFail(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Loading value)? loading,
    TResult Function(LoadedDoc value)? loadDoc,
    TResult Function(LoadFail value)? loadFail,
    required TResult orElse(),
  }) {
    if (loadFail != null) {
      return loadFail(this);
    }
    return orElse();
  }
}

abstract class LoadFail implements DocState {
  const factory LoadFail(WorkspaceError error) = _$LoadFail;

  WorkspaceError get error => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LoadFailCopyWith<LoadFail> get copyWith =>
      throw _privateConstructorUsedError;
}
