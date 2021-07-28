// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'page_stack_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
class _$PageStackEventTearOff {
  const _$PageStackEventTearOff();

  NewPageContext setStackView(HomeStackView newStackView) {
    return NewPageContext(
      newStackView,
    );
  }
}

/// @nodoc
const $PageStackEvent = _$PageStackEventTearOff();

/// @nodoc
mixin _$PageStackEvent {
  HomeStackView get newStackView => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(HomeStackView newStackView) setStackView,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(HomeStackView newStackView)? setStackView,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NewPageContext value) setStackView,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NewPageContext value)? setStackView,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $PageStackEventCopyWith<PageStackEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PageStackEventCopyWith<$Res> {
  factory $PageStackEventCopyWith(
          PageStackEvent value, $Res Function(PageStackEvent) then) =
      _$PageStackEventCopyWithImpl<$Res>;
  $Res call({HomeStackView newStackView});
}

/// @nodoc
class _$PageStackEventCopyWithImpl<$Res>
    implements $PageStackEventCopyWith<$Res> {
  _$PageStackEventCopyWithImpl(this._value, this._then);

  final PageStackEvent _value;
  // ignore: unused_field
  final $Res Function(PageStackEvent) _then;

  @override
  $Res call({
    Object? newStackView = freezed,
  }) {
    return _then(_value.copyWith(
      newStackView: newStackView == freezed
          ? _value.newStackView
          : newStackView // ignore: cast_nullable_to_non_nullable
              as HomeStackView,
    ));
  }
}

/// @nodoc
abstract class $NewPageContextCopyWith<$Res>
    implements $PageStackEventCopyWith<$Res> {
  factory $NewPageContextCopyWith(
          NewPageContext value, $Res Function(NewPageContext) then) =
      _$NewPageContextCopyWithImpl<$Res>;
  @override
  $Res call({HomeStackView newStackView});
}

/// @nodoc
class _$NewPageContextCopyWithImpl<$Res>
    extends _$PageStackEventCopyWithImpl<$Res>
    implements $NewPageContextCopyWith<$Res> {
  _$NewPageContextCopyWithImpl(
      NewPageContext _value, $Res Function(NewPageContext) _then)
      : super(_value, (v) => _then(v as NewPageContext));

  @override
  NewPageContext get _value => super._value as NewPageContext;

  @override
  $Res call({
    Object? newStackView = freezed,
  }) {
    return _then(NewPageContext(
      newStackView == freezed
          ? _value.newStackView
          : newStackView // ignore: cast_nullable_to_non_nullable
              as HomeStackView,
    ));
  }
}

/// @nodoc

class _$NewPageContext implements NewPageContext {
  const _$NewPageContext(this.newStackView);

  @override
  final HomeStackView newStackView;

  @override
  String toString() {
    return 'PageStackEvent.setStackView(newStackView: $newStackView)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is NewPageContext &&
            (identical(other.newStackView, newStackView) ||
                const DeepCollectionEquality()
                    .equals(other.newStackView, newStackView)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(newStackView);

  @JsonKey(ignore: true)
  @override
  $NewPageContextCopyWith<NewPageContext> get copyWith =>
      _$NewPageContextCopyWithImpl<NewPageContext>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(HomeStackView newStackView) setStackView,
  }) {
    return setStackView(newStackView);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(HomeStackView newStackView)? setStackView,
    required TResult orElse(),
  }) {
    if (setStackView != null) {
      return setStackView(newStackView);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NewPageContext value) setStackView,
  }) {
    return setStackView(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NewPageContext value)? setStackView,
    required TResult orElse(),
  }) {
    if (setStackView != null) {
      return setStackView(this);
    }
    return orElse();
  }
}

abstract class NewPageContext implements PageStackEvent {
  const factory NewPageContext(HomeStackView newStackView) = _$NewPageContext;

  @override
  HomeStackView get newStackView => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  $NewPageContextCopyWith<NewPageContext> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
class _$PageStackStateTearOff {
  const _$PageStackStateTearOff();

  _PageStackState call({required HomeStackView stackView}) {
    return _PageStackState(
      stackView: stackView,
    );
  }
}

/// @nodoc
const $PageStackState = _$PageStackStateTearOff();

/// @nodoc
mixin _$PageStackState {
  HomeStackView get stackView => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $PageStackStateCopyWith<PageStackState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PageStackStateCopyWith<$Res> {
  factory $PageStackStateCopyWith(
          PageStackState value, $Res Function(PageStackState) then) =
      _$PageStackStateCopyWithImpl<$Res>;
  $Res call({HomeStackView stackView});
}

/// @nodoc
class _$PageStackStateCopyWithImpl<$Res>
    implements $PageStackStateCopyWith<$Res> {
  _$PageStackStateCopyWithImpl(this._value, this._then);

  final PageStackState _value;
  // ignore: unused_field
  final $Res Function(PageStackState) _then;

  @override
  $Res call({
    Object? stackView = freezed,
  }) {
    return _then(_value.copyWith(
      stackView: stackView == freezed
          ? _value.stackView
          : stackView // ignore: cast_nullable_to_non_nullable
              as HomeStackView,
    ));
  }
}

/// @nodoc
abstract class _$PageStackStateCopyWith<$Res>
    implements $PageStackStateCopyWith<$Res> {
  factory _$PageStackStateCopyWith(
          _PageStackState value, $Res Function(_PageStackState) then) =
      __$PageStackStateCopyWithImpl<$Res>;
  @override
  $Res call({HomeStackView stackView});
}

/// @nodoc
class __$PageStackStateCopyWithImpl<$Res>
    extends _$PageStackStateCopyWithImpl<$Res>
    implements _$PageStackStateCopyWith<$Res> {
  __$PageStackStateCopyWithImpl(
      _PageStackState _value, $Res Function(_PageStackState) _then)
      : super(_value, (v) => _then(v as _PageStackState));

  @override
  _PageStackState get _value => super._value as _PageStackState;

  @override
  $Res call({
    Object? stackView = freezed,
  }) {
    return _then(_PageStackState(
      stackView: stackView == freezed
          ? _value.stackView
          : stackView // ignore: cast_nullable_to_non_nullable
              as HomeStackView,
    ));
  }
}

/// @nodoc

class _$_PageStackState implements _PageStackState {
  const _$_PageStackState({required this.stackView});

  @override
  final HomeStackView stackView;

  @override
  String toString() {
    return 'PageStackState(stackView: $stackView)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _PageStackState &&
            (identical(other.stackView, stackView) ||
                const DeepCollectionEquality()
                    .equals(other.stackView, stackView)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(stackView);

  @JsonKey(ignore: true)
  @override
  _$PageStackStateCopyWith<_PageStackState> get copyWith =>
      __$PageStackStateCopyWithImpl<_PageStackState>(this, _$identity);
}

abstract class _PageStackState implements PageStackState {
  const factory _PageStackState({required HomeStackView stackView}) =
      _$_PageStackState;

  @override
  HomeStackView get stackView => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$PageStackStateCopyWith<_PageStackState> get copyWith =>
      throw _privateConstructorUsedError;
}
