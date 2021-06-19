// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides

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

  _ShowMenu showMenu(bool isShow) {
    return _ShowMenu(
      isShow,
    );
  }

  SetCurrentPage setPage(PageContext context) {
    return SetCurrentPage(
      context,
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
    required TResult Function(bool isShow) showMenu,
    required TResult Function(PageContext context) setPage,
    required TResult Function(EditPannelContext editContext) setEditPannel,
    required TResult Function() dismissEditPannel,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool isLoading)? showLoading,
    TResult Function(bool isShow)? showMenu,
    TResult Function(PageContext context)? setPage,
    TResult Function(EditPannelContext editContext)? setEditPannel,
    TResult Function()? dismissEditPannel,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ShowLoading value) showLoading,
    required TResult Function(_ShowMenu value) showMenu,
    required TResult Function(SetCurrentPage value) setPage,
    required TResult Function(_ShowEditPannel value) setEditPannel,
    required TResult Function(_DismissEditPannel value) dismissEditPannel,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ShowLoading value)? showLoading,
    TResult Function(_ShowMenu value)? showMenu,
    TResult Function(SetCurrentPage value)? setPage,
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
    required TResult Function(bool isShow) showMenu,
    required TResult Function(PageContext context) setPage,
    required TResult Function(EditPannelContext editContext) setEditPannel,
    required TResult Function() dismissEditPannel,
  }) {
    return showLoading(isLoading);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool isLoading)? showLoading,
    TResult Function(bool isShow)? showMenu,
    TResult Function(PageContext context)? setPage,
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
    required TResult Function(_ShowMenu value) showMenu,
    required TResult Function(SetCurrentPage value) setPage,
    required TResult Function(_ShowEditPannel value) setEditPannel,
    required TResult Function(_DismissEditPannel value) dismissEditPannel,
  }) {
    return showLoading(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ShowLoading value)? showLoading,
    TResult Function(_ShowMenu value)? showMenu,
    TResult Function(SetCurrentPage value)? setPage,
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
abstract class _$ShowMenuCopyWith<$Res> {
  factory _$ShowMenuCopyWith(_ShowMenu value, $Res Function(_ShowMenu) then) =
      __$ShowMenuCopyWithImpl<$Res>;
  $Res call({bool isShow});
}

/// @nodoc
class __$ShowMenuCopyWithImpl<$Res> extends _$HomeEventCopyWithImpl<$Res>
    implements _$ShowMenuCopyWith<$Res> {
  __$ShowMenuCopyWithImpl(_ShowMenu _value, $Res Function(_ShowMenu) _then)
      : super(_value, (v) => _then(v as _ShowMenu));

  @override
  _ShowMenu get _value => super._value as _ShowMenu;

  @override
  $Res call({
    Object? isShow = freezed,
  }) {
    return _then(_ShowMenu(
      isShow == freezed
          ? _value.isShow
          : isShow // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$_ShowMenu implements _ShowMenu {
  const _$_ShowMenu(this.isShow);

  @override
  final bool isShow;

  @override
  String toString() {
    return 'HomeEvent.showMenu(isShow: $isShow)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _ShowMenu &&
            (identical(other.isShow, isShow) ||
                const DeepCollectionEquality().equals(other.isShow, isShow)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(isShow);

  @JsonKey(ignore: true)
  @override
  _$ShowMenuCopyWith<_ShowMenu> get copyWith =>
      __$ShowMenuCopyWithImpl<_ShowMenu>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool isLoading) showLoading,
    required TResult Function(bool isShow) showMenu,
    required TResult Function(PageContext context) setPage,
    required TResult Function(EditPannelContext editContext) setEditPannel,
    required TResult Function() dismissEditPannel,
  }) {
    return showMenu(isShow);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool isLoading)? showLoading,
    TResult Function(bool isShow)? showMenu,
    TResult Function(PageContext context)? setPage,
    TResult Function(EditPannelContext editContext)? setEditPannel,
    TResult Function()? dismissEditPannel,
    required TResult orElse(),
  }) {
    if (showMenu != null) {
      return showMenu(isShow);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ShowLoading value) showLoading,
    required TResult Function(_ShowMenu value) showMenu,
    required TResult Function(SetCurrentPage value) setPage,
    required TResult Function(_ShowEditPannel value) setEditPannel,
    required TResult Function(_DismissEditPannel value) dismissEditPannel,
  }) {
    return showMenu(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ShowLoading value)? showLoading,
    TResult Function(_ShowMenu value)? showMenu,
    TResult Function(SetCurrentPage value)? setPage,
    TResult Function(_ShowEditPannel value)? setEditPannel,
    TResult Function(_DismissEditPannel value)? dismissEditPannel,
    required TResult orElse(),
  }) {
    if (showMenu != null) {
      return showMenu(this);
    }
    return orElse();
  }
}

abstract class _ShowMenu implements HomeEvent {
  const factory _ShowMenu(bool isShow) = _$_ShowMenu;

  bool get isShow => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  _$ShowMenuCopyWith<_ShowMenu> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SetCurrentPageCopyWith<$Res> {
  factory $SetCurrentPageCopyWith(
          SetCurrentPage value, $Res Function(SetCurrentPage) then) =
      _$SetCurrentPageCopyWithImpl<$Res>;
  $Res call({PageContext context});
}

/// @nodoc
class _$SetCurrentPageCopyWithImpl<$Res> extends _$HomeEventCopyWithImpl<$Res>
    implements $SetCurrentPageCopyWith<$Res> {
  _$SetCurrentPageCopyWithImpl(
      SetCurrentPage _value, $Res Function(SetCurrentPage) _then)
      : super(_value, (v) => _then(v as SetCurrentPage));

  @override
  SetCurrentPage get _value => super._value as SetCurrentPage;

  @override
  $Res call({
    Object? context = freezed,
  }) {
    return _then(SetCurrentPage(
      context == freezed
          ? _value.context
          : context // ignore: cast_nullable_to_non_nullable
              as PageContext,
    ));
  }
}

/// @nodoc

class _$SetCurrentPage implements SetCurrentPage {
  const _$SetCurrentPage(this.context);

  @override
  final PageContext context;

  @override
  String toString() {
    return 'HomeEvent.setPage(context: $context)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is SetCurrentPage &&
            (identical(other.context, context) ||
                const DeepCollectionEquality().equals(other.context, context)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(context);

  @JsonKey(ignore: true)
  @override
  $SetCurrentPageCopyWith<SetCurrentPage> get copyWith =>
      _$SetCurrentPageCopyWithImpl<SetCurrentPage>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool isLoading) showLoading,
    required TResult Function(bool isShow) showMenu,
    required TResult Function(PageContext context) setPage,
    required TResult Function(EditPannelContext editContext) setEditPannel,
    required TResult Function() dismissEditPannel,
  }) {
    return setPage(context);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool isLoading)? showLoading,
    TResult Function(bool isShow)? showMenu,
    TResult Function(PageContext context)? setPage,
    TResult Function(EditPannelContext editContext)? setEditPannel,
    TResult Function()? dismissEditPannel,
    required TResult orElse(),
  }) {
    if (setPage != null) {
      return setPage(context);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ShowLoading value) showLoading,
    required TResult Function(_ShowMenu value) showMenu,
    required TResult Function(SetCurrentPage value) setPage,
    required TResult Function(_ShowEditPannel value) setEditPannel,
    required TResult Function(_DismissEditPannel value) dismissEditPannel,
  }) {
    return setPage(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ShowLoading value)? showLoading,
    TResult Function(_ShowMenu value)? showMenu,
    TResult Function(SetCurrentPage value)? setPage,
    TResult Function(_ShowEditPannel value)? setEditPannel,
    TResult Function(_DismissEditPannel value)? dismissEditPannel,
    required TResult orElse(),
  }) {
    if (setPage != null) {
      return setPage(this);
    }
    return orElse();
  }
}

abstract class SetCurrentPage implements HomeEvent {
  const factory SetCurrentPage(PageContext context) = _$SetCurrentPage;

  PageContext get context => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SetCurrentPageCopyWith<SetCurrentPage> get copyWith =>
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
    required TResult Function(bool isShow) showMenu,
    required TResult Function(PageContext context) setPage,
    required TResult Function(EditPannelContext editContext) setEditPannel,
    required TResult Function() dismissEditPannel,
  }) {
    return setEditPannel(editContext);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool isLoading)? showLoading,
    TResult Function(bool isShow)? showMenu,
    TResult Function(PageContext context)? setPage,
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
    required TResult Function(_ShowMenu value) showMenu,
    required TResult Function(SetCurrentPage value) setPage,
    required TResult Function(_ShowEditPannel value) setEditPannel,
    required TResult Function(_DismissEditPannel value) dismissEditPannel,
  }) {
    return setEditPannel(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ShowLoading value)? showLoading,
    TResult Function(_ShowMenu value)? showMenu,
    TResult Function(SetCurrentPage value)? setPage,
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
    required TResult Function(bool isShow) showMenu,
    required TResult Function(PageContext context) setPage,
    required TResult Function(EditPannelContext editContext) setEditPannel,
    required TResult Function() dismissEditPannel,
  }) {
    return dismissEditPannel();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool isLoading)? showLoading,
    TResult Function(bool isShow)? showMenu,
    TResult Function(PageContext context)? setPage,
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
    required TResult Function(_ShowMenu value) showMenu,
    required TResult Function(SetCurrentPage value) setPage,
    required TResult Function(_ShowEditPannel value) setEditPannel,
    required TResult Function(_DismissEditPannel value) dismissEditPannel,
  }) {
    return dismissEditPannel(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ShowLoading value)? showLoading,
    TResult Function(_ShowMenu value)? showMenu,
    TResult Function(SetCurrentPage value)? setPage,
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
      required bool showMenu,
      required PageContext pageContext,
      required Option<EditPannelContext> editContext}) {
    return _HomeState(
      isLoading: isLoading,
      showMenu: showMenu,
      pageContext: pageContext,
      editContext: editContext,
    );
  }
}

/// @nodoc
const $HomeState = _$HomeStateTearOff();

/// @nodoc
mixin _$HomeState {
  bool get isLoading => throw _privateConstructorUsedError;
  bool get showMenu => throw _privateConstructorUsedError;
  PageContext get pageContext => throw _privateConstructorUsedError;
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
      bool showMenu,
      PageContext pageContext,
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
    Object? showMenu = freezed,
    Object? pageContext = freezed,
    Object? editContext = freezed,
  }) {
    return _then(_value.copyWith(
      isLoading: isLoading == freezed
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      showMenu: showMenu == freezed
          ? _value.showMenu
          : showMenu // ignore: cast_nullable_to_non_nullable
              as bool,
      pageContext: pageContext == freezed
          ? _value.pageContext
          : pageContext // ignore: cast_nullable_to_non_nullable
              as PageContext,
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
      bool showMenu,
      PageContext pageContext,
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
    Object? showMenu = freezed,
    Object? pageContext = freezed,
    Object? editContext = freezed,
  }) {
    return _then(_HomeState(
      isLoading: isLoading == freezed
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      showMenu: showMenu == freezed
          ? _value.showMenu
          : showMenu // ignore: cast_nullable_to_non_nullable
              as bool,
      pageContext: pageContext == freezed
          ? _value.pageContext
          : pageContext // ignore: cast_nullable_to_non_nullable
              as PageContext,
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
      required this.showMenu,
      required this.pageContext,
      required this.editContext});

  @override
  final bool isLoading;
  @override
  final bool showMenu;
  @override
  final PageContext pageContext;
  @override
  final Option<EditPannelContext> editContext;

  @override
  String toString() {
    return 'HomeState(isLoading: $isLoading, showMenu: $showMenu, pageContext: $pageContext, editContext: $editContext)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _HomeState &&
            (identical(other.isLoading, isLoading) ||
                const DeepCollectionEquality()
                    .equals(other.isLoading, isLoading)) &&
            (identical(other.showMenu, showMenu) ||
                const DeepCollectionEquality()
                    .equals(other.showMenu, showMenu)) &&
            (identical(other.pageContext, pageContext) ||
                const DeepCollectionEquality()
                    .equals(other.pageContext, pageContext)) &&
            (identical(other.editContext, editContext) ||
                const DeepCollectionEquality()
                    .equals(other.editContext, editContext)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(isLoading) ^
      const DeepCollectionEquality().hash(showMenu) ^
      const DeepCollectionEquality().hash(pageContext) ^
      const DeepCollectionEquality().hash(editContext);

  @JsonKey(ignore: true)
  @override
  _$HomeStateCopyWith<_HomeState> get copyWith =>
      __$HomeStateCopyWithImpl<_HomeState>(this, _$identity);
}

abstract class _HomeState implements HomeState {
  const factory _HomeState(
      {required bool isLoading,
      required bool showMenu,
      required PageContext pageContext,
      required Option<EditPannelContext> editContext}) = _$_HomeState;

  @override
  bool get isLoading => throw _privateConstructorUsedError;
  @override
  bool get showMenu => throw _privateConstructorUsedError;
  @override
  PageContext get pageContext => throw _privateConstructorUsedError;
  @override
  Option<EditPannelContext> get editContext =>
      throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$HomeStateCopyWith<_HomeState> get copyWith =>
      throw _privateConstructorUsedError;
}
