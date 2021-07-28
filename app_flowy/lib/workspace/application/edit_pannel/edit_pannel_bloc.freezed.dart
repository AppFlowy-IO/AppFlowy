// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'edit_pannel_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
class _$EditPannelEventTearOff {
  const _$EditPannelEventTearOff();

  _StartEdit startEdit(EditPannelContext context) {
    return _StartEdit(
      context,
    );
  }

  _EndEdit endEdit(EditPannelContext context) {
    return _EndEdit(
      context,
    );
  }
}

/// @nodoc
const $EditPannelEvent = _$EditPannelEventTearOff();

/// @nodoc
mixin _$EditPannelEvent {
  EditPannelContext get context => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(EditPannelContext context) startEdit,
    required TResult Function(EditPannelContext context) endEdit,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(EditPannelContext context)? startEdit,
    TResult Function(EditPannelContext context)? endEdit,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_StartEdit value) startEdit,
    required TResult Function(_EndEdit value) endEdit,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_StartEdit value)? startEdit,
    TResult Function(_EndEdit value)? endEdit,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $EditPannelEventCopyWith<EditPannelEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EditPannelEventCopyWith<$Res> {
  factory $EditPannelEventCopyWith(
          EditPannelEvent value, $Res Function(EditPannelEvent) then) =
      _$EditPannelEventCopyWithImpl<$Res>;
  $Res call({EditPannelContext context});
}

/// @nodoc
class _$EditPannelEventCopyWithImpl<$Res>
    implements $EditPannelEventCopyWith<$Res> {
  _$EditPannelEventCopyWithImpl(this._value, this._then);

  final EditPannelEvent _value;
  // ignore: unused_field
  final $Res Function(EditPannelEvent) _then;

  @override
  $Res call({
    Object? context = freezed,
  }) {
    return _then(_value.copyWith(
      context: context == freezed
          ? _value.context
          : context // ignore: cast_nullable_to_non_nullable
              as EditPannelContext,
    ));
  }
}

/// @nodoc
abstract class _$StartEditCopyWith<$Res>
    implements $EditPannelEventCopyWith<$Res> {
  factory _$StartEditCopyWith(
          _StartEdit value, $Res Function(_StartEdit) then) =
      __$StartEditCopyWithImpl<$Res>;
  @override
  $Res call({EditPannelContext context});
}

/// @nodoc
class __$StartEditCopyWithImpl<$Res> extends _$EditPannelEventCopyWithImpl<$Res>
    implements _$StartEditCopyWith<$Res> {
  __$StartEditCopyWithImpl(_StartEdit _value, $Res Function(_StartEdit) _then)
      : super(_value, (v) => _then(v as _StartEdit));

  @override
  _StartEdit get _value => super._value as _StartEdit;

  @override
  $Res call({
    Object? context = freezed,
  }) {
    return _then(_StartEdit(
      context == freezed
          ? _value.context
          : context // ignore: cast_nullable_to_non_nullable
              as EditPannelContext,
    ));
  }
}

/// @nodoc

class _$_StartEdit implements _StartEdit {
  const _$_StartEdit(this.context);

  @override
  final EditPannelContext context;

  @override
  String toString() {
    return 'EditPannelEvent.startEdit(context: $context)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _StartEdit &&
            (identical(other.context, context) ||
                const DeepCollectionEquality().equals(other.context, context)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(context);

  @JsonKey(ignore: true)
  @override
  _$StartEditCopyWith<_StartEdit> get copyWith =>
      __$StartEditCopyWithImpl<_StartEdit>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(EditPannelContext context) startEdit,
    required TResult Function(EditPannelContext context) endEdit,
  }) {
    return startEdit(context);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(EditPannelContext context)? startEdit,
    TResult Function(EditPannelContext context)? endEdit,
    required TResult orElse(),
  }) {
    if (startEdit != null) {
      return startEdit(context);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_StartEdit value) startEdit,
    required TResult Function(_EndEdit value) endEdit,
  }) {
    return startEdit(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_StartEdit value)? startEdit,
    TResult Function(_EndEdit value)? endEdit,
    required TResult orElse(),
  }) {
    if (startEdit != null) {
      return startEdit(this);
    }
    return orElse();
  }
}

abstract class _StartEdit implements EditPannelEvent {
  const factory _StartEdit(EditPannelContext context) = _$_StartEdit;

  @override
  EditPannelContext get context => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$StartEditCopyWith<_StartEdit> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$EndEditCopyWith<$Res>
    implements $EditPannelEventCopyWith<$Res> {
  factory _$EndEditCopyWith(_EndEdit value, $Res Function(_EndEdit) then) =
      __$EndEditCopyWithImpl<$Res>;
  @override
  $Res call({EditPannelContext context});
}

/// @nodoc
class __$EndEditCopyWithImpl<$Res> extends _$EditPannelEventCopyWithImpl<$Res>
    implements _$EndEditCopyWith<$Res> {
  __$EndEditCopyWithImpl(_EndEdit _value, $Res Function(_EndEdit) _then)
      : super(_value, (v) => _then(v as _EndEdit));

  @override
  _EndEdit get _value => super._value as _EndEdit;

  @override
  $Res call({
    Object? context = freezed,
  }) {
    return _then(_EndEdit(
      context == freezed
          ? _value.context
          : context // ignore: cast_nullable_to_non_nullable
              as EditPannelContext,
    ));
  }
}

/// @nodoc

class _$_EndEdit implements _EndEdit {
  const _$_EndEdit(this.context);

  @override
  final EditPannelContext context;

  @override
  String toString() {
    return 'EditPannelEvent.endEdit(context: $context)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _EndEdit &&
            (identical(other.context, context) ||
                const DeepCollectionEquality().equals(other.context, context)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(context);

  @JsonKey(ignore: true)
  @override
  _$EndEditCopyWith<_EndEdit> get copyWith =>
      __$EndEditCopyWithImpl<_EndEdit>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(EditPannelContext context) startEdit,
    required TResult Function(EditPannelContext context) endEdit,
  }) {
    return endEdit(context);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(EditPannelContext context)? startEdit,
    TResult Function(EditPannelContext context)? endEdit,
    required TResult orElse(),
  }) {
    if (endEdit != null) {
      return endEdit(context);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_StartEdit value) startEdit,
    required TResult Function(_EndEdit value) endEdit,
  }) {
    return endEdit(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_StartEdit value)? startEdit,
    TResult Function(_EndEdit value)? endEdit,
    required TResult orElse(),
  }) {
    if (endEdit != null) {
      return endEdit(this);
    }
    return orElse();
  }
}

abstract class _EndEdit implements EditPannelEvent {
  const factory _EndEdit(EditPannelContext context) = _$_EndEdit;

  @override
  EditPannelContext get context => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$EndEditCopyWith<_EndEdit> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
class _$EditPannelStateTearOff {
  const _$EditPannelStateTearOff();

  _EditPannelState call(
      {required bool isEditing,
      required Option<EditPannelContext> editContext}) {
    return _EditPannelState(
      isEditing: isEditing,
      editContext: editContext,
    );
  }
}

/// @nodoc
const $EditPannelState = _$EditPannelStateTearOff();

/// @nodoc
mixin _$EditPannelState {
  bool get isEditing => throw _privateConstructorUsedError;
  Option<EditPannelContext> get editContext =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $EditPannelStateCopyWith<EditPannelState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EditPannelStateCopyWith<$Res> {
  factory $EditPannelStateCopyWith(
          EditPannelState value, $Res Function(EditPannelState) then) =
      _$EditPannelStateCopyWithImpl<$Res>;
  $Res call({bool isEditing, Option<EditPannelContext> editContext});
}

/// @nodoc
class _$EditPannelStateCopyWithImpl<$Res>
    implements $EditPannelStateCopyWith<$Res> {
  _$EditPannelStateCopyWithImpl(this._value, this._then);

  final EditPannelState _value;
  // ignore: unused_field
  final $Res Function(EditPannelState) _then;

  @override
  $Res call({
    Object? isEditing = freezed,
    Object? editContext = freezed,
  }) {
    return _then(_value.copyWith(
      isEditing: isEditing == freezed
          ? _value.isEditing
          : isEditing // ignore: cast_nullable_to_non_nullable
              as bool,
      editContext: editContext == freezed
          ? _value.editContext
          : editContext // ignore: cast_nullable_to_non_nullable
              as Option<EditPannelContext>,
    ));
  }
}

/// @nodoc
abstract class _$EditPannelStateCopyWith<$Res>
    implements $EditPannelStateCopyWith<$Res> {
  factory _$EditPannelStateCopyWith(
          _EditPannelState value, $Res Function(_EditPannelState) then) =
      __$EditPannelStateCopyWithImpl<$Res>;
  @override
  $Res call({bool isEditing, Option<EditPannelContext> editContext});
}

/// @nodoc
class __$EditPannelStateCopyWithImpl<$Res>
    extends _$EditPannelStateCopyWithImpl<$Res>
    implements _$EditPannelStateCopyWith<$Res> {
  __$EditPannelStateCopyWithImpl(
      _EditPannelState _value, $Res Function(_EditPannelState) _then)
      : super(_value, (v) => _then(v as _EditPannelState));

  @override
  _EditPannelState get _value => super._value as _EditPannelState;

  @override
  $Res call({
    Object? isEditing = freezed,
    Object? editContext = freezed,
  }) {
    return _then(_EditPannelState(
      isEditing: isEditing == freezed
          ? _value.isEditing
          : isEditing // ignore: cast_nullable_to_non_nullable
              as bool,
      editContext: editContext == freezed
          ? _value.editContext
          : editContext // ignore: cast_nullable_to_non_nullable
              as Option<EditPannelContext>,
    ));
  }
}

/// @nodoc

class _$_EditPannelState implements _EditPannelState {
  const _$_EditPannelState(
      {required this.isEditing, required this.editContext});

  @override
  final bool isEditing;
  @override
  final Option<EditPannelContext> editContext;

  @override
  String toString() {
    return 'EditPannelState(isEditing: $isEditing, editContext: $editContext)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _EditPannelState &&
            (identical(other.isEditing, isEditing) ||
                const DeepCollectionEquality()
                    .equals(other.isEditing, isEditing)) &&
            (identical(other.editContext, editContext) ||
                const DeepCollectionEquality()
                    .equals(other.editContext, editContext)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(isEditing) ^
      const DeepCollectionEquality().hash(editContext);

  @JsonKey(ignore: true)
  @override
  _$EditPannelStateCopyWith<_EditPannelState> get copyWith =>
      __$EditPannelStateCopyWithImpl<_EditPannelState>(this, _$identity);
}

abstract class _EditPannelState implements EditPannelState {
  const factory _EditPannelState(
      {required bool isEditing,
      required Option<EditPannelContext> editContext}) = _$_EditPannelState;

  @override
  bool get isEditing => throw _privateConstructorUsedError;
  @override
  Option<EditPannelContext> get editContext =>
      throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$EditPannelStateCopyWith<_EditPannelState> get copyWith =>
      throw _privateConstructorUsedError;
}
