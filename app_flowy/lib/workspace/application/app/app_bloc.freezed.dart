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

  ReceiveViews didReceiveViews(List<View> views) {
    return ReceiveViews(
      views,
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
    required TResult Function(List<View> views) didReceiveViews,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String name, String desc, ViewType viewType)? createView,
    TResult Function(List<View> views)? didReceiveViews,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(CreateView value) createView,
    required TResult Function(ReceiveViews value) didReceiveViews,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(CreateView value)? createView,
    TResult Function(ReceiveViews value)? didReceiveViews,
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
    required TResult Function(List<View> views) didReceiveViews,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String name, String desc, ViewType viewType)? createView,
    TResult Function(List<View> views)? didReceiveViews,
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
    required TResult Function(ReceiveViews value) didReceiveViews,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(CreateView value)? createView,
    TResult Function(ReceiveViews value)? didReceiveViews,
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
    required TResult Function(List<View> views) didReceiveViews,
  }) {
    return createView(name, desc, viewType);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String name, String desc, ViewType viewType)? createView,
    TResult Function(List<View> views)? didReceiveViews,
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
    required TResult Function(ReceiveViews value) didReceiveViews,
  }) {
    return createView(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(CreateView value)? createView,
    TResult Function(ReceiveViews value)? didReceiveViews,
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
    required TResult Function(List<View> views) didReceiveViews,
  }) {
    return didReceiveViews(views);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String name, String desc, ViewType viewType)? createView,
    TResult Function(List<View> views)? didReceiveViews,
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
    required TResult Function(ReceiveViews value) didReceiveViews,
  }) {
    return didReceiveViews(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(CreateView value)? createView,
    TResult Function(ReceiveViews value)? didReceiveViews,
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
class _$AppStateTearOff {
  const _$AppStateTearOff();

  _AppState call(
      {required bool isLoading,
      required List<View>? views,
      View? selectedView,
      required Either<Unit, WorkspaceError> successOrFailure}) {
    return _AppState(
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
      {bool isLoading,
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
    Object? isLoading = freezed,
    Object? views = freezed,
    Object? selectedView = freezed,
    Object? successOrFailure = freezed,
  }) {
    return _then(_value.copyWith(
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
      {bool isLoading,
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
    Object? isLoading = freezed,
    Object? views = freezed,
    Object? selectedView = freezed,
    Object? successOrFailure = freezed,
  }) {
    return _then(_AppState(
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
      {required this.isLoading,
      required this.views,
      this.selectedView,
      required this.successOrFailure});

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
    return 'AppState(isLoading: $isLoading, views: $views, selectedView: $selectedView, successOrFailure: $successOrFailure)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _AppState &&
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
      {required bool isLoading,
      required List<View>? views,
      View? selectedView,
      required Either<Unit, WorkspaceError> successOrFailure}) = _$_AppState;

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
