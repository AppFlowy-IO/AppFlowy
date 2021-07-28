// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'home_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
class _$HomeEventTearOff {
  const _$HomeEventTearOff();

  _ShowLoading showLoading(bool isLoading) {
    return _ShowLoading(
      isLoading,
    );
  }

  _ForceCollapse forceCollapse(bool forceCollapse) {
    return _ForceCollapse(
      forceCollapse,
    );
  }

  _ShowEditPannel setEditPannel(EditPannelContext editContext) {
    return _ShowEditPannel(
      editContext,
    );
  }

  _DismissEditPannel dismissEditPannel() {
    return const _DismissEditPannel();
  }
}

/// @nodoc
const $HomeEvent = _$HomeEventTearOff();

/// @nodoc
mixin _$HomeEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool isLoading) showLoading,
    required TResult Function(bool forceCollapse) forceCollapse,
    required TResult Function(EditPannelContext editContext) setEditPannel,
    required TResult Function() dismissEditPannel,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool isLoading)? showLoading,
    TResult Function(bool forceCollapse)? forceCollapse,
    TResult Function(EditPannelContext editContext)? setEditPannel,
    TResult Function()? dismissEditPannel,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ShowLoading value) showLoading,
    required TResult Function(_ForceCollapse value) forceCollapse,
    required TResult Function(_ShowEditPannel value) setEditPannel,
    required TResult Function(_DismissEditPannel value) dismissEditPannel,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ShowLoading value)? showLoading,
    TResult Function(_ForceCollapse value)? forceCollapse,
    TResult Function(_ShowEditPannel value)? setEditPannel,
    TResult Function(_DismissEditPannel value)? dismissEditPannel,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HomeEventCopyWith<$Res> {
  factory $HomeEventCopyWith(HomeEvent value, $Res Function(HomeEvent) then) =
      _$HomeEventCopyWithImpl<$Res>;
}

/// @nodoc
class _$HomeEventCopyWithImpl<$Res> implements $HomeEventCopyWith<$Res> {
  _$HomeEventCopyWithImpl(this._value, this._then);

  final HomeEvent _value;
  // ignore: unused_field
  final $Res Function(HomeEvent) _then;
}

/// @nodoc
abstract class _$ShowLoadingCopyWith<$Res> {
  factory _$ShowLoadingCopyWith(
          _ShowLoading value, $Res Function(_ShowLoading) then) =
      __$ShowLoadingCopyWithImpl<$Res>;
  $Res call({bool isLoading});
}

/// @nodoc
class __$ShowLoadingCopyWithImpl<$Res> extends _$HomeEventCopyWithImpl<$Res>
    implements _$ShowLoadingCopyWith<$Res> {
  __$ShowLoadingCopyWithImpl(
      _ShowLoading _value, $Res Function(_ShowLoading) _then)
      : super(_value, (v) => _then(v as _ShowLoading));

  @override
  _ShowLoading get _value => super._value as _ShowLoading;

  @override
  $Res call({
    Object? isLoading = freezed,
  }) {
    return _then(_ShowLoading(
      isLoading == freezed
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$_ShowLoading implements _ShowLoading {
  const _$_ShowLoading(this.isLoading);

  @override
  final bool isLoading;

  @override
  String toString() {
    return 'HomeEvent.showLoading(isLoading: $isLoading)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _ShowLoading &&
            (identical(other.isLoading, isLoading) ||
                const DeepCollectionEquality()
                    .equals(other.isLoading, isLoading)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(isLoading);

  @JsonKey(ignore: true)
  @override
  _$ShowLoadingCopyWith<_ShowLoading> get copyWith =>
      __$ShowLoadingCopyWithImpl<_ShowLoading>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool isLoading) showLoading,
    required TResult Function(bool forceCollapse) forceCollapse,
    required TResult Function(EditPannelContext editContext) setEditPannel,
    required TResult Function() dismissEditPannel,
  }) {
    return showLoading(isLoading);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool isLoading)? showLoading,
    TResult Function(bool forceCollapse)? forceCollapse,
    TResult Function(EditPannelContext editContext)? setEditPannel,
    TResult Function()? dismissEditPannel,
    required TResult orElse(),
  }) {
    if (showLoading != null) {
      return showLoading(isLoading);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ShowLoading value) showLoading,
    required TResult Function(_ForceCollapse value) forceCollapse,
    required TResult Function(_ShowEditPannel value) setEditPannel,
    required TResult Function(_DismissEditPannel value) dismissEditPannel,
  }) {
    return showLoading(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ShowLoading value)? showLoading,
    TResult Function(_ForceCollapse value)? forceCollapse,
    TResult Function(_ShowEditPannel value)? setEditPannel,
    TResult Function(_DismissEditPannel value)? dismissEditPannel,
    required TResult orElse(),
  }) {
    if (showLoading != null) {
      return showLoading(this);
    }
    return orElse();
  }
}

abstract class _ShowLoading implements HomeEvent {
  const factory _ShowLoading(bool isLoading) = _$_ShowLoading;

  bool get isLoading => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  _$ShowLoadingCopyWith<_ShowLoading> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$ForceCollapseCopyWith<$Res> {
  factory _$ForceCollapseCopyWith(
          _ForceCollapse value, $Res Function(_ForceCollapse) then) =
      __$ForceCollapseCopyWithImpl<$Res>;
  $Res call({bool forceCollapse});
}

/// @nodoc
class __$ForceCollapseCopyWithImpl<$Res> extends _$HomeEventCopyWithImpl<$Res>
    implements _$ForceCollapseCopyWith<$Res> {
  __$ForceCollapseCopyWithImpl(
      _ForceCollapse _value, $Res Function(_ForceCollapse) _then)
      : super(_value, (v) => _then(v as _ForceCollapse));

  @override
  _ForceCollapse get _value => super._value as _ForceCollapse;

  @override
  $Res call({
    Object? forceCollapse = freezed,
  }) {
    return _then(_ForceCollapse(
      forceCollapse == freezed
          ? _value.forceCollapse
          : forceCollapse // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$_ForceCollapse implements _ForceCollapse {
  const _$_ForceCollapse(this.forceCollapse);

  @override
  final bool forceCollapse;

  @override
  String toString() {
    return 'HomeEvent.forceCollapse(forceCollapse: $forceCollapse)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _ForceCollapse &&
            (identical(other.forceCollapse, forceCollapse) ||
                const DeepCollectionEquality()
                    .equals(other.forceCollapse, forceCollapse)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(forceCollapse);

  @JsonKey(ignore: true)
  @override
  _$ForceCollapseCopyWith<_ForceCollapse> get copyWith =>
      __$ForceCollapseCopyWithImpl<_ForceCollapse>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool isLoading) showLoading,
    required TResult Function(bool forceCollapse) forceCollapse,
    required TResult Function(EditPannelContext editContext) setEditPannel,
    required TResult Function() dismissEditPannel,
  }) {
    return forceCollapse(this.forceCollapse);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool isLoading)? showLoading,
    TResult Function(bool forceCollapse)? forceCollapse,
    TResult Function(EditPannelContext editContext)? setEditPannel,
    TResult Function()? dismissEditPannel,
    required TResult orElse(),
  }) {
    if (forceCollapse != null) {
      return forceCollapse(this.forceCollapse);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ShowLoading value) showLoading,
    required TResult Function(_ForceCollapse value) forceCollapse,
    required TResult Function(_ShowEditPannel value) setEditPannel,
    required TResult Function(_DismissEditPannel value) dismissEditPannel,
  }) {
    return forceCollapse(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ShowLoading value)? showLoading,
    TResult Function(_ForceCollapse value)? forceCollapse,
    TResult Function(_ShowEditPannel value)? setEditPannel,
    TResult Function(_DismissEditPannel value)? dismissEditPannel,
    required TResult orElse(),
  }) {
    if (forceCollapse != null) {
      return forceCollapse(this);
    }
    return orElse();
  }
}

abstract class _ForceCollapse implements HomeEvent {
  const factory _ForceCollapse(bool forceCollapse) = _$_ForceCollapse;

  bool get forceCollapse => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  _$ForceCollapseCopyWith<_ForceCollapse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$ShowEditPannelCopyWith<$Res> {
  factory _$ShowEditPannelCopyWith(
          _ShowEditPannel value, $Res Function(_ShowEditPannel) then) =
      __$ShowEditPannelCopyWithImpl<$Res>;
  $Res call({EditPannelContext editContext});
}

/// @nodoc
class __$ShowEditPannelCopyWithImpl<$Res> extends _$HomeEventCopyWithImpl<$Res>
    implements _$ShowEditPannelCopyWith<$Res> {
  __$ShowEditPannelCopyWithImpl(
      _ShowEditPannel _value, $Res Function(_ShowEditPannel) _then)
      : super(_value, (v) => _then(v as _ShowEditPannel));

  @override
  _ShowEditPannel get _value => super._value as _ShowEditPannel;

  @override
  $Res call({
    Object? editContext = freezed,
  }) {
    return _then(_ShowEditPannel(
      editContext == freezed
          ? _value.editContext
          : editContext // ignore: cast_nullable_to_non_nullable
              as EditPannelContext,
    ));
  }
}

/// @nodoc

class _$_ShowEditPannel implements _ShowEditPannel {
  const _$_ShowEditPannel(this.editContext);

  @override
  final EditPannelContext editContext;

  @override
  String toString() {
    return 'HomeEvent.setEditPannel(editContext: $editContext)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _ShowEditPannel &&
            (identical(other.editContext, editContext) ||
                const DeepCollectionEquality()
                    .equals(other.editContext, editContext)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(editContext);

  @JsonKey(ignore: true)
  @override
  _$ShowEditPannelCopyWith<_ShowEditPannel> get copyWith =>
      __$ShowEditPannelCopyWithImpl<_ShowEditPannel>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool isLoading) showLoading,
    required TResult Function(bool forceCollapse) forceCollapse,
    required TResult Function(EditPannelContext editContext) setEditPannel,
    required TResult Function() dismissEditPannel,
  }) {
    return setEditPannel(editContext);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool isLoading)? showLoading,
    TResult Function(bool forceCollapse)? forceCollapse,
    TResult Function(EditPannelContext editContext)? setEditPannel,
    TResult Function()? dismissEditPannel,
    required TResult orElse(),
  }) {
    if (setEditPannel != null) {
      return setEditPannel(editContext);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ShowLoading value) showLoading,
    required TResult Function(_ForceCollapse value) forceCollapse,
    required TResult Function(_ShowEditPannel value) setEditPannel,
    required TResult Function(_DismissEditPannel value) dismissEditPannel,
  }) {
    return setEditPannel(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ShowLoading value)? showLoading,
    TResult Function(_ForceCollapse value)? forceCollapse,
    TResult Function(_ShowEditPannel value)? setEditPannel,
    TResult Function(_DismissEditPannel value)? dismissEditPannel,
    required TResult orElse(),
  }) {
    if (setEditPannel != null) {
      return setEditPannel(this);
    }
    return orElse();
  }
}

abstract class _ShowEditPannel implements HomeEvent {
  const factory _ShowEditPannel(EditPannelContext editContext) =
      _$_ShowEditPannel;

  EditPannelContext get editContext => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  _$ShowEditPannelCopyWith<_ShowEditPannel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$DismissEditPannelCopyWith<$Res> {
  factory _$DismissEditPannelCopyWith(
          _DismissEditPannel value, $Res Function(_DismissEditPannel) then) =
      __$DismissEditPannelCopyWithImpl<$Res>;
}

/// @nodoc
class __$DismissEditPannelCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res>
    implements _$DismissEditPannelCopyWith<$Res> {
  __$DismissEditPannelCopyWithImpl(
      _DismissEditPannel _value, $Res Function(_DismissEditPannel) _then)
      : super(_value, (v) => _then(v as _DismissEditPannel));

  @override
  _DismissEditPannel get _value => super._value as _DismissEditPannel;
}

/// @nodoc

class _$_DismissEditPannel implements _DismissEditPannel {
  const _$_DismissEditPannel();

  @override
  String toString() {
    return 'HomeEvent.dismissEditPannel()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) || (other is _DismissEditPannel);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool isLoading) showLoading,
    required TResult Function(bool forceCollapse) forceCollapse,
    required TResult Function(EditPannelContext editContext) setEditPannel,
    required TResult Function() dismissEditPannel,
  }) {
    return dismissEditPannel();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool isLoading)? showLoading,
    TResult Function(bool forceCollapse)? forceCollapse,
    TResult Function(EditPannelContext editContext)? setEditPannel,
    TResult Function()? dismissEditPannel,
    required TResult orElse(),
  }) {
    if (dismissEditPannel != null) {
      return dismissEditPannel();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ShowLoading value) showLoading,
    required TResult Function(_ForceCollapse value) forceCollapse,
    required TResult Function(_ShowEditPannel value) setEditPannel,
    required TResult Function(_DismissEditPannel value) dismissEditPannel,
  }) {
    return dismissEditPannel(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ShowLoading value)? showLoading,
    TResult Function(_ForceCollapse value)? forceCollapse,
    TResult Function(_ShowEditPannel value)? setEditPannel,
    TResult Function(_DismissEditPannel value)? dismissEditPannel,
    required TResult orElse(),
  }) {
    if (dismissEditPannel != null) {
      return dismissEditPannel(this);
    }
    return orElse();
  }
}

abstract class _DismissEditPannel implements HomeEvent {
  const factory _DismissEditPannel() = _$_DismissEditPannel;
}

/// @nodoc
class _$HomeStateTearOff {
  const _$HomeStateTearOff();

  _HomeState call(
      {required bool isLoading,
      required bool forceCollapse,
      required Option<EditPannelContext> editContext}) {
    return _HomeState(
      isLoading: isLoading,
      forceCollapse: forceCollapse,
      editContext: editContext,
    );
  }
}

/// @nodoc
const $HomeState = _$HomeStateTearOff();

/// @nodoc
mixin _$HomeState {
  bool get isLoading => throw _privateConstructorUsedError;
  bool get forceCollapse => throw _privateConstructorUsedError;
  Option<EditPannelContext> get editContext =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $HomeStateCopyWith<HomeState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HomeStateCopyWith<$Res> {
  factory $HomeStateCopyWith(HomeState value, $Res Function(HomeState) then) =
      _$HomeStateCopyWithImpl<$Res>;
  $Res call(
      {bool isLoading,
      bool forceCollapse,
      Option<EditPannelContext> editContext});
}

/// @nodoc
class _$HomeStateCopyWithImpl<$Res> implements $HomeStateCopyWith<$Res> {
  _$HomeStateCopyWithImpl(this._value, this._then);

  final HomeState _value;
  // ignore: unused_field
  final $Res Function(HomeState) _then;

  @override
  $Res call({
    Object? isLoading = freezed,
    Object? forceCollapse = freezed,
    Object? editContext = freezed,
  }) {
    return _then(_value.copyWith(
      isLoading: isLoading == freezed
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      forceCollapse: forceCollapse == freezed
          ? _value.forceCollapse
          : forceCollapse // ignore: cast_nullable_to_non_nullable
              as bool,
      editContext: editContext == freezed
          ? _value.editContext
          : editContext // ignore: cast_nullable_to_non_nullable
              as Option<EditPannelContext>,
    ));
  }
}

/// @nodoc
abstract class _$HomeStateCopyWith<$Res> implements $HomeStateCopyWith<$Res> {
  factory _$HomeStateCopyWith(
          _HomeState value, $Res Function(_HomeState) then) =
      __$HomeStateCopyWithImpl<$Res>;
  @override
  $Res call(
      {bool isLoading,
      bool forceCollapse,
      Option<EditPannelContext> editContext});
}

/// @nodoc
class __$HomeStateCopyWithImpl<$Res> extends _$HomeStateCopyWithImpl<$Res>
    implements _$HomeStateCopyWith<$Res> {
  __$HomeStateCopyWithImpl(_HomeState _value, $Res Function(_HomeState) _then)
      : super(_value, (v) => _then(v as _HomeState));

  @override
  _HomeState get _value => super._value as _HomeState;

  @override
  $Res call({
    Object? isLoading = freezed,
    Object? forceCollapse = freezed,
    Object? editContext = freezed,
  }) {
    return _then(_HomeState(
      isLoading: isLoading == freezed
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      forceCollapse: forceCollapse == freezed
          ? _value.forceCollapse
          : forceCollapse // ignore: cast_nullable_to_non_nullable
              as bool,
      editContext: editContext == freezed
          ? _value.editContext
          : editContext // ignore: cast_nullable_to_non_nullable
              as Option<EditPannelContext>,
    ));
  }
}

/// @nodoc

class _$_HomeState implements _HomeState {
  const _$_HomeState(
      {required this.isLoading,
      required this.forceCollapse,
      required this.editContext});

  @override
  final bool isLoading;
  @override
  final bool forceCollapse;
  @override
  final Option<EditPannelContext> editContext;

  @override
  String toString() {
    return 'HomeState(isLoading: $isLoading, forceCollapse: $forceCollapse, editContext: $editContext)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _HomeState &&
            (identical(other.isLoading, isLoading) ||
                const DeepCollectionEquality()
                    .equals(other.isLoading, isLoading)) &&
            (identical(other.forceCollapse, forceCollapse) ||
                const DeepCollectionEquality()
                    .equals(other.forceCollapse, forceCollapse)) &&
            (identical(other.editContext, editContext) ||
                const DeepCollectionEquality()
                    .equals(other.editContext, editContext)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(isLoading) ^
      const DeepCollectionEquality().hash(forceCollapse) ^
      const DeepCollectionEquality().hash(editContext);

  @JsonKey(ignore: true)
  @override
  _$HomeStateCopyWith<_HomeState> get copyWith =>
      __$HomeStateCopyWithImpl<_HomeState>(this, _$identity);
}

abstract class _HomeState implements HomeState {
  const factory _HomeState(
      {required bool isLoading,
      required bool forceCollapse,
      required Option<EditPannelContext> editContext}) = _$_HomeState;

  @override
  bool get isLoading => throw _privateConstructorUsedError;
  @override
  bool get forceCollapse => throw _privateConstructorUsedError;
  @override
  Option<EditPannelContext> get editContext =>
      throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$HomeStateCopyWith<_HomeState> get copyWith =>
      throw _privateConstructorUsedError;
}
