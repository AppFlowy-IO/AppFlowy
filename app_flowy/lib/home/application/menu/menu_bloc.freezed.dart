// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides

part of 'menu_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
class _$MenuEventTearOff {
  const _$MenuEventTearOff();

  Collapse collapse() {
    return const Collapse();
  }

  _OpenPage openPage(PageContext context) {
    return _OpenPage(
      context,
    );
  }

  _CreateApp createApp(String appName) {
    return _CreateApp(
      appName,
    );
  }
}

/// @nodoc
const $MenuEvent = _$MenuEventTearOff();

/// @nodoc
mixin _$MenuEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() collapse,
    required TResult Function(PageContext context) openPage,
    required TResult Function(String appName) createApp,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? collapse,
    TResult Function(PageContext context)? openPage,
    TResult Function(String appName)? createApp,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Collapse value) collapse,
    required TResult Function(_OpenPage value) openPage,
    required TResult Function(_CreateApp value) createApp,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Collapse value)? collapse,
    TResult Function(_OpenPage value)? openPage,
    TResult Function(_CreateApp value)? createApp,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MenuEventCopyWith<$Res> {
  factory $MenuEventCopyWith(MenuEvent value, $Res Function(MenuEvent) then) =
      _$MenuEventCopyWithImpl<$Res>;
}

/// @nodoc
class _$MenuEventCopyWithImpl<$Res> implements $MenuEventCopyWith<$Res> {
  _$MenuEventCopyWithImpl(this._value, this._then);

  final MenuEvent _value;
  // ignore: unused_field
  final $Res Function(MenuEvent) _then;
}

/// @nodoc
abstract class $CollapseCopyWith<$Res> {
  factory $CollapseCopyWith(Collapse value, $Res Function(Collapse) then) =
      _$CollapseCopyWithImpl<$Res>;
}

/// @nodoc
class _$CollapseCopyWithImpl<$Res> extends _$MenuEventCopyWithImpl<$Res>
    implements $CollapseCopyWith<$Res> {
  _$CollapseCopyWithImpl(Collapse _value, $Res Function(Collapse) _then)
      : super(_value, (v) => _then(v as Collapse));

  @override
  Collapse get _value => super._value as Collapse;
}

/// @nodoc

class _$Collapse implements Collapse {
  const _$Collapse();

  @override
  String toString() {
    return 'MenuEvent.collapse()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) || (other is Collapse);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() collapse,
    required TResult Function(PageContext context) openPage,
    required TResult Function(String appName) createApp,
  }) {
    return collapse();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? collapse,
    TResult Function(PageContext context)? openPage,
    TResult Function(String appName)? createApp,
    required TResult orElse(),
  }) {
    if (collapse != null) {
      return collapse();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Collapse value) collapse,
    required TResult Function(_OpenPage value) openPage,
    required TResult Function(_CreateApp value) createApp,
  }) {
    return collapse(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Collapse value)? collapse,
    TResult Function(_OpenPage value)? openPage,
    TResult Function(_CreateApp value)? createApp,
    required TResult orElse(),
  }) {
    if (collapse != null) {
      return collapse(this);
    }
    return orElse();
  }
}

abstract class Collapse implements MenuEvent {
  const factory Collapse() = _$Collapse;
}

/// @nodoc
abstract class _$OpenPageCopyWith<$Res> {
  factory _$OpenPageCopyWith(_OpenPage value, $Res Function(_OpenPage) then) =
      __$OpenPageCopyWithImpl<$Res>;
  $Res call({PageContext context});
}

/// @nodoc
class __$OpenPageCopyWithImpl<$Res> extends _$MenuEventCopyWithImpl<$Res>
    implements _$OpenPageCopyWith<$Res> {
  __$OpenPageCopyWithImpl(_OpenPage _value, $Res Function(_OpenPage) _then)
      : super(_value, (v) => _then(v as _OpenPage));

  @override
  _OpenPage get _value => super._value as _OpenPage;

  @override
  $Res call({
    Object? context = freezed,
  }) {
    return _then(_OpenPage(
      context == freezed
          ? _value.context
          : context // ignore: cast_nullable_to_non_nullable
              as PageContext,
    ));
  }
}

/// @nodoc

class _$_OpenPage implements _OpenPage {
  const _$_OpenPage(this.context);

  @override
  final PageContext context;

  @override
  String toString() {
    return 'MenuEvent.openPage(context: $context)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _OpenPage &&
            (identical(other.context, context) ||
                const DeepCollectionEquality().equals(other.context, context)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(context);

  @JsonKey(ignore: true)
  @override
  _$OpenPageCopyWith<_OpenPage> get copyWith =>
      __$OpenPageCopyWithImpl<_OpenPage>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() collapse,
    required TResult Function(PageContext context) openPage,
    required TResult Function(String appName) createApp,
  }) {
    return openPage(context);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? collapse,
    TResult Function(PageContext context)? openPage,
    TResult Function(String appName)? createApp,
    required TResult orElse(),
  }) {
    if (openPage != null) {
      return openPage(context);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Collapse value) collapse,
    required TResult Function(_OpenPage value) openPage,
    required TResult Function(_CreateApp value) createApp,
  }) {
    return openPage(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Collapse value)? collapse,
    TResult Function(_OpenPage value)? openPage,
    TResult Function(_CreateApp value)? createApp,
    required TResult orElse(),
  }) {
    if (openPage != null) {
      return openPage(this);
    }
    return orElse();
  }
}

abstract class _OpenPage implements MenuEvent {
  const factory _OpenPage(PageContext context) = _$_OpenPage;

  PageContext get context => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  _$OpenPageCopyWith<_OpenPage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$CreateAppCopyWith<$Res> {
  factory _$CreateAppCopyWith(
          _CreateApp value, $Res Function(_CreateApp) then) =
      __$CreateAppCopyWithImpl<$Res>;
  $Res call({String appName});
}

/// @nodoc
class __$CreateAppCopyWithImpl<$Res> extends _$MenuEventCopyWithImpl<$Res>
    implements _$CreateAppCopyWith<$Res> {
  __$CreateAppCopyWithImpl(_CreateApp _value, $Res Function(_CreateApp) _then)
      : super(_value, (v) => _then(v as _CreateApp));

  @override
  _CreateApp get _value => super._value as _CreateApp;

  @override
  $Res call({
    Object? appName = freezed,
  }) {
    return _then(_CreateApp(
      appName == freezed
          ? _value.appName
          : appName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$_CreateApp implements _CreateApp {
  const _$_CreateApp(this.appName);

  @override
  final String appName;

  @override
  String toString() {
    return 'MenuEvent.createApp(appName: $appName)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _CreateApp &&
            (identical(other.appName, appName) ||
                const DeepCollectionEquality().equals(other.appName, appName)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(appName);

  @JsonKey(ignore: true)
  @override
  _$CreateAppCopyWith<_CreateApp> get copyWith =>
      __$CreateAppCopyWithImpl<_CreateApp>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() collapse,
    required TResult Function(PageContext context) openPage,
    required TResult Function(String appName) createApp,
  }) {
    return createApp(appName);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? collapse,
    TResult Function(PageContext context)? openPage,
    TResult Function(String appName)? createApp,
    required TResult orElse(),
  }) {
    if (createApp != null) {
      return createApp(appName);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Collapse value) collapse,
    required TResult Function(_OpenPage value) openPage,
    required TResult Function(_CreateApp value) createApp,
  }) {
    return createApp(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Collapse value)? collapse,
    TResult Function(_OpenPage value)? openPage,
    TResult Function(_CreateApp value)? createApp,
    required TResult orElse(),
  }) {
    if (createApp != null) {
      return createApp(this);
    }
    return orElse();
  }
}

abstract class _CreateApp implements MenuEvent {
  const factory _CreateApp(String appName) = _$_CreateApp;

  String get appName => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  _$CreateAppCopyWith<_CreateApp> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
class _$MenuStateTearOff {
  const _$MenuStateTearOff();

  _MenuState call(
      {required bool isCollapse, required Option<PageContext> pageContext}) {
    return _MenuState(
      isCollapse: isCollapse,
      pageContext: pageContext,
    );
  }
}

/// @nodoc
const $MenuState = _$MenuStateTearOff();

/// @nodoc
mixin _$MenuState {
  bool get isCollapse => throw _privateConstructorUsedError;
  Option<PageContext> get pageContext => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $MenuStateCopyWith<MenuState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MenuStateCopyWith<$Res> {
  factory $MenuStateCopyWith(MenuState value, $Res Function(MenuState) then) =
      _$MenuStateCopyWithImpl<$Res>;
  $Res call({bool isCollapse, Option<PageContext> pageContext});
}

/// @nodoc
class _$MenuStateCopyWithImpl<$Res> implements $MenuStateCopyWith<$Res> {
  _$MenuStateCopyWithImpl(this._value, this._then);

  final MenuState _value;
  // ignore: unused_field
  final $Res Function(MenuState) _then;

  @override
  $Res call({
    Object? isCollapse = freezed,
    Object? pageContext = freezed,
  }) {
    return _then(_value.copyWith(
      isCollapse: isCollapse == freezed
          ? _value.isCollapse
          : isCollapse // ignore: cast_nullable_to_non_nullable
              as bool,
      pageContext: pageContext == freezed
          ? _value.pageContext
          : pageContext // ignore: cast_nullable_to_non_nullable
              as Option<PageContext>,
    ));
  }
}

/// @nodoc
abstract class _$MenuStateCopyWith<$Res> implements $MenuStateCopyWith<$Res> {
  factory _$MenuStateCopyWith(
          _MenuState value, $Res Function(_MenuState) then) =
      __$MenuStateCopyWithImpl<$Res>;
  @override
  $Res call({bool isCollapse, Option<PageContext> pageContext});
}

/// @nodoc
class __$MenuStateCopyWithImpl<$Res> extends _$MenuStateCopyWithImpl<$Res>
    implements _$MenuStateCopyWith<$Res> {
  __$MenuStateCopyWithImpl(_MenuState _value, $Res Function(_MenuState) _then)
      : super(_value, (v) => _then(v as _MenuState));

  @override
  _MenuState get _value => super._value as _MenuState;

  @override
  $Res call({
    Object? isCollapse = freezed,
    Object? pageContext = freezed,
  }) {
    return _then(_MenuState(
      isCollapse: isCollapse == freezed
          ? _value.isCollapse
          : isCollapse // ignore: cast_nullable_to_non_nullable
              as bool,
      pageContext: pageContext == freezed
          ? _value.pageContext
          : pageContext // ignore: cast_nullable_to_non_nullable
              as Option<PageContext>,
    ));
  }
}

/// @nodoc

class _$_MenuState implements _MenuState {
  const _$_MenuState({required this.isCollapse, required this.pageContext});

  @override
  final bool isCollapse;
  @override
  final Option<PageContext> pageContext;

  @override
  String toString() {
    return 'MenuState(isCollapse: $isCollapse, pageContext: $pageContext)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _MenuState &&
            (identical(other.isCollapse, isCollapse) ||
                const DeepCollectionEquality()
                    .equals(other.isCollapse, isCollapse)) &&
            (identical(other.pageContext, pageContext) ||
                const DeepCollectionEquality()
                    .equals(other.pageContext, pageContext)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(isCollapse) ^
      const DeepCollectionEquality().hash(pageContext);

  @JsonKey(ignore: true)
  @override
  _$MenuStateCopyWith<_MenuState> get copyWith =>
      __$MenuStateCopyWithImpl<_MenuState>(this, _$identity);
}

abstract class _MenuState implements MenuState {
  const factory _MenuState(
      {required bool isCollapse,
      required Option<PageContext> pageContext}) = _$_MenuState;

  @override
  bool get isCollapse => throw _privateConstructorUsedError;
  @override
  Option<PageContext> get pageContext => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$MenuStateCopyWith<_MenuState> get copyWith =>
      throw _privateConstructorUsedError;
}
