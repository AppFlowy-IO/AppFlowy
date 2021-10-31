// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'app_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
class _$AppEventTearOff {
  const _$AppEventTearOff();

  Initial initial() {
    return const Initial();
  }

  CreateView createView(String name, String desc, ViewType viewType) {
    return CreateView(
      name,
      desc,
      viewType,
    );
  }

  Delete delete() {
    return const Delete();
  }

  Rename rename(String newName) {
    return Rename(
      newName,
    );
  }

  ReceiveViews didReceiveViews(List<View> views) {
    return ReceiveViews(
      views,
    );
  }

  AppDidUpdate appDidUpdate(App app) {
    return AppDidUpdate(
      app,
    );
  }
}

/// @nodoc
const $AppEvent = _$AppEventTearOff();

/// @nodoc
mixin _$AppEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(String name, String desc, ViewType viewType)
        createView,
    required TResult Function() delete,
    required TResult Function(String newName) rename,
    required TResult Function(List<View> views) didReceiveViews,
    required TResult Function(App app) appDidUpdate,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String name, String desc, ViewType viewType)? createView,
    TResult Function()? delete,
    TResult Function(String newName)? rename,
    TResult Function(List<View> views)? didReceiveViews,
    TResult Function(App app)? appDidUpdate,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(CreateView value) createView,
    required TResult Function(Delete value) delete,
    required TResult Function(Rename value) rename,
    required TResult Function(ReceiveViews value) didReceiveViews,
    required TResult Function(AppDidUpdate value) appDidUpdate,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(CreateView value)? createView,
    TResult Function(Delete value)? delete,
    TResult Function(Rename value)? rename,
    TResult Function(ReceiveViews value)? didReceiveViews,
    TResult Function(AppDidUpdate value)? appDidUpdate,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppEventCopyWith<$Res> {
  factory $AppEventCopyWith(AppEvent value, $Res Function(AppEvent) then) =
      _$AppEventCopyWithImpl<$Res>;
}

/// @nodoc
class _$AppEventCopyWithImpl<$Res> implements $AppEventCopyWith<$Res> {
  _$AppEventCopyWithImpl(this._value, this._then);

  final AppEvent _value;
  // ignore: unused_field
  final $Res Function(AppEvent) _then;
}

/// @nodoc
abstract class $InitialCopyWith<$Res> {
  factory $InitialCopyWith(Initial value, $Res Function(Initial) then) =
      _$InitialCopyWithImpl<$Res>;
}

/// @nodoc
class _$InitialCopyWithImpl<$Res> extends _$AppEventCopyWithImpl<$Res>
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
    return 'AppEvent.initial()';
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
    required TResult Function(String name, String desc, ViewType viewType)
        createView,
    required TResult Function() delete,
    required TResult Function(String newName) rename,
    required TResult Function(List<View> views) didReceiveViews,
    required TResult Function(App app) appDidUpdate,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String name, String desc, ViewType viewType)? createView,
    TResult Function()? delete,
    TResult Function(String newName)? rename,
    TResult Function(List<View> views)? didReceiveViews,
    TResult Function(App app)? appDidUpdate,
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
    required TResult Function(CreateView value) createView,
    required TResult Function(Delete value) delete,
    required TResult Function(Rename value) rename,
    required TResult Function(ReceiveViews value) didReceiveViews,
    required TResult Function(AppDidUpdate value) appDidUpdate,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(CreateView value)? createView,
    TResult Function(Delete value)? delete,
    TResult Function(Rename value)? rename,
    TResult Function(ReceiveViews value)? didReceiveViews,
    TResult Function(AppDidUpdate value)? appDidUpdate,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class Initial implements AppEvent {
  const factory Initial() = _$Initial;
}

/// @nodoc
abstract class $CreateViewCopyWith<$Res> {
  factory $CreateViewCopyWith(
          CreateView value, $Res Function(CreateView) then) =
      _$CreateViewCopyWithImpl<$Res>;
  $Res call({String name, String desc, ViewType viewType});
}

/// @nodoc
class _$CreateViewCopyWithImpl<$Res> extends _$AppEventCopyWithImpl<$Res>
    implements $CreateViewCopyWith<$Res> {
  _$CreateViewCopyWithImpl(CreateView _value, $Res Function(CreateView) _then)
      : super(_value, (v) => _then(v as CreateView));

  @override
  CreateView get _value => super._value as CreateView;

  @override
  $Res call({
    Object? name = freezed,
    Object? desc = freezed,
    Object? viewType = freezed,
  }) {
    return _then(CreateView(
      name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      desc == freezed
          ? _value.desc
          : desc // ignore: cast_nullable_to_non_nullable
              as String,
      viewType == freezed
          ? _value.viewType
          : viewType // ignore: cast_nullable_to_non_nullable
              as ViewType,
    ));
  }
}

/// @nodoc

class _$CreateView implements CreateView {
  const _$CreateView(this.name, this.desc, this.viewType);

  @override
  final String name;
  @override
  final String desc;
  @override
  final ViewType viewType;

  @override
  String toString() {
    return 'AppEvent.createView(name: $name, desc: $desc, viewType: $viewType)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is CreateView &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.desc, desc) ||
                const DeepCollectionEquality().equals(other.desc, desc)) &&
            (identical(other.viewType, viewType) ||
                const DeepCollectionEquality()
                    .equals(other.viewType, viewType)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(desc) ^
      const DeepCollectionEquality().hash(viewType);

  @JsonKey(ignore: true)
  @override
  $CreateViewCopyWith<CreateView> get copyWith =>
      _$CreateViewCopyWithImpl<CreateView>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(String name, String desc, ViewType viewType)
        createView,
    required TResult Function() delete,
    required TResult Function(String newName) rename,
    required TResult Function(List<View> views) didReceiveViews,
    required TResult Function(App app) appDidUpdate,
  }) {
    return createView(name, desc, viewType);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String name, String desc, ViewType viewType)? createView,
    TResult Function()? delete,
    TResult Function(String newName)? rename,
    TResult Function(List<View> views)? didReceiveViews,
    TResult Function(App app)? appDidUpdate,
    required TResult orElse(),
  }) {
    if (createView != null) {
      return createView(name, desc, viewType);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(CreateView value) createView,
    required TResult Function(Delete value) delete,
    required TResult Function(Rename value) rename,
    required TResult Function(ReceiveViews value) didReceiveViews,
    required TResult Function(AppDidUpdate value) appDidUpdate,
  }) {
    return createView(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(CreateView value)? createView,
    TResult Function(Delete value)? delete,
    TResult Function(Rename value)? rename,
    TResult Function(ReceiveViews value)? didReceiveViews,
    TResult Function(AppDidUpdate value)? appDidUpdate,
    required TResult orElse(),
  }) {
    if (createView != null) {
      return createView(this);
    }
    return orElse();
  }
}

abstract class CreateView implements AppEvent {
  const factory CreateView(String name, String desc, ViewType viewType) =
      _$CreateView;

  String get name => throw _privateConstructorUsedError;
  String get desc => throw _privateConstructorUsedError;
  ViewType get viewType => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CreateViewCopyWith<CreateView> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeleteCopyWith<$Res> {
  factory $DeleteCopyWith(Delete value, $Res Function(Delete) then) =
      _$DeleteCopyWithImpl<$Res>;
}

/// @nodoc
class _$DeleteCopyWithImpl<$Res> extends _$AppEventCopyWithImpl<$Res>
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
    return 'AppEvent.delete()';
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
    required TResult Function(String name, String desc, ViewType viewType)
        createView,
    required TResult Function() delete,
    required TResult Function(String newName) rename,
    required TResult Function(List<View> views) didReceiveViews,
    required TResult Function(App app) appDidUpdate,
  }) {
    return delete();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String name, String desc, ViewType viewType)? createView,
    TResult Function()? delete,
    TResult Function(String newName)? rename,
    TResult Function(List<View> views)? didReceiveViews,
    TResult Function(App app)? appDidUpdate,
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
    required TResult Function(CreateView value) createView,
    required TResult Function(Delete value) delete,
    required TResult Function(Rename value) rename,
    required TResult Function(ReceiveViews value) didReceiveViews,
    required TResult Function(AppDidUpdate value) appDidUpdate,
  }) {
    return delete(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(CreateView value)? createView,
    TResult Function(Delete value)? delete,
    TResult Function(Rename value)? rename,
    TResult Function(ReceiveViews value)? didReceiveViews,
    TResult Function(AppDidUpdate value)? appDidUpdate,
    required TResult orElse(),
  }) {
    if (delete != null) {
      return delete(this);
    }
    return orElse();
  }
}

abstract class Delete implements AppEvent {
  const factory Delete() = _$Delete;
}

/// @nodoc
abstract class $RenameCopyWith<$Res> {
  factory $RenameCopyWith(Rename value, $Res Function(Rename) then) =
      _$RenameCopyWithImpl<$Res>;
  $Res call({String newName});
}

/// @nodoc
class _$RenameCopyWithImpl<$Res> extends _$AppEventCopyWithImpl<$Res>
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
    return 'AppEvent.rename(newName: $newName)';
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
    required TResult Function(String name, String desc, ViewType viewType)
        createView,
    required TResult Function() delete,
    required TResult Function(String newName) rename,
    required TResult Function(List<View> views) didReceiveViews,
    required TResult Function(App app) appDidUpdate,
  }) {
    return rename(newName);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String name, String desc, ViewType viewType)? createView,
    TResult Function()? delete,
    TResult Function(String newName)? rename,
    TResult Function(List<View> views)? didReceiveViews,
    TResult Function(App app)? appDidUpdate,
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
    required TResult Function(CreateView value) createView,
    required TResult Function(Delete value) delete,
    required TResult Function(Rename value) rename,
    required TResult Function(ReceiveViews value) didReceiveViews,
    required TResult Function(AppDidUpdate value) appDidUpdate,
  }) {
    return rename(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(CreateView value)? createView,
    TResult Function(Delete value)? delete,
    TResult Function(Rename value)? rename,
    TResult Function(ReceiveViews value)? didReceiveViews,
    TResult Function(AppDidUpdate value)? appDidUpdate,
    required TResult orElse(),
  }) {
    if (rename != null) {
      return rename(this);
    }
    return orElse();
  }
}

abstract class Rename implements AppEvent {
  const factory Rename(String newName) = _$Rename;

  String get newName => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RenameCopyWith<Rename> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReceiveViewsCopyWith<$Res> {
  factory $ReceiveViewsCopyWith(
          ReceiveViews value, $Res Function(ReceiveViews) then) =
      _$ReceiveViewsCopyWithImpl<$Res>;
  $Res call({List<View> views});
}

/// @nodoc
class _$ReceiveViewsCopyWithImpl<$Res> extends _$AppEventCopyWithImpl<$Res>
    implements $ReceiveViewsCopyWith<$Res> {
  _$ReceiveViewsCopyWithImpl(
      ReceiveViews _value, $Res Function(ReceiveViews) _then)
      : super(_value, (v) => _then(v as ReceiveViews));

  @override
  ReceiveViews get _value => super._value as ReceiveViews;

  @override
  $Res call({
    Object? views = freezed,
  }) {
    return _then(ReceiveViews(
      views == freezed
          ? _value.views
          : views // ignore: cast_nullable_to_non_nullable
              as List<View>,
    ));
  }
}

/// @nodoc

class _$ReceiveViews implements ReceiveViews {
  const _$ReceiveViews(this.views);

  @override
  final List<View> views;

  @override
  String toString() {
    return 'AppEvent.didReceiveViews(views: $views)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is ReceiveViews &&
            (identical(other.views, views) ||
                const DeepCollectionEquality().equals(other.views, views)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(views);

  @JsonKey(ignore: true)
  @override
  $ReceiveViewsCopyWith<ReceiveViews> get copyWith =>
      _$ReceiveViewsCopyWithImpl<ReceiveViews>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(String name, String desc, ViewType viewType)
        createView,
    required TResult Function() delete,
    required TResult Function(String newName) rename,
    required TResult Function(List<View> views) didReceiveViews,
    required TResult Function(App app) appDidUpdate,
  }) {
    return didReceiveViews(views);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String name, String desc, ViewType viewType)? createView,
    TResult Function()? delete,
    TResult Function(String newName)? rename,
    TResult Function(List<View> views)? didReceiveViews,
    TResult Function(App app)? appDidUpdate,
    required TResult orElse(),
  }) {
    if (didReceiveViews != null) {
      return didReceiveViews(views);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(CreateView value) createView,
    required TResult Function(Delete value) delete,
    required TResult Function(Rename value) rename,
    required TResult Function(ReceiveViews value) didReceiveViews,
    required TResult Function(AppDidUpdate value) appDidUpdate,
  }) {
    return didReceiveViews(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(CreateView value)? createView,
    TResult Function(Delete value)? delete,
    TResult Function(Rename value)? rename,
    TResult Function(ReceiveViews value)? didReceiveViews,
    TResult Function(AppDidUpdate value)? appDidUpdate,
    required TResult orElse(),
  }) {
    if (didReceiveViews != null) {
      return didReceiveViews(this);
    }
    return orElse();
  }
}

abstract class ReceiveViews implements AppEvent {
  const factory ReceiveViews(List<View> views) = _$ReceiveViews;

  List<View> get views => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ReceiveViewsCopyWith<ReceiveViews> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppDidUpdateCopyWith<$Res> {
  factory $AppDidUpdateCopyWith(
          AppDidUpdate value, $Res Function(AppDidUpdate) then) =
      _$AppDidUpdateCopyWithImpl<$Res>;
  $Res call({App app});
}

/// @nodoc
class _$AppDidUpdateCopyWithImpl<$Res> extends _$AppEventCopyWithImpl<$Res>
    implements $AppDidUpdateCopyWith<$Res> {
  _$AppDidUpdateCopyWithImpl(
      AppDidUpdate _value, $Res Function(AppDidUpdate) _then)
      : super(_value, (v) => _then(v as AppDidUpdate));

  @override
  AppDidUpdate get _value => super._value as AppDidUpdate;

  @override
  $Res call({
    Object? app = freezed,
  }) {
    return _then(AppDidUpdate(
      app == freezed
          ? _value.app
          : app // ignore: cast_nullable_to_non_nullable
              as App,
    ));
  }
}

/// @nodoc

class _$AppDidUpdate implements AppDidUpdate {
  const _$AppDidUpdate(this.app);

  @override
  final App app;

  @override
  String toString() {
    return 'AppEvent.appDidUpdate(app: $app)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is AppDidUpdate &&
            (identical(other.app, app) ||
                const DeepCollectionEquality().equals(other.app, app)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(app);

  @JsonKey(ignore: true)
  @override
  $AppDidUpdateCopyWith<AppDidUpdate> get copyWith =>
      _$AppDidUpdateCopyWithImpl<AppDidUpdate>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(String name, String desc, ViewType viewType)
        createView,
    required TResult Function() delete,
    required TResult Function(String newName) rename,
    required TResult Function(List<View> views) didReceiveViews,
    required TResult Function(App app) appDidUpdate,
  }) {
    return appDidUpdate(app);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String name, String desc, ViewType viewType)? createView,
    TResult Function()? delete,
    TResult Function(String newName)? rename,
    TResult Function(List<View> views)? didReceiveViews,
    TResult Function(App app)? appDidUpdate,
    required TResult orElse(),
  }) {
    if (appDidUpdate != null) {
      return appDidUpdate(app);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(CreateView value) createView,
    required TResult Function(Delete value) delete,
    required TResult Function(Rename value) rename,
    required TResult Function(ReceiveViews value) didReceiveViews,
    required TResult Function(AppDidUpdate value) appDidUpdate,
  }) {
    return appDidUpdate(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(CreateView value)? createView,
    TResult Function(Delete value)? delete,
    TResult Function(Rename value)? rename,
    TResult Function(ReceiveViews value)? didReceiveViews,
    TResult Function(AppDidUpdate value)? appDidUpdate,
    required TResult orElse(),
  }) {
    if (appDidUpdate != null) {
      return appDidUpdate(this);
    }
    return orElse();
  }
}

abstract class AppDidUpdate implements AppEvent {
  const factory AppDidUpdate(App app) = _$AppDidUpdate;

  App get app => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AppDidUpdateCopyWith<AppDidUpdate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
class _$AppStateTearOff {
  const _$AppStateTearOff();

  _AppState call(
      {required App app,
      required bool isLoading,
      required List<View>? views,
      View? selectedView,
      required Either<Unit, WorkspaceError> successOrFailure}) {
    return _AppState(
      app: app,
      isLoading: isLoading,
      views: views,
      selectedView: selectedView,
      successOrFailure: successOrFailure,
    );
  }
}

/// @nodoc
const $AppState = _$AppStateTearOff();

/// @nodoc
mixin _$AppState {
  App get app => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  List<View>? get views => throw _privateConstructorUsedError;
  View? get selectedView => throw _privateConstructorUsedError;
  Either<Unit, WorkspaceError> get successOrFailure =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $AppStateCopyWith<AppState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppStateCopyWith<$Res> {
  factory $AppStateCopyWith(AppState value, $Res Function(AppState) then) =
      _$AppStateCopyWithImpl<$Res>;
  $Res call(
      {App app,
      bool isLoading,
      List<View>? views,
      View? selectedView,
      Either<Unit, WorkspaceError> successOrFailure});
}

/// @nodoc
class _$AppStateCopyWithImpl<$Res> implements $AppStateCopyWith<$Res> {
  _$AppStateCopyWithImpl(this._value, this._then);

  final AppState _value;
  // ignore: unused_field
  final $Res Function(AppState) _then;

  @override
  $Res call({
    Object? app = freezed,
    Object? isLoading = freezed,
    Object? views = freezed,
    Object? selectedView = freezed,
    Object? successOrFailure = freezed,
  }) {
    return _then(_value.copyWith(
      app: app == freezed
          ? _value.app
          : app // ignore: cast_nullable_to_non_nullable
              as App,
      isLoading: isLoading == freezed
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      views: views == freezed
          ? _value.views
          : views // ignore: cast_nullable_to_non_nullable
              as List<View>?,
      selectedView: selectedView == freezed
          ? _value.selectedView
          : selectedView // ignore: cast_nullable_to_non_nullable
              as View?,
      successOrFailure: successOrFailure == freezed
          ? _value.successOrFailure
          : successOrFailure // ignore: cast_nullable_to_non_nullable
              as Either<Unit, WorkspaceError>,
    ));
  }
}

/// @nodoc
abstract class _$AppStateCopyWith<$Res> implements $AppStateCopyWith<$Res> {
  factory _$AppStateCopyWith(_AppState value, $Res Function(_AppState) then) =
      __$AppStateCopyWithImpl<$Res>;
  @override
  $Res call(
      {App app,
      bool isLoading,
      List<View>? views,
      View? selectedView,
      Either<Unit, WorkspaceError> successOrFailure});
}

/// @nodoc
class __$AppStateCopyWithImpl<$Res> extends _$AppStateCopyWithImpl<$Res>
    implements _$AppStateCopyWith<$Res> {
  __$AppStateCopyWithImpl(_AppState _value, $Res Function(_AppState) _then)
      : super(_value, (v) => _then(v as _AppState));

  @override
  _AppState get _value => super._value as _AppState;

  @override
  $Res call({
    Object? app = freezed,
    Object? isLoading = freezed,
    Object? views = freezed,
    Object? selectedView = freezed,
    Object? successOrFailure = freezed,
  }) {
    return _then(_AppState(
      app: app == freezed
          ? _value.app
          : app // ignore: cast_nullable_to_non_nullable
              as App,
      isLoading: isLoading == freezed
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      views: views == freezed
          ? _value.views
          : views // ignore: cast_nullable_to_non_nullable
              as List<View>?,
      selectedView: selectedView == freezed
          ? _value.selectedView
          : selectedView // ignore: cast_nullable_to_non_nullable
              as View?,
      successOrFailure: successOrFailure == freezed
          ? _value.successOrFailure
          : successOrFailure // ignore: cast_nullable_to_non_nullable
              as Either<Unit, WorkspaceError>,
    ));
  }
}

/// @nodoc

class _$_AppState implements _AppState {
  const _$_AppState(
      {required this.app,
      required this.isLoading,
      required this.views,
      this.selectedView,
      required this.successOrFailure});

  @override
  final App app;
  @override
  final bool isLoading;
  @override
  final List<View>? views;
  @override
  final View? selectedView;
  @override
  final Either<Unit, WorkspaceError> successOrFailure;

  @override
  String toString() {
    return 'AppState(app: $app, isLoading: $isLoading, views: $views, selectedView: $selectedView, successOrFailure: $successOrFailure)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _AppState &&
            (identical(other.app, app) ||
                const DeepCollectionEquality().equals(other.app, app)) &&
            (identical(other.isLoading, isLoading) ||
                const DeepCollectionEquality()
                    .equals(other.isLoading, isLoading)) &&
            (identical(other.views, views) ||
                const DeepCollectionEquality().equals(other.views, views)) &&
            (identical(other.selectedView, selectedView) ||
                const DeepCollectionEquality()
                    .equals(other.selectedView, selectedView)) &&
            (identical(other.successOrFailure, successOrFailure) ||
                const DeepCollectionEquality()
                    .equals(other.successOrFailure, successOrFailure)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(app) ^
      const DeepCollectionEquality().hash(isLoading) ^
      const DeepCollectionEquality().hash(views) ^
      const DeepCollectionEquality().hash(selectedView) ^
      const DeepCollectionEquality().hash(successOrFailure);

  @JsonKey(ignore: true)
  @override
  _$AppStateCopyWith<_AppState> get copyWith =>
      __$AppStateCopyWithImpl<_AppState>(this, _$identity);
}

abstract class _AppState implements AppState {
  const factory _AppState(
      {required App app,
      required bool isLoading,
      required List<View>? views,
      View? selectedView,
      required Either<Unit, WorkspaceError> successOrFailure}) = _$_AppState;

  @override
  App get app => throw _privateConstructorUsedError;
  @override
  bool get isLoading => throw _privateConstructorUsedError;
  @override
  List<View>? get views => throw _privateConstructorUsedError;
  @override
  View? get selectedView => throw _privateConstructorUsedError;
  @override
  Either<Unit, WorkspaceError> get successOrFailure =>
      throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$AppStateCopyWith<_AppState> get copyWith =>
      throw _privateConstructorUsedError;
}
