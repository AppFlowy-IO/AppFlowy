// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

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

  _Initial initial() {
    return const _Initial();
  }

  _Collapse collapse() {
    return const _Collapse();
  }

  _OpenPage openPage(Plugin plugin) {
    return _OpenPage(
      plugin,
    );
  }

  _CreateApp createApp(String name, {String? desc}) {
    return _CreateApp(
      name,
      desc: desc,
    );
  }

  _MoveApp moveApp(int fromIndex, int toIndex) {
    return _MoveApp(
      fromIndex,
      toIndex,
    );
  }

  _ReceiveApps didReceiveApps(Either<List<App>, FlowyError> appsOrFail) {
    return _ReceiveApps(
      appsOrFail,
    );
  }
}

/// @nodoc
const $MenuEvent = _$MenuEventTearOff();

/// @nodoc
mixin _$MenuEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() collapse,
    required TResult Function(Plugin plugin) openPage,
    required TResult Function(String name, String? desc) createApp,
    required TResult Function(int fromIndex, int toIndex) moveApp,
    required TResult Function(Either<List<App>, FlowyError> appsOrFail)
        didReceiveApps,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? collapse,
    TResult Function(Plugin plugin)? openPage,
    TResult Function(String name, String? desc)? createApp,
    TResult Function(int fromIndex, int toIndex)? moveApp,
    TResult Function(Either<List<App>, FlowyError> appsOrFail)? didReceiveApps,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? collapse,
    TResult Function(Plugin plugin)? openPage,
    TResult Function(String name, String? desc)? createApp,
    TResult Function(int fromIndex, int toIndex)? moveApp,
    TResult Function(Either<List<App>, FlowyError> appsOrFail)? didReceiveApps,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Collapse value) collapse,
    required TResult Function(_OpenPage value) openPage,
    required TResult Function(_CreateApp value) createApp,
    required TResult Function(_MoveApp value) moveApp,
    required TResult Function(_ReceiveApps value) didReceiveApps,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Collapse value)? collapse,
    TResult Function(_OpenPage value)? openPage,
    TResult Function(_CreateApp value)? createApp,
    TResult Function(_MoveApp value)? moveApp,
    TResult Function(_ReceiveApps value)? didReceiveApps,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Collapse value)? collapse,
    TResult Function(_OpenPage value)? openPage,
    TResult Function(_CreateApp value)? createApp,
    TResult Function(_MoveApp value)? moveApp,
    TResult Function(_ReceiveApps value)? didReceiveApps,
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
abstract class _$InitialCopyWith<$Res> {
  factory _$InitialCopyWith(_Initial value, $Res Function(_Initial) then) =
      __$InitialCopyWithImpl<$Res>;
}

/// @nodoc
class __$InitialCopyWithImpl<$Res> extends _$MenuEventCopyWithImpl<$Res>
    implements _$InitialCopyWith<$Res> {
  __$InitialCopyWithImpl(_Initial _value, $Res Function(_Initial) _then)
      : super(_value, (v) => _then(v as _Initial));

  @override
  _Initial get _value => super._value as _Initial;
}

/// @nodoc

class _$_Initial implements _Initial {
  const _$_Initial();

  @override
  String toString() {
    return 'MenuEvent.initial()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) || (other is _Initial);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() collapse,
    required TResult Function(Plugin plugin) openPage,
    required TResult Function(String name, String? desc) createApp,
    required TResult Function(int fromIndex, int toIndex) moveApp,
    required TResult Function(Either<List<App>, FlowyError> appsOrFail)
        didReceiveApps,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? collapse,
    TResult Function(Plugin plugin)? openPage,
    TResult Function(String name, String? desc)? createApp,
    TResult Function(int fromIndex, int toIndex)? moveApp,
    TResult Function(Either<List<App>, FlowyError> appsOrFail)? didReceiveApps,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? collapse,
    TResult Function(Plugin plugin)? openPage,
    TResult Function(String name, String? desc)? createApp,
    TResult Function(int fromIndex, int toIndex)? moveApp,
    TResult Function(Either<List<App>, FlowyError> appsOrFail)? didReceiveApps,
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
    required TResult Function(_Initial value) initial,
    required TResult Function(_Collapse value) collapse,
    required TResult Function(_OpenPage value) openPage,
    required TResult Function(_CreateApp value) createApp,
    required TResult Function(_MoveApp value) moveApp,
    required TResult Function(_ReceiveApps value) didReceiveApps,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Collapse value)? collapse,
    TResult Function(_OpenPage value)? openPage,
    TResult Function(_CreateApp value)? createApp,
    TResult Function(_MoveApp value)? moveApp,
    TResult Function(_ReceiveApps value)? didReceiveApps,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Collapse value)? collapse,
    TResult Function(_OpenPage value)? openPage,
    TResult Function(_CreateApp value)? createApp,
    TResult Function(_MoveApp value)? moveApp,
    TResult Function(_ReceiveApps value)? didReceiveApps,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _Initial implements MenuEvent {
  const factory _Initial() = _$_Initial;
}

/// @nodoc
abstract class _$CollapseCopyWith<$Res> {
  factory _$CollapseCopyWith(_Collapse value, $Res Function(_Collapse) then) =
      __$CollapseCopyWithImpl<$Res>;
}

/// @nodoc
class __$CollapseCopyWithImpl<$Res> extends _$MenuEventCopyWithImpl<$Res>
    implements _$CollapseCopyWith<$Res> {
  __$CollapseCopyWithImpl(_Collapse _value, $Res Function(_Collapse) _then)
      : super(_value, (v) => _then(v as _Collapse));

  @override
  _Collapse get _value => super._value as _Collapse;
}

/// @nodoc

class _$_Collapse implements _Collapse {
  const _$_Collapse();

  @override
  String toString() {
    return 'MenuEvent.collapse()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) || (other is _Collapse);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() collapse,
    required TResult Function(Plugin plugin) openPage,
    required TResult Function(String name, String? desc) createApp,
    required TResult Function(int fromIndex, int toIndex) moveApp,
    required TResult Function(Either<List<App>, FlowyError> appsOrFail)
        didReceiveApps,
  }) {
    return collapse();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? collapse,
    TResult Function(Plugin plugin)? openPage,
    TResult Function(String name, String? desc)? createApp,
    TResult Function(int fromIndex, int toIndex)? moveApp,
    TResult Function(Either<List<App>, FlowyError> appsOrFail)? didReceiveApps,
  }) {
    return collapse?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? collapse,
    TResult Function(Plugin plugin)? openPage,
    TResult Function(String name, String? desc)? createApp,
    TResult Function(int fromIndex, int toIndex)? moveApp,
    TResult Function(Either<List<App>, FlowyError> appsOrFail)? didReceiveApps,
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
    required TResult Function(_Initial value) initial,
    required TResult Function(_Collapse value) collapse,
    required TResult Function(_OpenPage value) openPage,
    required TResult Function(_CreateApp value) createApp,
    required TResult Function(_MoveApp value) moveApp,
    required TResult Function(_ReceiveApps value) didReceiveApps,
  }) {
    return collapse(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Collapse value)? collapse,
    TResult Function(_OpenPage value)? openPage,
    TResult Function(_CreateApp value)? createApp,
    TResult Function(_MoveApp value)? moveApp,
    TResult Function(_ReceiveApps value)? didReceiveApps,
  }) {
    return collapse?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Collapse value)? collapse,
    TResult Function(_OpenPage value)? openPage,
    TResult Function(_CreateApp value)? createApp,
    TResult Function(_MoveApp value)? moveApp,
    TResult Function(_ReceiveApps value)? didReceiveApps,
    required TResult orElse(),
  }) {
    if (collapse != null) {
      return collapse(this);
    }
    return orElse();
  }
}

abstract class _Collapse implements MenuEvent {
  const factory _Collapse() = _$_Collapse;
}

/// @nodoc
abstract class _$OpenPageCopyWith<$Res> {
  factory _$OpenPageCopyWith(_OpenPage value, $Res Function(_OpenPage) then) =
      __$OpenPageCopyWithImpl<$Res>;
  $Res call({Plugin plugin});
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
    Object? plugin = freezed,
  }) {
    return _then(_OpenPage(
      plugin == freezed
          ? _value.plugin
          : plugin // ignore: cast_nullable_to_non_nullable
              as Plugin,
    ));
  }
}

/// @nodoc

class _$_OpenPage implements _OpenPage {
  const _$_OpenPage(this.plugin);

  @override
  final Plugin plugin;

  @override
  String toString() {
    return 'MenuEvent.openPage(plugin: $plugin)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _OpenPage &&
            (identical(other.plugin, plugin) ||
                const DeepCollectionEquality().equals(other.plugin, plugin)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(plugin);

  @JsonKey(ignore: true)
  @override
  _$OpenPageCopyWith<_OpenPage> get copyWith =>
      __$OpenPageCopyWithImpl<_OpenPage>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() collapse,
    required TResult Function(Plugin plugin) openPage,
    required TResult Function(String name, String? desc) createApp,
    required TResult Function(int fromIndex, int toIndex) moveApp,
    required TResult Function(Either<List<App>, FlowyError> appsOrFail)
        didReceiveApps,
  }) {
    return openPage(plugin);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? collapse,
    TResult Function(Plugin plugin)? openPage,
    TResult Function(String name, String? desc)? createApp,
    TResult Function(int fromIndex, int toIndex)? moveApp,
    TResult Function(Either<List<App>, FlowyError> appsOrFail)? didReceiveApps,
  }) {
    return openPage?.call(plugin);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? collapse,
    TResult Function(Plugin plugin)? openPage,
    TResult Function(String name, String? desc)? createApp,
    TResult Function(int fromIndex, int toIndex)? moveApp,
    TResult Function(Either<List<App>, FlowyError> appsOrFail)? didReceiveApps,
    required TResult orElse(),
  }) {
    if (openPage != null) {
      return openPage(plugin);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Collapse value) collapse,
    required TResult Function(_OpenPage value) openPage,
    required TResult Function(_CreateApp value) createApp,
    required TResult Function(_MoveApp value) moveApp,
    required TResult Function(_ReceiveApps value) didReceiveApps,
  }) {
    return openPage(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Collapse value)? collapse,
    TResult Function(_OpenPage value)? openPage,
    TResult Function(_CreateApp value)? createApp,
    TResult Function(_MoveApp value)? moveApp,
    TResult Function(_ReceiveApps value)? didReceiveApps,
  }) {
    return openPage?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Collapse value)? collapse,
    TResult Function(_OpenPage value)? openPage,
    TResult Function(_CreateApp value)? createApp,
    TResult Function(_MoveApp value)? moveApp,
    TResult Function(_ReceiveApps value)? didReceiveApps,
    required TResult orElse(),
  }) {
    if (openPage != null) {
      return openPage(this);
    }
    return orElse();
  }
}

abstract class _OpenPage implements MenuEvent {
  const factory _OpenPage(Plugin plugin) = _$_OpenPage;

  Plugin get plugin => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  _$OpenPageCopyWith<_OpenPage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$CreateAppCopyWith<$Res> {
  factory _$CreateAppCopyWith(
          _CreateApp value, $Res Function(_CreateApp) then) =
      __$CreateAppCopyWithImpl<$Res>;
  $Res call({String name, String? desc});
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
    Object? name = freezed,
    Object? desc = freezed,
  }) {
    return _then(_CreateApp(
      name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      desc: desc == freezed
          ? _value.desc
          : desc // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$_CreateApp implements _CreateApp {
  const _$_CreateApp(this.name, {this.desc});

  @override
  final String name;
  @override
  final String? desc;

  @override
  String toString() {
    return 'MenuEvent.createApp(name: $name, desc: $desc)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _CreateApp &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.desc, desc) ||
                const DeepCollectionEquality().equals(other.desc, desc)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(desc);

  @JsonKey(ignore: true)
  @override
  _$CreateAppCopyWith<_CreateApp> get copyWith =>
      __$CreateAppCopyWithImpl<_CreateApp>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() collapse,
    required TResult Function(Plugin plugin) openPage,
    required TResult Function(String name, String? desc) createApp,
    required TResult Function(int fromIndex, int toIndex) moveApp,
    required TResult Function(Either<List<App>, FlowyError> appsOrFail)
        didReceiveApps,
  }) {
    return createApp(name, desc);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? collapse,
    TResult Function(Plugin plugin)? openPage,
    TResult Function(String name, String? desc)? createApp,
    TResult Function(int fromIndex, int toIndex)? moveApp,
    TResult Function(Either<List<App>, FlowyError> appsOrFail)? didReceiveApps,
  }) {
    return createApp?.call(name, desc);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? collapse,
    TResult Function(Plugin plugin)? openPage,
    TResult Function(String name, String? desc)? createApp,
    TResult Function(int fromIndex, int toIndex)? moveApp,
    TResult Function(Either<List<App>, FlowyError> appsOrFail)? didReceiveApps,
    required TResult orElse(),
  }) {
    if (createApp != null) {
      return createApp(name, desc);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Collapse value) collapse,
    required TResult Function(_OpenPage value) openPage,
    required TResult Function(_CreateApp value) createApp,
    required TResult Function(_MoveApp value) moveApp,
    required TResult Function(_ReceiveApps value) didReceiveApps,
  }) {
    return createApp(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Collapse value)? collapse,
    TResult Function(_OpenPage value)? openPage,
    TResult Function(_CreateApp value)? createApp,
    TResult Function(_MoveApp value)? moveApp,
    TResult Function(_ReceiveApps value)? didReceiveApps,
  }) {
    return createApp?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Collapse value)? collapse,
    TResult Function(_OpenPage value)? openPage,
    TResult Function(_CreateApp value)? createApp,
    TResult Function(_MoveApp value)? moveApp,
    TResult Function(_ReceiveApps value)? didReceiveApps,
    required TResult orElse(),
  }) {
    if (createApp != null) {
      return createApp(this);
    }
    return orElse();
  }
}

abstract class _CreateApp implements MenuEvent {
  const factory _CreateApp(String name, {String? desc}) = _$_CreateApp;

  String get name => throw _privateConstructorUsedError;
  String? get desc => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  _$CreateAppCopyWith<_CreateApp> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$MoveAppCopyWith<$Res> {
  factory _$MoveAppCopyWith(_MoveApp value, $Res Function(_MoveApp) then) =
      __$MoveAppCopyWithImpl<$Res>;
  $Res call({int fromIndex, int toIndex});
}

/// @nodoc
class __$MoveAppCopyWithImpl<$Res> extends _$MenuEventCopyWithImpl<$Res>
    implements _$MoveAppCopyWith<$Res> {
  __$MoveAppCopyWithImpl(_MoveApp _value, $Res Function(_MoveApp) _then)
      : super(_value, (v) => _then(v as _MoveApp));

  @override
  _MoveApp get _value => super._value as _MoveApp;

  @override
  $Res call({
    Object? fromIndex = freezed,
    Object? toIndex = freezed,
  }) {
    return _then(_MoveApp(
      fromIndex == freezed
          ? _value.fromIndex
          : fromIndex // ignore: cast_nullable_to_non_nullable
              as int,
      toIndex == freezed
          ? _value.toIndex
          : toIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$_MoveApp implements _MoveApp {
  const _$_MoveApp(this.fromIndex, this.toIndex);

  @override
  final int fromIndex;
  @override
  final int toIndex;

  @override
  String toString() {
    return 'MenuEvent.moveApp(fromIndex: $fromIndex, toIndex: $toIndex)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _MoveApp &&
            (identical(other.fromIndex, fromIndex) ||
                const DeepCollectionEquality()
                    .equals(other.fromIndex, fromIndex)) &&
            (identical(other.toIndex, toIndex) ||
                const DeepCollectionEquality().equals(other.toIndex, toIndex)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(fromIndex) ^
      const DeepCollectionEquality().hash(toIndex);

  @JsonKey(ignore: true)
  @override
  _$MoveAppCopyWith<_MoveApp> get copyWith =>
      __$MoveAppCopyWithImpl<_MoveApp>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() collapse,
    required TResult Function(Plugin plugin) openPage,
    required TResult Function(String name, String? desc) createApp,
    required TResult Function(int fromIndex, int toIndex) moveApp,
    required TResult Function(Either<List<App>, FlowyError> appsOrFail)
        didReceiveApps,
  }) {
    return moveApp(fromIndex, toIndex);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? collapse,
    TResult Function(Plugin plugin)? openPage,
    TResult Function(String name, String? desc)? createApp,
    TResult Function(int fromIndex, int toIndex)? moveApp,
    TResult Function(Either<List<App>, FlowyError> appsOrFail)? didReceiveApps,
  }) {
    return moveApp?.call(fromIndex, toIndex);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? collapse,
    TResult Function(Plugin plugin)? openPage,
    TResult Function(String name, String? desc)? createApp,
    TResult Function(int fromIndex, int toIndex)? moveApp,
    TResult Function(Either<List<App>, FlowyError> appsOrFail)? didReceiveApps,
    required TResult orElse(),
  }) {
    if (moveApp != null) {
      return moveApp(fromIndex, toIndex);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Collapse value) collapse,
    required TResult Function(_OpenPage value) openPage,
    required TResult Function(_CreateApp value) createApp,
    required TResult Function(_MoveApp value) moveApp,
    required TResult Function(_ReceiveApps value) didReceiveApps,
  }) {
    return moveApp(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Collapse value)? collapse,
    TResult Function(_OpenPage value)? openPage,
    TResult Function(_CreateApp value)? createApp,
    TResult Function(_MoveApp value)? moveApp,
    TResult Function(_ReceiveApps value)? didReceiveApps,
  }) {
    return moveApp?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Collapse value)? collapse,
    TResult Function(_OpenPage value)? openPage,
    TResult Function(_CreateApp value)? createApp,
    TResult Function(_MoveApp value)? moveApp,
    TResult Function(_ReceiveApps value)? didReceiveApps,
    required TResult orElse(),
  }) {
    if (moveApp != null) {
      return moveApp(this);
    }
    return orElse();
  }
}

abstract class _MoveApp implements MenuEvent {
  const factory _MoveApp(int fromIndex, int toIndex) = _$_MoveApp;

  int get fromIndex => throw _privateConstructorUsedError;
  int get toIndex => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  _$MoveAppCopyWith<_MoveApp> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$ReceiveAppsCopyWith<$Res> {
  factory _$ReceiveAppsCopyWith(
          _ReceiveApps value, $Res Function(_ReceiveApps) then) =
      __$ReceiveAppsCopyWithImpl<$Res>;
  $Res call({Either<List<App>, FlowyError> appsOrFail});
}

/// @nodoc
class __$ReceiveAppsCopyWithImpl<$Res> extends _$MenuEventCopyWithImpl<$Res>
    implements _$ReceiveAppsCopyWith<$Res> {
  __$ReceiveAppsCopyWithImpl(
      _ReceiveApps _value, $Res Function(_ReceiveApps) _then)
      : super(_value, (v) => _then(v as _ReceiveApps));

  @override
  _ReceiveApps get _value => super._value as _ReceiveApps;

  @override
  $Res call({
    Object? appsOrFail = freezed,
  }) {
    return _then(_ReceiveApps(
      appsOrFail == freezed
          ? _value.appsOrFail
          : appsOrFail // ignore: cast_nullable_to_non_nullable
              as Either<List<App>, FlowyError>,
    ));
  }
}

/// @nodoc

class _$_ReceiveApps implements _ReceiveApps {
  const _$_ReceiveApps(this.appsOrFail);

  @override
  final Either<List<App>, FlowyError> appsOrFail;

  @override
  String toString() {
    return 'MenuEvent.didReceiveApps(appsOrFail: $appsOrFail)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _ReceiveApps &&
            (identical(other.appsOrFail, appsOrFail) ||
                const DeepCollectionEquality()
                    .equals(other.appsOrFail, appsOrFail)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(appsOrFail);

  @JsonKey(ignore: true)
  @override
  _$ReceiveAppsCopyWith<_ReceiveApps> get copyWith =>
      __$ReceiveAppsCopyWithImpl<_ReceiveApps>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() collapse,
    required TResult Function(Plugin plugin) openPage,
    required TResult Function(String name, String? desc) createApp,
    required TResult Function(int fromIndex, int toIndex) moveApp,
    required TResult Function(Either<List<App>, FlowyError> appsOrFail)
        didReceiveApps,
  }) {
    return didReceiveApps(appsOrFail);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? collapse,
    TResult Function(Plugin plugin)? openPage,
    TResult Function(String name, String? desc)? createApp,
    TResult Function(int fromIndex, int toIndex)? moveApp,
    TResult Function(Either<List<App>, FlowyError> appsOrFail)? didReceiveApps,
  }) {
    return didReceiveApps?.call(appsOrFail);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? collapse,
    TResult Function(Plugin plugin)? openPage,
    TResult Function(String name, String? desc)? createApp,
    TResult Function(int fromIndex, int toIndex)? moveApp,
    TResult Function(Either<List<App>, FlowyError> appsOrFail)? didReceiveApps,
    required TResult orElse(),
  }) {
    if (didReceiveApps != null) {
      return didReceiveApps(appsOrFail);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Collapse value) collapse,
    required TResult Function(_OpenPage value) openPage,
    required TResult Function(_CreateApp value) createApp,
    required TResult Function(_MoveApp value) moveApp,
    required TResult Function(_ReceiveApps value) didReceiveApps,
  }) {
    return didReceiveApps(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Collapse value)? collapse,
    TResult Function(_OpenPage value)? openPage,
    TResult Function(_CreateApp value)? createApp,
    TResult Function(_MoveApp value)? moveApp,
    TResult Function(_ReceiveApps value)? didReceiveApps,
  }) {
    return didReceiveApps?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Collapse value)? collapse,
    TResult Function(_OpenPage value)? openPage,
    TResult Function(_CreateApp value)? createApp,
    TResult Function(_MoveApp value)? moveApp,
    TResult Function(_ReceiveApps value)? didReceiveApps,
    required TResult orElse(),
  }) {
    if (didReceiveApps != null) {
      return didReceiveApps(this);
    }
    return orElse();
  }
}

abstract class _ReceiveApps implements MenuEvent {
  const factory _ReceiveApps(Either<List<App>, FlowyError> appsOrFail) =
      _$_ReceiveApps;

  Either<List<App>, FlowyError> get appsOrFail =>
      throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  _$ReceiveAppsCopyWith<_ReceiveApps> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
class _$MenuStateTearOff {
  const _$MenuStateTearOff();

  _MenuState call(
      {required bool isCollapse,
      required List<App> apps,
      required Either<Unit, FlowyError> successOrFailure,
      required Plugin plugin}) {
    return _MenuState(
      isCollapse: isCollapse,
      apps: apps,
      successOrFailure: successOrFailure,
      plugin: plugin,
    );
  }
}

/// @nodoc
const $MenuState = _$MenuStateTearOff();

/// @nodoc
mixin _$MenuState {
  bool get isCollapse => throw _privateConstructorUsedError;
  List<App> get apps => throw _privateConstructorUsedError;
  Either<Unit, FlowyError> get successOrFailure =>
      throw _privateConstructorUsedError;
  Plugin get plugin => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $MenuStateCopyWith<MenuState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MenuStateCopyWith<$Res> {
  factory $MenuStateCopyWith(MenuState value, $Res Function(MenuState) then) =
      _$MenuStateCopyWithImpl<$Res>;
  $Res call(
      {bool isCollapse,
      List<App> apps,
      Either<Unit, FlowyError> successOrFailure,
      Plugin plugin});
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
    Object? apps = freezed,
    Object? successOrFailure = freezed,
    Object? plugin = freezed,
  }) {
    return _then(_value.copyWith(
      isCollapse: isCollapse == freezed
          ? _value.isCollapse
          : isCollapse // ignore: cast_nullable_to_non_nullable
              as bool,
      apps: apps == freezed
          ? _value.apps
          : apps // ignore: cast_nullable_to_non_nullable
              as List<App>,
      successOrFailure: successOrFailure == freezed
          ? _value.successOrFailure
          : successOrFailure // ignore: cast_nullable_to_non_nullable
              as Either<Unit, FlowyError>,
      plugin: plugin == freezed
          ? _value.plugin
          : plugin // ignore: cast_nullable_to_non_nullable
              as Plugin,
    ));
  }
}

/// @nodoc
abstract class _$MenuStateCopyWith<$Res> implements $MenuStateCopyWith<$Res> {
  factory _$MenuStateCopyWith(
          _MenuState value, $Res Function(_MenuState) then) =
      __$MenuStateCopyWithImpl<$Res>;
  @override
  $Res call(
      {bool isCollapse,
      List<App> apps,
      Either<Unit, FlowyError> successOrFailure,
      Plugin plugin});
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
    Object? apps = freezed,
    Object? successOrFailure = freezed,
    Object? plugin = freezed,
  }) {
    return _then(_MenuState(
      isCollapse: isCollapse == freezed
          ? _value.isCollapse
          : isCollapse // ignore: cast_nullable_to_non_nullable
              as bool,
      apps: apps == freezed
          ? _value.apps
          : apps // ignore: cast_nullable_to_non_nullable
              as List<App>,
      successOrFailure: successOrFailure == freezed
          ? _value.successOrFailure
          : successOrFailure // ignore: cast_nullable_to_non_nullable
              as Either<Unit, FlowyError>,
      plugin: plugin == freezed
          ? _value.plugin
          : plugin // ignore: cast_nullable_to_non_nullable
              as Plugin,
    ));
  }
}

/// @nodoc

class _$_MenuState implements _MenuState {
  const _$_MenuState(
      {required this.isCollapse,
      required this.apps,
      required this.successOrFailure,
      required this.plugin});

  @override
  final bool isCollapse;
  @override
  final List<App> apps;
  @override
  final Either<Unit, FlowyError> successOrFailure;
  @override
  final Plugin plugin;

  @override
  String toString() {
    return 'MenuState(isCollapse: $isCollapse, apps: $apps, successOrFailure: $successOrFailure, plugin: $plugin)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _MenuState &&
            (identical(other.isCollapse, isCollapse) ||
                const DeepCollectionEquality()
                    .equals(other.isCollapse, isCollapse)) &&
            (identical(other.apps, apps) ||
                const DeepCollectionEquality().equals(other.apps, apps)) &&
            (identical(other.successOrFailure, successOrFailure) ||
                const DeepCollectionEquality()
                    .equals(other.successOrFailure, successOrFailure)) &&
            (identical(other.plugin, plugin) ||
                const DeepCollectionEquality().equals(other.plugin, plugin)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(isCollapse) ^
      const DeepCollectionEquality().hash(apps) ^
      const DeepCollectionEquality().hash(successOrFailure) ^
      const DeepCollectionEquality().hash(plugin);

  @JsonKey(ignore: true)
  @override
  _$MenuStateCopyWith<_MenuState> get copyWith =>
      __$MenuStateCopyWithImpl<_MenuState>(this, _$identity);
}

abstract class _MenuState implements MenuState {
  const factory _MenuState(
      {required bool isCollapse,
      required List<App> apps,
      required Either<Unit, FlowyError> successOrFailure,
      required Plugin plugin}) = _$_MenuState;

  @override
  bool get isCollapse => throw _privateConstructorUsedError;
  @override
  List<App> get apps => throw _privateConstructorUsedError;
  @override
  Either<Unit, FlowyError> get successOrFailure =>
      throw _privateConstructorUsedError;
  @override
  Plugin get plugin => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$MenuStateCopyWith<_MenuState> get copyWith =>
      throw _privateConstructorUsedError;
}
