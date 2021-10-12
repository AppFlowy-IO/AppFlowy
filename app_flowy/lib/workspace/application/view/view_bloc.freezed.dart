// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

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

  SetEditing setIsEditing(bool isEditing) {
    return SetEditing(
      isEditing,
    );
  }

  Rename rename(String newName) {
    return Rename(
      newName,
    );
  }

  Delete delete() {
    return const Delete();
  }

  ViewDidUpdate viewDidUpdate(Either<View, WorkspaceError> result) {
    return ViewDidUpdate(
      result,
    );
  }
}

/// @nodoc
const $ViewEvent = _$ViewEventTearOff();

/// @nodoc
mixin _$ViewEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(bool isEditing) setIsEditing,
    required TResult Function(String newName) rename,
    required TResult Function() delete,
    required TResult Function(Either<View, WorkspaceError> result)
        viewDidUpdate,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(bool isEditing)? setIsEditing,
    TResult Function(String newName)? rename,
    TResult Function()? delete,
    TResult Function(Either<View, WorkspaceError> result)? viewDidUpdate,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(SetEditing value) setIsEditing,
    required TResult Function(Rename value) rename,
    required TResult Function(Delete value) delete,
    required TResult Function(ViewDidUpdate value) viewDidUpdate,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(SetEditing value)? setIsEditing,
    TResult Function(Rename value)? rename,
    TResult Function(Delete value)? delete,
    TResult Function(ViewDidUpdate value)? viewDidUpdate,
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
    required TResult Function(bool isEditing) setIsEditing,
    required TResult Function(String newName) rename,
    required TResult Function() delete,
    required TResult Function(Either<View, WorkspaceError> result)
        viewDidUpdate,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(bool isEditing)? setIsEditing,
    TResult Function(String newName)? rename,
    TResult Function()? delete,
    TResult Function(Either<View, WorkspaceError> result)? viewDidUpdate,
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
    required TResult Function(SetEditing value) setIsEditing,
    required TResult Function(Rename value) rename,
    required TResult Function(Delete value) delete,
    required TResult Function(ViewDidUpdate value) viewDidUpdate,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(SetEditing value)? setIsEditing,
    TResult Function(Rename value)? rename,
    TResult Function(Delete value)? delete,
    TResult Function(ViewDidUpdate value)? viewDidUpdate,
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
abstract class $SetEditingCopyWith<$Res> {
  factory $SetEditingCopyWith(
          SetEditing value, $Res Function(SetEditing) then) =
      _$SetEditingCopyWithImpl<$Res>;
  $Res call({bool isEditing});
}

/// @nodoc
class _$SetEditingCopyWithImpl<$Res> extends _$ViewEventCopyWithImpl<$Res>
    implements $SetEditingCopyWith<$Res> {
  _$SetEditingCopyWithImpl(SetEditing _value, $Res Function(SetEditing) _then)
      : super(_value, (v) => _then(v as SetEditing));

  @override
  SetEditing get _value => super._value as SetEditing;

  @override
  $Res call({
    Object? isEditing = freezed,
  }) {
    return _then(SetEditing(
      isEditing == freezed
          ? _value.isEditing
          : isEditing // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$SetEditing implements SetEditing {
  const _$SetEditing(this.isEditing);

  @override
  final bool isEditing;

  @override
  String toString() {
    return 'ViewEvent.setIsEditing(isEditing: $isEditing)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is SetEditing &&
            (identical(other.isEditing, isEditing) ||
                const DeepCollectionEquality()
                    .equals(other.isEditing, isEditing)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(isEditing);

  @JsonKey(ignore: true)
  @override
  $SetEditingCopyWith<SetEditing> get copyWith =>
      _$SetEditingCopyWithImpl<SetEditing>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(bool isEditing) setIsEditing,
    required TResult Function(String newName) rename,
    required TResult Function() delete,
    required TResult Function(Either<View, WorkspaceError> result)
        viewDidUpdate,
  }) {
    return setIsEditing(isEditing);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(bool isEditing)? setIsEditing,
    TResult Function(String newName)? rename,
    TResult Function()? delete,
    TResult Function(Either<View, WorkspaceError> result)? viewDidUpdate,
    required TResult orElse(),
  }) {
    if (setIsEditing != null) {
      return setIsEditing(isEditing);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(SetEditing value) setIsEditing,
    required TResult Function(Rename value) rename,
    required TResult Function(Delete value) delete,
    required TResult Function(ViewDidUpdate value) viewDidUpdate,
  }) {
    return setIsEditing(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(SetEditing value)? setIsEditing,
    TResult Function(Rename value)? rename,
    TResult Function(Delete value)? delete,
    TResult Function(ViewDidUpdate value)? viewDidUpdate,
    required TResult orElse(),
  }) {
    if (setIsEditing != null) {
      return setIsEditing(this);
    }
    return orElse();
  }
}

abstract class SetEditing implements ViewEvent {
  const factory SetEditing(bool isEditing) = _$SetEditing;

  bool get isEditing => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SetEditingCopyWith<SetEditing> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RenameCopyWith<$Res> {
  factory $RenameCopyWith(Rename value, $Res Function(Rename) then) =
      _$RenameCopyWithImpl<$Res>;
  $Res call({String newName});
}

/// @nodoc
class _$RenameCopyWithImpl<$Res> extends _$ViewEventCopyWithImpl<$Res>
    implements $RenameCopyWith<$Res> {
  _$RenameCopyWithImpl(Rename _value, $Res Function(Rename) _then)
      : super(_value, (v) => _then(v as Rename));

  @override
  Rename get _value => super._value as Rename;

  @override
  $Res call({
    Object? newName = freezed,
  }) {
    return _then(Rename(
      newName == freezed
          ? _value.newName
          : newName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$Rename implements Rename {
  const _$Rename(this.newName);

  @override
  final String newName;

  @override
  String toString() {
    return 'ViewEvent.rename(newName: $newName)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is Rename &&
            (identical(other.newName, newName) ||
                const DeepCollectionEquality().equals(other.newName, newName)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(newName);

  @JsonKey(ignore: true)
  @override
  $RenameCopyWith<Rename> get copyWith =>
      _$RenameCopyWithImpl<Rename>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(bool isEditing) setIsEditing,
    required TResult Function(String newName) rename,
    required TResult Function() delete,
    required TResult Function(Either<View, WorkspaceError> result)
        viewDidUpdate,
  }) {
    return rename(newName);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(bool isEditing)? setIsEditing,
    TResult Function(String newName)? rename,
    TResult Function()? delete,
    TResult Function(Either<View, WorkspaceError> result)? viewDidUpdate,
    required TResult orElse(),
  }) {
    if (rename != null) {
      return rename(newName);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(SetEditing value) setIsEditing,
    required TResult Function(Rename value) rename,
    required TResult Function(Delete value) delete,
    required TResult Function(ViewDidUpdate value) viewDidUpdate,
  }) {
    return rename(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(SetEditing value)? setIsEditing,
    TResult Function(Rename value)? rename,
    TResult Function(Delete value)? delete,
    TResult Function(ViewDidUpdate value)? viewDidUpdate,
    required TResult orElse(),
  }) {
    if (rename != null) {
      return rename(this);
    }
    return orElse();
  }
}

abstract class Rename implements ViewEvent {
  const factory Rename(String newName) = _$Rename;

  String get newName => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RenameCopyWith<Rename> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeleteCopyWith<$Res> {
  factory $DeleteCopyWith(Delete value, $Res Function(Delete) then) =
      _$DeleteCopyWithImpl<$Res>;
}

/// @nodoc
class _$DeleteCopyWithImpl<$Res> extends _$ViewEventCopyWithImpl<$Res>
    implements $DeleteCopyWith<$Res> {
  _$DeleteCopyWithImpl(Delete _value, $Res Function(Delete) _then)
      : super(_value, (v) => _then(v as Delete));

  @override
  Delete get _value => super._value as Delete;
}

/// @nodoc

class _$Delete implements Delete {
  const _$Delete();

  @override
  String toString() {
    return 'ViewEvent.delete()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) || (other is Delete);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(bool isEditing) setIsEditing,
    required TResult Function(String newName) rename,
    required TResult Function() delete,
    required TResult Function(Either<View, WorkspaceError> result)
        viewDidUpdate,
  }) {
    return delete();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(bool isEditing)? setIsEditing,
    TResult Function(String newName)? rename,
    TResult Function()? delete,
    TResult Function(Either<View, WorkspaceError> result)? viewDidUpdate,
    required TResult orElse(),
  }) {
    if (delete != null) {
      return delete();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(SetEditing value) setIsEditing,
    required TResult Function(Rename value) rename,
    required TResult Function(Delete value) delete,
    required TResult Function(ViewDidUpdate value) viewDidUpdate,
  }) {
    return delete(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(SetEditing value)? setIsEditing,
    TResult Function(Rename value)? rename,
    TResult Function(Delete value)? delete,
    TResult Function(ViewDidUpdate value)? viewDidUpdate,
    required TResult orElse(),
  }) {
    if (delete != null) {
      return delete(this);
    }
    return orElse();
  }
}

abstract class Delete implements ViewEvent {
  const factory Delete() = _$Delete;
}

/// @nodoc
abstract class $ViewDidUpdateCopyWith<$Res> {
  factory $ViewDidUpdateCopyWith(
          ViewDidUpdate value, $Res Function(ViewDidUpdate) then) =
      _$ViewDidUpdateCopyWithImpl<$Res>;
  $Res call({Either<View, WorkspaceError> result});
}

/// @nodoc
class _$ViewDidUpdateCopyWithImpl<$Res> extends _$ViewEventCopyWithImpl<$Res>
    implements $ViewDidUpdateCopyWith<$Res> {
  _$ViewDidUpdateCopyWithImpl(
      ViewDidUpdate _value, $Res Function(ViewDidUpdate) _then)
      : super(_value, (v) => _then(v as ViewDidUpdate));

  @override
  ViewDidUpdate get _value => super._value as ViewDidUpdate;

  @override
  $Res call({
    Object? result = freezed,
  }) {
    return _then(ViewDidUpdate(
      result == freezed
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as Either<View, WorkspaceError>,
    ));
  }
}

/// @nodoc

class _$ViewDidUpdate implements ViewDidUpdate {
  const _$ViewDidUpdate(this.result);

  @override
  final Either<View, WorkspaceError> result;

  @override
  String toString() {
    return 'ViewEvent.viewDidUpdate(result: $result)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is ViewDidUpdate &&
            (identical(other.result, result) ||
                const DeepCollectionEquality().equals(other.result, result)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(result);

  @JsonKey(ignore: true)
  @override
  $ViewDidUpdateCopyWith<ViewDidUpdate> get copyWith =>
      _$ViewDidUpdateCopyWithImpl<ViewDidUpdate>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(bool isEditing) setIsEditing,
    required TResult Function(String newName) rename,
    required TResult Function() delete,
    required TResult Function(Either<View, WorkspaceError> result)
        viewDidUpdate,
  }) {
    return viewDidUpdate(result);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(bool isEditing)? setIsEditing,
    TResult Function(String newName)? rename,
    TResult Function()? delete,
    TResult Function(Either<View, WorkspaceError> result)? viewDidUpdate,
    required TResult orElse(),
  }) {
    if (viewDidUpdate != null) {
      return viewDidUpdate(result);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(SetEditing value) setIsEditing,
    required TResult Function(Rename value) rename,
    required TResult Function(Delete value) delete,
    required TResult Function(ViewDidUpdate value) viewDidUpdate,
  }) {
    return viewDidUpdate(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(SetEditing value)? setIsEditing,
    TResult Function(Rename value)? rename,
    TResult Function(Delete value)? delete,
    TResult Function(ViewDidUpdate value)? viewDidUpdate,
    required TResult orElse(),
  }) {
    if (viewDidUpdate != null) {
      return viewDidUpdate(this);
    }
    return orElse();
  }
}

abstract class ViewDidUpdate implements ViewEvent {
  const factory ViewDidUpdate(Either<View, WorkspaceError> result) =
      _$ViewDidUpdate;

  Either<View, WorkspaceError> get result => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ViewDidUpdateCopyWith<ViewDidUpdate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
class _$ViewStateTearOff {
  const _$ViewStateTearOff();

  _ViewState call(
      {required View view,
      required bool isEditing,
      required Either<Unit, WorkspaceError> successOrFailure}) {
    return _ViewState(
      view: view,
      isEditing: isEditing,
      successOrFailure: successOrFailure,
    );
  }
}

/// @nodoc
const $ViewState = _$ViewStateTearOff();

/// @nodoc
mixin _$ViewState {
  View get view => throw _privateConstructorUsedError;
  bool get isEditing => throw _privateConstructorUsedError;
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
      {View view,
      bool isEditing,
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
    Object? view = freezed,
    Object? isEditing = freezed,
    Object? successOrFailure = freezed,
  }) {
    return _then(_value.copyWith(
      view: view == freezed
          ? _value.view
          : view // ignore: cast_nullable_to_non_nullable
              as View,
      isEditing: isEditing == freezed
          ? _value.isEditing
          : isEditing // ignore: cast_nullable_to_non_nullable
              as bool,
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
      {View view,
      bool isEditing,
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
    Object? view = freezed,
    Object? isEditing = freezed,
    Object? successOrFailure = freezed,
  }) {
    return _then(_ViewState(
      view: view == freezed
          ? _value.view
          : view // ignore: cast_nullable_to_non_nullable
              as View,
      isEditing: isEditing == freezed
          ? _value.isEditing
          : isEditing // ignore: cast_nullable_to_non_nullable
              as bool,
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
      {required this.view,
      required this.isEditing,
      required this.successOrFailure});

  @override
  final View view;
  @override
  final bool isEditing;
  @override
  final Either<Unit, WorkspaceError> successOrFailure;

  @override
  String toString() {
    return 'ViewState(view: $view, isEditing: $isEditing, successOrFailure: $successOrFailure)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _ViewState &&
            (identical(other.view, view) ||
                const DeepCollectionEquality().equals(other.view, view)) &&
            (identical(other.isEditing, isEditing) ||
                const DeepCollectionEquality()
                    .equals(other.isEditing, isEditing)) &&
            (identical(other.successOrFailure, successOrFailure) ||
                const DeepCollectionEquality()
                    .equals(other.successOrFailure, successOrFailure)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(view) ^
      const DeepCollectionEquality().hash(isEditing) ^
      const DeepCollectionEquality().hash(successOrFailure);

  @JsonKey(ignore: true)
  @override
  _$ViewStateCopyWith<_ViewState> get copyWith =>
      __$ViewStateCopyWithImpl<_ViewState>(this, _$identity);
}

abstract class _ViewState implements ViewState {
  const factory _ViewState(
      {required View view,
      required bool isEditing,
      required Either<Unit, WorkspaceError> successOrFailure}) = _$_ViewState;

  @override
  View get view => throw _privateConstructorUsedError;
  @override
  bool get isEditing => throw _privateConstructorUsedError;
  @override
  Either<Unit, WorkspaceError> get successOrFailure =>
      throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$ViewStateCopyWith<_ViewState> get copyWith =>
      throw _privateConstructorUsedError;
}
