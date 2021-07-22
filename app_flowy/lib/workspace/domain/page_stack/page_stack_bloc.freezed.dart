// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides

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

  NewPageContext setContext(PageContext newContext) {
    return NewPageContext(
      newContext,
    );
  }
}

/// @nodoc
const $PageStackEvent = _$PageStackEventTearOff();

/// @nodoc
mixin _$PageStackEvent {
  PageContext get newContext => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(PageContext newContext) setContext,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PageContext newContext)? setContext,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NewPageContext value) setContext,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NewPageContext value)? setContext,
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
  $Res call({PageContext newContext});
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
    Object? newContext = freezed,
  }) {
    return _then(_value.copyWith(
      newContext: newContext == freezed
          ? _value.newContext
          : newContext // ignore: cast_nullable_to_non_nullable
              as PageContext,
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
  $Res call({PageContext newContext});
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
    Object? newContext = freezed,
  }) {
    return _then(NewPageContext(
      newContext == freezed
          ? _value.newContext
          : newContext // ignore: cast_nullable_to_non_nullable
              as PageContext,
    ));
  }
}

/// @nodoc

class _$NewPageContext implements NewPageContext {
  const _$NewPageContext(this.newContext);

  @override
  final PageContext newContext;

  @override
  String toString() {
    return 'PageStackEvent.setContext(newContext: $newContext)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is NewPageContext &&
            (identical(other.newContext, newContext) ||
                const DeepCollectionEquality()
                    .equals(other.newContext, newContext)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(newContext);

  @JsonKey(ignore: true)
  @override
  $NewPageContextCopyWith<NewPageContext> get copyWith =>
      _$NewPageContextCopyWithImpl<NewPageContext>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(PageContext newContext) setContext,
  }) {
    return setContext(newContext);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PageContext newContext)? setContext,
    required TResult orElse(),
  }) {
    if (setContext != null) {
      return setContext(newContext);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NewPageContext value) setContext,
  }) {
    return setContext(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NewPageContext value)? setContext,
    required TResult orElse(),
  }) {
    if (setContext != null) {
      return setContext(this);
    }
    return orElse();
  }
}

abstract class NewPageContext implements PageStackEvent {
  const factory NewPageContext(PageContext newContext) = _$NewPageContext;

  @override
  PageContext get newContext => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  $NewPageContextCopyWith<NewPageContext> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
class _$PageStackStateTearOff {
  const _$PageStackStateTearOff();

  _PageStackState call({required PageContext pageContext}) {
    return _PageStackState(
      pageContext: pageContext,
    );
  }
}

/// @nodoc
const $PageStackState = _$PageStackStateTearOff();

/// @nodoc
mixin _$PageStackState {
  PageContext get pageContext => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $PageStackStateCopyWith<PageStackState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PageStackStateCopyWith<$Res> {
  factory $PageStackStateCopyWith(
          PageStackState value, $Res Function(PageStackState) then) =
      _$PageStackStateCopyWithImpl<$Res>;
  $Res call({PageContext pageContext});
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
    Object? pageContext = freezed,
  }) {
    return _then(_value.copyWith(
      pageContext: pageContext == freezed
          ? _value.pageContext
          : pageContext // ignore: cast_nullable_to_non_nullable
              as PageContext,
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
  $Res call({PageContext pageContext});
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
    Object? pageContext = freezed,
  }) {
    return _then(_PageStackState(
      pageContext: pageContext == freezed
          ? _value.pageContext
          : pageContext // ignore: cast_nullable_to_non_nullable
              as PageContext,
    ));
  }
}

/// @nodoc

class _$_PageStackState implements _PageStackState {
  const _$_PageStackState({required this.pageContext});

  @override
  final PageContext pageContext;

  @override
  String toString() {
    return 'PageStackState(pageContext: $pageContext)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _PageStackState &&
            (identical(other.pageContext, pageContext) ||
                const DeepCollectionEquality()
                    .equals(other.pageContext, pageContext)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(pageContext);

  @JsonKey(ignore: true)
  @override
  _$PageStackStateCopyWith<_PageStackState> get copyWith =>
      __$PageStackStateCopyWithImpl<_PageStackState>(this, _$identity);
}

abstract class _PageStackState implements PageStackState {
  const factory _PageStackState({required PageContext pageContext}) =
      _$_PageStackState;

  @override
  PageContext get pageContext => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$PageStackStateCopyWith<_PageStackState> get copyWith =>
      throw _privateConstructorUsedError;
}
