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

  SetSelected setIsSelected(bool isSelected) {
    return SetSelected(
      isSelected,
    );
  }

  SetEditing setIsEditing(bool isEditing) {
    return SetEditing(
      isEditing,
    );
  }

  SetAction setAction(Option<ViewAction> action) {
    return SetAction(
      action,
    );
  }
}

/// @nodoc
const $ViewEvent = _$ViewEventTearOff();

/// @nodoc
mixin _$ViewEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool isSelected) setIsSelected,
    required TResult Function(bool isEditing) setIsEditing,
    required TResult Function(Option<ViewAction> action) setAction,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool isSelected)? setIsSelected,
    TResult Function(bool isEditing)? setIsEditing,
    TResult Function(Option<ViewAction> action)? setAction,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SetSelected value) setIsSelected,
    required TResult Function(SetEditing value) setIsEditing,
    required TResult Function(SetAction value) setAction,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SetSelected value)? setIsSelected,
    TResult Function(SetEditing value)? setIsEditing,
    TResult Function(SetAction value)? setAction,
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
abstract class $SetSelectedCopyWith<$Res> {
  factory $SetSelectedCopyWith(
          SetSelected value, $Res Function(SetSelected) then) =
      _$SetSelectedCopyWithImpl<$Res>;
  $Res call({bool isSelected});
}

/// @nodoc
class _$SetSelectedCopyWithImpl<$Res> extends _$ViewEventCopyWithImpl<$Res>
    implements $SetSelectedCopyWith<$Res> {
  _$SetSelectedCopyWithImpl(
      SetSelected _value, $Res Function(SetSelected) _then)
      : super(_value, (v) => _then(v as SetSelected));

  @override
  SetSelected get _value => super._value as SetSelected;

  @override
  $Res call({
    Object? isSelected = freezed,
  }) {
    return _then(SetSelected(
      isSelected == freezed
          ? _value.isSelected
          : isSelected // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$SetSelected implements SetSelected {
  const _$SetSelected(this.isSelected);

  @override
  final bool isSelected;

  @override
  String toString() {
    return 'ViewEvent.setIsSelected(isSelected: $isSelected)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is SetSelected &&
            (identical(other.isSelected, isSelected) ||
                const DeepCollectionEquality()
                    .equals(other.isSelected, isSelected)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(isSelected);

  @JsonKey(ignore: true)
  @override
  $SetSelectedCopyWith<SetSelected> get copyWith =>
      _$SetSelectedCopyWithImpl<SetSelected>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool isSelected) setIsSelected,
    required TResult Function(bool isEditing) setIsEditing,
    required TResult Function(Option<ViewAction> action) setAction,
  }) {
    return setIsSelected(isSelected);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool isSelected)? setIsSelected,
    TResult Function(bool isEditing)? setIsEditing,
    TResult Function(Option<ViewAction> action)? setAction,
    required TResult orElse(),
  }) {
    if (setIsSelected != null) {
      return setIsSelected(isSelected);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SetSelected value) setIsSelected,
    required TResult Function(SetEditing value) setIsEditing,
    required TResult Function(SetAction value) setAction,
  }) {
    return setIsSelected(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SetSelected value)? setIsSelected,
    TResult Function(SetEditing value)? setIsEditing,
    TResult Function(SetAction value)? setAction,
    required TResult orElse(),
  }) {
    if (setIsSelected != null) {
      return setIsSelected(this);
    }
    return orElse();
  }
}

abstract class SetSelected implements ViewEvent {
  const factory SetSelected(bool isSelected) = _$SetSelected;

  bool get isSelected => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SetSelectedCopyWith<SetSelected> get copyWith =>
      throw _privateConstructorUsedError;
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
    required TResult Function(bool isSelected) setIsSelected,
    required TResult Function(bool isEditing) setIsEditing,
    required TResult Function(Option<ViewAction> action) setAction,
  }) {
    return setIsEditing(isEditing);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool isSelected)? setIsSelected,
    TResult Function(bool isEditing)? setIsEditing,
    TResult Function(Option<ViewAction> action)? setAction,
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
    required TResult Function(SetSelected value) setIsSelected,
    required TResult Function(SetEditing value) setIsEditing,
    required TResult Function(SetAction value) setAction,
  }) {
    return setIsEditing(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SetSelected value)? setIsSelected,
    TResult Function(SetEditing value)? setIsEditing,
    TResult Function(SetAction value)? setAction,
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
abstract class $SetActionCopyWith<$Res> {
  factory $SetActionCopyWith(SetAction value, $Res Function(SetAction) then) =
      _$SetActionCopyWithImpl<$Res>;
  $Res call({Option<ViewAction> action});
}

/// @nodoc
class _$SetActionCopyWithImpl<$Res> extends _$ViewEventCopyWithImpl<$Res>
    implements $SetActionCopyWith<$Res> {
  _$SetActionCopyWithImpl(SetAction _value, $Res Function(SetAction) _then)
      : super(_value, (v) => _then(v as SetAction));

  @override
  SetAction get _value => super._value as SetAction;

  @override
  $Res call({
    Object? action = freezed,
  }) {
    return _then(SetAction(
      action == freezed
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as Option<ViewAction>,
    ));
  }
}

/// @nodoc

class _$SetAction implements SetAction {
  const _$SetAction(this.action);

  @override
  final Option<ViewAction> action;

  @override
  String toString() {
    return 'ViewEvent.setAction(action: $action)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is SetAction &&
            (identical(other.action, action) ||
                const DeepCollectionEquality().equals(other.action, action)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(action);

  @JsonKey(ignore: true)
  @override
  $SetActionCopyWith<SetAction> get copyWith =>
      _$SetActionCopyWithImpl<SetAction>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool isSelected) setIsSelected,
    required TResult Function(bool isEditing) setIsEditing,
    required TResult Function(Option<ViewAction> action) setAction,
  }) {
    return setAction(action);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool isSelected)? setIsSelected,
    TResult Function(bool isEditing)? setIsEditing,
    TResult Function(Option<ViewAction> action)? setAction,
    required TResult orElse(),
  }) {
    if (setAction != null) {
      return setAction(action);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SetSelected value) setIsSelected,
    required TResult Function(SetEditing value) setIsEditing,
    required TResult Function(SetAction value) setAction,
  }) {
    return setAction(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SetSelected value)? setIsSelected,
    TResult Function(SetEditing value)? setIsEditing,
    TResult Function(SetAction value)? setAction,
    required TResult orElse(),
  }) {
    if (setAction != null) {
      return setAction(this);
    }
    return orElse();
  }
}

abstract class SetAction implements ViewEvent {
  const factory SetAction(Option<ViewAction> action) = _$SetAction;

  Option<ViewAction> get action => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SetActionCopyWith<SetAction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
class _$ViewStateTearOff {
  const _$ViewStateTearOff();

  _ViewState call(
      {required View view,
      required bool isSelected,
      required bool isEditing,
      required Option<ViewAction> action,
      required Either<Unit, WorkspaceError> successOrFailure}) {
    return _ViewState(
      view: view,
      isSelected: isSelected,
      isEditing: isEditing,
      action: action,
      successOrFailure: successOrFailure,
    );
  }
}

/// @nodoc
const $ViewState = _$ViewStateTearOff();

/// @nodoc
mixin _$ViewState {
  View get view => throw _privateConstructorUsedError;
  bool get isSelected => throw _privateConstructorUsedError;
  bool get isEditing => throw _privateConstructorUsedError;
  Option<ViewAction> get action => throw _privateConstructorUsedError;
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
      bool isSelected,
      bool isEditing,
      Option<ViewAction> action,
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
    Object? isSelected = freezed,
    Object? isEditing = freezed,
    Object? action = freezed,
    Object? successOrFailure = freezed,
  }) {
    return _then(_value.copyWith(
      view: view == freezed
          ? _value.view
          : view // ignore: cast_nullable_to_non_nullable
              as View,
      isSelected: isSelected == freezed
          ? _value.isSelected
          : isSelected // ignore: cast_nullable_to_non_nullable
              as bool,
      isEditing: isEditing == freezed
          ? _value.isEditing
          : isEditing // ignore: cast_nullable_to_non_nullable
              as bool,
      action: action == freezed
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as Option<ViewAction>,
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
      bool isSelected,
      bool isEditing,
      Option<ViewAction> action,
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
    Object? isSelected = freezed,
    Object? isEditing = freezed,
    Object? action = freezed,
    Object? successOrFailure = freezed,
  }) {
    return _then(_ViewState(
      view: view == freezed
          ? _value.view
          : view // ignore: cast_nullable_to_non_nullable
              as View,
      isSelected: isSelected == freezed
          ? _value.isSelected
          : isSelected // ignore: cast_nullable_to_non_nullable
              as bool,
      isEditing: isEditing == freezed
          ? _value.isEditing
          : isEditing // ignore: cast_nullable_to_non_nullable
              as bool,
      action: action == freezed
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as Option<ViewAction>,
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
      required this.isSelected,
      required this.isEditing,
      required this.action,
      required this.successOrFailure});

  @override
  final View view;
  @override
  final bool isSelected;
  @override
  final bool isEditing;
  @override
  final Option<ViewAction> action;
  @override
  final Either<Unit, WorkspaceError> successOrFailure;

  @override
  String toString() {
    return 'ViewState(view: $view, isSelected: $isSelected, isEditing: $isEditing, action: $action, successOrFailure: $successOrFailure)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _ViewState &&
            (identical(other.view, view) ||
                const DeepCollectionEquality().equals(other.view, view)) &&
            (identical(other.isSelected, isSelected) ||
                const DeepCollectionEquality()
                    .equals(other.isSelected, isSelected)) &&
            (identical(other.isEditing, isEditing) ||
                const DeepCollectionEquality()
                    .equals(other.isEditing, isEditing)) &&
            (identical(other.action, action) ||
                const DeepCollectionEquality().equals(other.action, action)) &&
            (identical(other.successOrFailure, successOrFailure) ||
                const DeepCollectionEquality()
                    .equals(other.successOrFailure, successOrFailure)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(view) ^
      const DeepCollectionEquality().hash(isSelected) ^
      const DeepCollectionEquality().hash(isEditing) ^
      const DeepCollectionEquality().hash(action) ^
      const DeepCollectionEquality().hash(successOrFailure);

  @JsonKey(ignore: true)
  @override
  _$ViewStateCopyWith<_ViewState> get copyWith =>
      __$ViewStateCopyWithImpl<_ViewState>(this, _$identity);
}

abstract class _ViewState implements ViewState {
  const factory _ViewState(
      {required View view,
      required bool isSelected,
      required bool isEditing,
      required Option<ViewAction> action,
      required Either<Unit, WorkspaceError> successOrFailure}) = _$_ViewState;

  @override
  View get view => throw _privateConstructorUsedError;
  @override
  bool get isSelected => throw _privateConstructorUsedError;
  @override
  bool get isEditing => throw _privateConstructorUsedError;
  @override
  Option<ViewAction> get action => throw _privateConstructorUsedError;
  @override
  Either<Unit, WorkspaceError> get successOrFailure =>
      throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$ViewStateCopyWith<_ViewState> get copyWith =>
      throw _privateConstructorUsedError;
}
