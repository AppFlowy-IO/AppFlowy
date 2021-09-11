// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'view_list_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
class _$ViewListEventTearOff {
  const _$ViewListEventTearOff();

  Initial initial(List<View> views) {
    return Initial(
      views,
    );
  }

  OpenView openView(View view) {
    return OpenView(
      view,
    );
  }
}

/// @nodoc
const $ViewListEvent = _$ViewListEventTearOff();

/// @nodoc
mixin _$ViewListEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<View> views) initial,
    required TResult Function(View view) openView,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<View> views)? initial,
    TResult Function(View view)? openView,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(OpenView value) openView,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(OpenView value)? openView,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ViewListEventCopyWith<$Res> {
  factory $ViewListEventCopyWith(
          ViewListEvent value, $Res Function(ViewListEvent) then) =
      _$ViewListEventCopyWithImpl<$Res>;
}

/// @nodoc
class _$ViewListEventCopyWithImpl<$Res>
    implements $ViewListEventCopyWith<$Res> {
  _$ViewListEventCopyWithImpl(this._value, this._then);

  final ViewListEvent _value;
  // ignore: unused_field
  final $Res Function(ViewListEvent) _then;
}

/// @nodoc
abstract class $InitialCopyWith<$Res> {
  factory $InitialCopyWith(Initial value, $Res Function(Initial) then) =
      _$InitialCopyWithImpl<$Res>;
  $Res call({List<View> views});
}

/// @nodoc
class _$InitialCopyWithImpl<$Res> extends _$ViewListEventCopyWithImpl<$Res>
    implements $InitialCopyWith<$Res> {
  _$InitialCopyWithImpl(Initial _value, $Res Function(Initial) _then)
      : super(_value, (v) => _then(v as Initial));

  @override
  Initial get _value => super._value as Initial;

  @override
  $Res call({
    Object? views = freezed,
  }) {
    return _then(Initial(
      views == freezed
          ? _value.views
          : views // ignore: cast_nullable_to_non_nullable
              as List<View>,
    ));
  }
}

/// @nodoc

class _$Initial implements Initial {
  const _$Initial(this.views);

  @override
  final List<View> views;

  @override
  String toString() {
    return 'ViewListEvent.initial(views: $views)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is Initial &&
            (identical(other.views, views) ||
                const DeepCollectionEquality().equals(other.views, views)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(views);

  @JsonKey(ignore: true)
  @override
  $InitialCopyWith<Initial> get copyWith =>
      _$InitialCopyWithImpl<Initial>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<View> views) initial,
    required TResult Function(View view) openView,
  }) {
    return initial(views);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<View> views)? initial,
    TResult Function(View view)? openView,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(views);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(OpenView value) openView,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(OpenView value)? openView,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class Initial implements ViewListEvent {
  const factory Initial(List<View> views) = _$Initial;

  List<View> get views => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $InitialCopyWith<Initial> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OpenViewCopyWith<$Res> {
  factory $OpenViewCopyWith(OpenView value, $Res Function(OpenView) then) =
      _$OpenViewCopyWithImpl<$Res>;
  $Res call({View view});
}

/// @nodoc
class _$OpenViewCopyWithImpl<$Res> extends _$ViewListEventCopyWithImpl<$Res>
    implements $OpenViewCopyWith<$Res> {
  _$OpenViewCopyWithImpl(OpenView _value, $Res Function(OpenView) _then)
      : super(_value, (v) => _then(v as OpenView));

  @override
  OpenView get _value => super._value as OpenView;

  @override
  $Res call({
    Object? view = freezed,
  }) {
    return _then(OpenView(
      view == freezed
          ? _value.view
          : view // ignore: cast_nullable_to_non_nullable
              as View,
    ));
  }
}

/// @nodoc

class _$OpenView implements OpenView {
  const _$OpenView(this.view);

  @override
  final View view;

  @override
  String toString() {
    return 'ViewListEvent.openView(view: $view)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is OpenView &&
            (identical(other.view, view) ||
                const DeepCollectionEquality().equals(other.view, view)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(view);

  @JsonKey(ignore: true)
  @override
  $OpenViewCopyWith<OpenView> get copyWith =>
      _$OpenViewCopyWithImpl<OpenView>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<View> views) initial,
    required TResult Function(View view) openView,
  }) {
    return openView(view);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<View> views)? initial,
    TResult Function(View view)? openView,
    required TResult orElse(),
  }) {
    if (openView != null) {
      return openView(view);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(OpenView value) openView,
  }) {
    return openView(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(OpenView value)? openView,
    required TResult orElse(),
  }) {
    if (openView != null) {
      return openView(this);
    }
    return orElse();
  }
}

abstract class OpenView implements ViewListEvent {
  const factory OpenView(View view) = _$OpenView;

  View get view => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $OpenViewCopyWith<OpenView> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
class _$ViewListStateTearOff {
  const _$ViewListStateTearOff();

  _ViewListState call(
      {required bool isLoading,
      required Option<String> openedView,
      required Option<List<View>> views}) {
    return _ViewListState(
      isLoading: isLoading,
      openedView: openedView,
      views: views,
    );
  }
}

/// @nodoc
const $ViewListState = _$ViewListStateTearOff();

/// @nodoc
mixin _$ViewListState {
  bool get isLoading => throw _privateConstructorUsedError;
  Option<String> get openedView => throw _privateConstructorUsedError;
  Option<List<View>> get views => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ViewListStateCopyWith<ViewListState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ViewListStateCopyWith<$Res> {
  factory $ViewListStateCopyWith(
          ViewListState value, $Res Function(ViewListState) then) =
      _$ViewListStateCopyWithImpl<$Res>;
  $Res call(
      {bool isLoading, Option<String> openedView, Option<List<View>> views});
}

/// @nodoc
class _$ViewListStateCopyWithImpl<$Res>
    implements $ViewListStateCopyWith<$Res> {
  _$ViewListStateCopyWithImpl(this._value, this._then);

  final ViewListState _value;
  // ignore: unused_field
  final $Res Function(ViewListState) _then;

  @override
  $Res call({
    Object? isLoading = freezed,
    Object? openedView = freezed,
    Object? views = freezed,
  }) {
    return _then(_value.copyWith(
      isLoading: isLoading == freezed
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      openedView: openedView == freezed
          ? _value.openedView
          : openedView // ignore: cast_nullable_to_non_nullable
              as Option<String>,
      views: views == freezed
          ? _value.views
          : views // ignore: cast_nullable_to_non_nullable
              as Option<List<View>>,
    ));
  }
}

/// @nodoc
abstract class _$ViewListStateCopyWith<$Res>
    implements $ViewListStateCopyWith<$Res> {
  factory _$ViewListStateCopyWith(
          _ViewListState value, $Res Function(_ViewListState) then) =
      __$ViewListStateCopyWithImpl<$Res>;
  @override
  $Res call(
      {bool isLoading, Option<String> openedView, Option<List<View>> views});
}

/// @nodoc
class __$ViewListStateCopyWithImpl<$Res>
    extends _$ViewListStateCopyWithImpl<$Res>
    implements _$ViewListStateCopyWith<$Res> {
  __$ViewListStateCopyWithImpl(
      _ViewListState _value, $Res Function(_ViewListState) _then)
      : super(_value, (v) => _then(v as _ViewListState));

  @override
  _ViewListState get _value => super._value as _ViewListState;

  @override
  $Res call({
    Object? isLoading = freezed,
    Object? openedView = freezed,
    Object? views = freezed,
  }) {
    return _then(_ViewListState(
      isLoading: isLoading == freezed
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      openedView: openedView == freezed
          ? _value.openedView
          : openedView // ignore: cast_nullable_to_non_nullable
              as Option<String>,
      views: views == freezed
          ? _value.views
          : views // ignore: cast_nullable_to_non_nullable
              as Option<List<View>>,
    ));
  }
}

/// @nodoc

class _$_ViewListState implements _ViewListState {
  const _$_ViewListState(
      {required this.isLoading, required this.openedView, required this.views});

  @override
  final bool isLoading;
  @override
  final Option<String> openedView;
  @override
  final Option<List<View>> views;

  @override
  String toString() {
    return 'ViewListState(isLoading: $isLoading, openedView: $openedView, views: $views)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _ViewListState &&
            (identical(other.isLoading, isLoading) ||
                const DeepCollectionEquality()
                    .equals(other.isLoading, isLoading)) &&
            (identical(other.openedView, openedView) ||
                const DeepCollectionEquality()
                    .equals(other.openedView, openedView)) &&
            (identical(other.views, views) ||
                const DeepCollectionEquality().equals(other.views, views)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(isLoading) ^
      const DeepCollectionEquality().hash(openedView) ^
      const DeepCollectionEquality().hash(views);

  @JsonKey(ignore: true)
  @override
  _$ViewListStateCopyWith<_ViewListState> get copyWith =>
      __$ViewListStateCopyWithImpl<_ViewListState>(this, _$identity);
}

abstract class _ViewListState implements ViewListState {
  const factory _ViewListState(
      {required bool isLoading,
      required Option<String> openedView,
      required Option<List<View>> views}) = _$_ViewListState;

  @override
  bool get isLoading => throw _privateConstructorUsedError;
  @override
  Option<String> get openedView => throw _privateConstructorUsedError;
  @override
  Option<List<View>> get views => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$ViewListStateCopyWith<_ViewListState> get copyWith =>
      throw _privateConstructorUsedError;
}
