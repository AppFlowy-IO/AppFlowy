// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides

part of 'doc_watch_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
class _$DocWatchEventTearOff {
  const _$DocWatchEventTearOff();

  Started started() {
    return const Started();
  }
}

/// @nodoc
const $DocWatchEvent = _$DocWatchEventTearOff();

/// @nodoc
mixin _$DocWatchEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Started value) started,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Started value)? started,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DocWatchEventCopyWith<$Res> {
  factory $DocWatchEventCopyWith(
          DocWatchEvent value, $Res Function(DocWatchEvent) then) =
      _$DocWatchEventCopyWithImpl<$Res>;
}

/// @nodoc
class _$DocWatchEventCopyWithImpl<$Res>
    implements $DocWatchEventCopyWith<$Res> {
  _$DocWatchEventCopyWithImpl(this._value, this._then);

  final DocWatchEvent _value;
  // ignore: unused_field
  final $Res Function(DocWatchEvent) _then;
}

/// @nodoc
abstract class $StartedCopyWith<$Res> {
  factory $StartedCopyWith(Started value, $Res Function(Started) then) =
      _$StartedCopyWithImpl<$Res>;
}

/// @nodoc
class _$StartedCopyWithImpl<$Res> extends _$DocWatchEventCopyWithImpl<$Res>
    implements $StartedCopyWith<$Res> {
  _$StartedCopyWithImpl(Started _value, $Res Function(Started) _then)
      : super(_value, (v) => _then(v as Started));

  @override
  Started get _value => super._value as Started;
}

/// @nodoc

class _$Started implements Started {
  const _$Started();

  @override
  String toString() {
    return 'DocWatchEvent.started()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) || (other is Started);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
  }) {
    return started();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
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
    required TResult Function(Started value) started,
  }) {
    return started(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Started value)? started,
    required TResult orElse(),
  }) {
    if (started != null) {
      return started(this);
    }
    return orElse();
  }
}

abstract class Started implements DocWatchEvent {
  const factory Started() = _$Started;
}

/// @nodoc
class _$DocWatchStateTearOff {
  const _$DocWatchStateTearOff();

  Loading loading() {
    return const Loading();
  }

  LoadDoc loadDoc(Doc doc) {
    return LoadDoc(
      doc,
    );
  }

  LoadFail loadFail(EditorError error) {
    return LoadFail(
      error,
    );
  }
}

/// @nodoc
const $DocWatchState = _$DocWatchStateTearOff();

/// @nodoc
mixin _$DocWatchState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(Doc doc) loadDoc,
    required TResult Function(EditorError error) loadFail,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(Doc doc)? loadDoc,
    TResult Function(EditorError error)? loadFail,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Loading value) loading,
    required TResult Function(LoadDoc value) loadDoc,
    required TResult Function(LoadFail value) loadFail,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Loading value)? loading,
    TResult Function(LoadDoc value)? loadDoc,
    TResult Function(LoadFail value)? loadFail,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DocWatchStateCopyWith<$Res> {
  factory $DocWatchStateCopyWith(
          DocWatchState value, $Res Function(DocWatchState) then) =
      _$DocWatchStateCopyWithImpl<$Res>;
}

/// @nodoc
class _$DocWatchStateCopyWithImpl<$Res>
    implements $DocWatchStateCopyWith<$Res> {
  _$DocWatchStateCopyWithImpl(this._value, this._then);

  final DocWatchState _value;
  // ignore: unused_field
  final $Res Function(DocWatchState) _then;
}

/// @nodoc
abstract class $LoadingCopyWith<$Res> {
  factory $LoadingCopyWith(Loading value, $Res Function(Loading) then) =
      _$LoadingCopyWithImpl<$Res>;
}

/// @nodoc
class _$LoadingCopyWithImpl<$Res> extends _$DocWatchStateCopyWithImpl<$Res>
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
    return 'DocWatchState.loading()';
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
    required TResult Function(Doc doc) loadDoc,
    required TResult Function(EditorError error) loadFail,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(Doc doc)? loadDoc,
    TResult Function(EditorError error)? loadFail,
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
    required TResult Function(LoadDoc value) loadDoc,
    required TResult Function(LoadFail value) loadFail,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Loading value)? loading,
    TResult Function(LoadDoc value)? loadDoc,
    TResult Function(LoadFail value)? loadFail,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class Loading implements DocWatchState {
  const factory Loading() = _$Loading;
}

/// @nodoc
abstract class $LoadDocCopyWith<$Res> {
  factory $LoadDocCopyWith(LoadDoc value, $Res Function(LoadDoc) then) =
      _$LoadDocCopyWithImpl<$Res>;
  $Res call({Doc doc});
}

/// @nodoc
class _$LoadDocCopyWithImpl<$Res> extends _$DocWatchStateCopyWithImpl<$Res>
    implements $LoadDocCopyWith<$Res> {
  _$LoadDocCopyWithImpl(LoadDoc _value, $Res Function(LoadDoc) _then)
      : super(_value, (v) => _then(v as LoadDoc));

  @override
  LoadDoc get _value => super._value as LoadDoc;

  @override
  $Res call({
    Object? doc = freezed,
  }) {
    return _then(LoadDoc(
      doc == freezed
          ? _value.doc
          : doc // ignore: cast_nullable_to_non_nullable
              as Doc,
    ));
  }
}

/// @nodoc

class _$LoadDoc implements LoadDoc {
  const _$LoadDoc(this.doc);

  @override
  final Doc doc;

  @override
  String toString() {
    return 'DocWatchState.loadDoc(doc: $doc)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is LoadDoc &&
            (identical(other.doc, doc) ||
                const DeepCollectionEquality().equals(other.doc, doc)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(doc);

  @JsonKey(ignore: true)
  @override
  $LoadDocCopyWith<LoadDoc> get copyWith =>
      _$LoadDocCopyWithImpl<LoadDoc>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(Doc doc) loadDoc,
    required TResult Function(EditorError error) loadFail,
  }) {
    return loadDoc(doc);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(Doc doc)? loadDoc,
    TResult Function(EditorError error)? loadFail,
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
    required TResult Function(LoadDoc value) loadDoc,
    required TResult Function(LoadFail value) loadFail,
  }) {
    return loadDoc(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Loading value)? loading,
    TResult Function(LoadDoc value)? loadDoc,
    TResult Function(LoadFail value)? loadFail,
    required TResult orElse(),
  }) {
    if (loadDoc != null) {
      return loadDoc(this);
    }
    return orElse();
  }
}

abstract class LoadDoc implements DocWatchState {
  const factory LoadDoc(Doc doc) = _$LoadDoc;

  Doc get doc => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LoadDocCopyWith<LoadDoc> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LoadFailCopyWith<$Res> {
  factory $LoadFailCopyWith(LoadFail value, $Res Function(LoadFail) then) =
      _$LoadFailCopyWithImpl<$Res>;
  $Res call({EditorError error});
}

/// @nodoc
class _$LoadFailCopyWithImpl<$Res> extends _$DocWatchStateCopyWithImpl<$Res>
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
              as EditorError,
    ));
  }
}

/// @nodoc

class _$LoadFail implements LoadFail {
  const _$LoadFail(this.error);

  @override
  final EditorError error;

  @override
  String toString() {
    return 'DocWatchState.loadFail(error: $error)';
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
    required TResult Function(Doc doc) loadDoc,
    required TResult Function(EditorError error) loadFail,
  }) {
    return loadFail(error);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(Doc doc)? loadDoc,
    TResult Function(EditorError error)? loadFail,
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
    required TResult Function(LoadDoc value) loadDoc,
    required TResult Function(LoadFail value) loadFail,
  }) {
    return loadFail(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Loading value)? loading,
    TResult Function(LoadDoc value)? loadDoc,
    TResult Function(LoadFail value)? loadFail,
    required TResult orElse(),
  }) {
    if (loadFail != null) {
      return loadFail(this);
    }
    return orElse();
  }
}

abstract class LoadFail implements DocWatchState {
  const factory LoadFail(EditorError error) = _$LoadFail;

  EditorError get error => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LoadFailCopyWith<LoadFail> get copyWith =>
      throw _privateConstructorUsedError;
}
