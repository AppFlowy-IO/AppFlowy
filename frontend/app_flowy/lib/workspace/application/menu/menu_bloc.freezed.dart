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

  Collapse collapse() {
    return const Collapse();
  }

  OpenPage openPage(HomeStackContext<dynamic, dynamic> context) {
    return OpenPage(
      context,
    );
  }

  CreateApp createApp(String name, {String? desc}) {
    return CreateApp(
      name,
      desc: desc,
    );
  }

  ReceiveApps didReceiveApps(Either<List<App>, FlowyError> appsOrFail) {
    return ReceiveApps(
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
    required TResult Function(HomeStackContext<dynamic, dynamic> context)
        openPage,
    required TResult Function(String name, String? desc) createApp,
    required TResult Function(Either<List<App>, FlowyError> appsOrFail)
        didReceiveApps,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? collapse,
    TResult Function(HomeStackContext<dynamic, dynamic> context)? openPage,
    TResult Function(String name, String? desc)? createApp,
    TResult Function(Either<List<App>, FlowyError> appsOrFail)? didReceiveApps,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? collapse,
    TResult Function(HomeStackContext<dynamic, dynamic> context)? openPage,
    TResult Function(String name, String? desc)? createApp,
    TResult Function(Either<List<App>, FlowyError> appsOrFail)? didReceiveApps,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(Collapse value) collapse,
    required TResult Function(OpenPage value) openPage,
    required TResult Function(CreateApp value) createApp,
    required TResult Function(ReceiveApps value) didReceiveApps,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(Collapse value)? collapse,
    TResult Function(OpenPage value)? openPage,
    TResult Function(CreateApp value)? createApp,
    TResult Function(ReceiveApps value)? didReceiveApps,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(Collapse value)? collapse,
    TResult Function(OpenPage value)? openPage,
    TResult Function(CreateApp value)? createApp,
    TResult Function(ReceiveApps value)? didReceiveApps,
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
    required TResult Function(HomeStackContext<dynamic, dynamic> context)
        openPage,
    required TResult Function(String name, String? desc) createApp,
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
    TResult Function(HomeStackContext<dynamic, dynamic> context)? openPage,
    TResult Function(String name, String? desc)? createApp,
    TResult Function(Either<List<App>, FlowyError> appsOrFail)? didReceiveApps,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? collapse,
    TResult Function(HomeStackContext<dynamic, dynamic> context)? openPage,
    TResult Function(String name, String? desc)? createApp,
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
    required TResult Function(Collapse value) collapse,
    required TResult Function(OpenPage value) openPage,
    required TResult Function(CreateApp value) createApp,
    required TResult Function(ReceiveApps value) didReceiveApps,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(Collapse value)? collapse,
    TResult Function(OpenPage value)? openPage,
    TResult Function(CreateApp value)? createApp,
    TResult Function(ReceiveApps value)? didReceiveApps,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(Collapse value)? collapse,
    TResult Function(OpenPage value)? openPage,
    TResult Function(CreateApp value)? createApp,
    TResult Function(ReceiveApps value)? didReceiveApps,
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
    required TResult Function() initial,
    required TResult Function() collapse,
    required TResult Function(HomeStackContext<dynamic, dynamic> context)
        openPage,
    required TResult Function(String name, String? desc) createApp,
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
    TResult Function(HomeStackContext<dynamic, dynamic> context)? openPage,
    TResult Function(String name, String? desc)? createApp,
    TResult Function(Either<List<App>, FlowyError> appsOrFail)? didReceiveApps,
  }) {
    return collapse?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? collapse,
    TResult Function(HomeStackContext<dynamic, dynamic> context)? openPage,
    TResult Function(String name, String? desc)? createApp,
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
    required TResult Function(Collapse value) collapse,
    required TResult Function(OpenPage value) openPage,
    required TResult Function(CreateApp value) createApp,
    required TResult Function(ReceiveApps value) didReceiveApps,
  }) {
    return collapse(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(Collapse value)? collapse,
    TResult Function(OpenPage value)? openPage,
    TResult Function(CreateApp value)? createApp,
    TResult Function(ReceiveApps value)? didReceiveApps,
  }) {
    return collapse?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(Collapse value)? collapse,
    TResult Function(OpenPage value)? openPage,
    TResult Function(CreateApp value)? createApp,
    TResult Function(ReceiveApps value)? didReceiveApps,
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
abstract class $OpenPageCopyWith<$Res> {
  factory $OpenPageCopyWith(OpenPage value, $Res Function(OpenPage) then) =
      _$OpenPageCopyWithImpl<$Res>;
  $Res call({HomeStackContext<dynamic, dynamic> context});
}

/// @nodoc
class _$OpenPageCopyWithImpl<$Res> extends _$MenuEventCopyWithImpl<$Res>
    implements $OpenPageCopyWith<$Res> {
  _$OpenPageCopyWithImpl(OpenPage _value, $Res Function(OpenPage) _then)
      : super(_value, (v) => _then(v as OpenPage));

  @override
  OpenPage get _value => super._value as OpenPage;

  @override
  $Res call({
    Object? context = freezed,
  }) {
    return _then(OpenPage(
      context == freezed
          ? _value.context
          : context // ignore: cast_nullable_to_non_nullable
              as HomeStackContext<dynamic, dynamic>,
    ));
  }
}

/// @nodoc

class _$OpenPage implements OpenPage {
  const _$OpenPage(this.context);

  @override
  final HomeStackContext<dynamic, dynamic> context;

  @override
  String toString() {
    return 'MenuEvent.openPage(context: $context)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is OpenPage &&
            (identical(other.context, context) ||
                const DeepCollectionEquality().equals(other.context, context)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(context);

  @JsonKey(ignore: true)
  @override
  $OpenPageCopyWith<OpenPage> get copyWith =>
      _$OpenPageCopyWithImpl<OpenPage>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() collapse,
    required TResult Function(HomeStackContext<dynamic, dynamic> context)
        openPage,
    required TResult Function(String name, String? desc) createApp,
    required TResult Function(Either<List<App>, FlowyError> appsOrFail)
        didReceiveApps,
  }) {
    return openPage(context);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? collapse,
    TResult Function(HomeStackContext<dynamic, dynamic> context)? openPage,
    TResult Function(String name, String? desc)? createApp,
    TResult Function(Either<List<App>, FlowyError> appsOrFail)? didReceiveApps,
  }) {
    return openPage?.call(context);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? collapse,
    TResult Function(HomeStackContext<dynamic, dynamic> context)? openPage,
    TResult Function(String name, String? desc)? createApp,
    TResult Function(Either<List<App>, FlowyError> appsOrFail)? didReceiveApps,
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
    required TResult Function(_Initial value) initial,
    required TResult Function(Collapse value) collapse,
    required TResult Function(OpenPage value) openPage,
    required TResult Function(CreateApp value) createApp,
    required TResult Function(ReceiveApps value) didReceiveApps,
  }) {
    return openPage(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(Collapse value)? collapse,
    TResult Function(OpenPage value)? openPage,
    TResult Function(CreateApp value)? createApp,
    TResult Function(ReceiveApps value)? didReceiveApps,
  }) {
    return openPage?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(Collapse value)? collapse,
    TResult Function(OpenPage value)? openPage,
    TResult Function(CreateApp value)? createApp,
    TResult Function(ReceiveApps value)? didReceiveApps,
    required TResult orElse(),
  }) {
    if (openPage != null) {
      return openPage(this);
    }
    return orElse();
  }
}

abstract class OpenPage implements MenuEvent {
  const factory OpenPage(HomeStackContext<dynamic, dynamic> context) =
      _$OpenPage;

  HomeStackContext<dynamic, dynamic> get context =>
      throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $OpenPageCopyWith<OpenPage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateAppCopyWith<$Res> {
  factory $CreateAppCopyWith(CreateApp value, $Res Function(CreateApp) then) =
      _$CreateAppCopyWithImpl<$Res>;
  $Res call({String name, String? desc});
}

/// @nodoc
class _$CreateAppCopyWithImpl<$Res> extends _$MenuEventCopyWithImpl<$Res>
    implements $CreateAppCopyWith<$Res> {
  _$CreateAppCopyWithImpl(CreateApp _value, $Res Function(CreateApp) _then)
      : super(_value, (v) => _then(v as CreateApp));

  @override
  CreateApp get _value => super._value as CreateApp;

  @override
  $Res call({
    Object? name = freezed,
    Object? desc = freezed,
  }) {
    return _then(CreateApp(
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

class _$CreateApp implements CreateApp {
  const _$CreateApp(this.name, {this.desc});

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
        (other is CreateApp &&
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
  $CreateAppCopyWith<CreateApp> get copyWith =>
      _$CreateAppCopyWithImpl<CreateApp>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() collapse,
    required TResult Function(HomeStackContext<dynamic, dynamic> context)
        openPage,
    required TResult Function(String name, String? desc) createApp,
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
    TResult Function(HomeStackContext<dynamic, dynamic> context)? openPage,
    TResult Function(String name, String? desc)? createApp,
    TResult Function(Either<List<App>, FlowyError> appsOrFail)? didReceiveApps,
  }) {
    return createApp?.call(name, desc);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? collapse,
    TResult Function(HomeStackContext<dynamic, dynamic> context)? openPage,
    TResult Function(String name, String? desc)? createApp,
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
    required TResult Function(Collapse value) collapse,
    required TResult Function(OpenPage value) openPage,
    required TResult Function(CreateApp value) createApp,
    required TResult Function(ReceiveApps value) didReceiveApps,
  }) {
    return createApp(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(Collapse value)? collapse,
    TResult Function(OpenPage value)? openPage,
    TResult Function(CreateApp value)? createApp,
    TResult Function(ReceiveApps value)? didReceiveApps,
  }) {
    return createApp?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(Collapse value)? collapse,
    TResult Function(OpenPage value)? openPage,
    TResult Function(CreateApp value)? createApp,
    TResult Function(ReceiveApps value)? didReceiveApps,
    required TResult orElse(),
  }) {
    if (createApp != null) {
      return createApp(this);
    }
    return orElse();
  }
}

abstract class CreateApp implements MenuEvent {
  const factory CreateApp(String name, {String? desc}) = _$CreateApp;

  String get name => throw _privateConstructorUsedError;
  String? get desc => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CreateAppCopyWith<CreateApp> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReceiveAppsCopyWith<$Res> {
  factory $ReceiveAppsCopyWith(
          ReceiveApps value, $Res Function(ReceiveApps) then) =
      _$ReceiveAppsCopyWithImpl<$Res>;
  $Res call({Either<List<App>, FlowyError> appsOrFail});
}

/// @nodoc
class _$ReceiveAppsCopyWithImpl<$Res> extends _$MenuEventCopyWithImpl<$Res>
    implements $ReceiveAppsCopyWith<$Res> {
  _$ReceiveAppsCopyWithImpl(
      ReceiveApps _value, $Res Function(ReceiveApps) _then)
      : super(_value, (v) => _then(v as ReceiveApps));

  @override
  ReceiveApps get _value => super._value as ReceiveApps;

  @override
  $Res call({
    Object? appsOrFail = freezed,
  }) {
    return _then(ReceiveApps(
      appsOrFail == freezed
          ? _value.appsOrFail
          : appsOrFail // ignore: cast_nullable_to_non_nullable
              as Either<List<App>, FlowyError>,
    ));
  }
}

/// @nodoc

class _$ReceiveApps implements ReceiveApps {
  const _$ReceiveApps(this.appsOrFail);

  @override
  final Either<List<App>, FlowyError> appsOrFail;

  @override
  String toString() {
    return 'MenuEvent.didReceiveApps(appsOrFail: $appsOrFail)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is ReceiveApps &&
            (identical(other.appsOrFail, appsOrFail) ||
                const DeepCollectionEquality()
                    .equals(other.appsOrFail, appsOrFail)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(appsOrFail);

  @JsonKey(ignore: true)
  @override
  $ReceiveAppsCopyWith<ReceiveApps> get copyWith =>
      _$ReceiveAppsCopyWithImpl<ReceiveApps>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() collapse,
    required TResult Function(HomeStackContext<dynamic, dynamic> context)
        openPage,
    required TResult Function(String name, String? desc) createApp,
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
    TResult Function(HomeStackContext<dynamic, dynamic> context)? openPage,
    TResult Function(String name, String? desc)? createApp,
    TResult Function(Either<List<App>, FlowyError> appsOrFail)? didReceiveApps,
  }) {
    return didReceiveApps?.call(appsOrFail);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? collapse,
    TResult Function(HomeStackContext<dynamic, dynamic> context)? openPage,
    TResult Function(String name, String? desc)? createApp,
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
    required TResult Function(Collapse value) collapse,
    required TResult Function(OpenPage value) openPage,
    required TResult Function(CreateApp value) createApp,
    required TResult Function(ReceiveApps value) didReceiveApps,
  }) {
    return didReceiveApps(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(Collapse value)? collapse,
    TResult Function(OpenPage value)? openPage,
    TResult Function(CreateApp value)? createApp,
    TResult Function(ReceiveApps value)? didReceiveApps,
  }) {
    return didReceiveApps?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(Collapse value)? collapse,
    TResult Function(OpenPage value)? openPage,
    TResult Function(CreateApp value)? createApp,
    TResult Function(ReceiveApps value)? didReceiveApps,
    required TResult orElse(),
  }) {
    if (didReceiveApps != null) {
      return didReceiveApps(this);
    }
    return orElse();
  }
}

abstract class ReceiveApps implements MenuEvent {
  const factory ReceiveApps(Either<List<App>, FlowyError> appsOrFail) =
      _$ReceiveApps;

  Either<List<App>, FlowyError> get appsOrFail =>
      throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ReceiveAppsCopyWith<ReceiveApps> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
class _$MenuStateTearOff {
  const _$MenuStateTearOff();

  _MenuState call(
      {required bool isCollapse,
      required Option<List<App>> apps,
      required Either<Unit, FlowyError> successOrFailure,
      required HomeStackContext<dynamic, dynamic> stackContext}) {
    return _MenuState(
      isCollapse: isCollapse,
      apps: apps,
      successOrFailure: successOrFailure,
      stackContext: stackContext,
    );
  }
}

/// @nodoc
const $MenuState = _$MenuStateTearOff();

/// @nodoc
mixin _$MenuState {
  bool get isCollapse => throw _privateConstructorUsedError;
  Option<List<App>> get apps => throw _privateConstructorUsedError;
  Either<Unit, FlowyError> get successOrFailure =>
      throw _privateConstructorUsedError;
  HomeStackContext<dynamic, dynamic> get stackContext =>
      throw _privateConstructorUsedError;

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
      Option<List<App>> apps,
      Either<Unit, FlowyError> successOrFailure,
      HomeStackContext<dynamic, dynamic> stackContext});
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
    Object? stackContext = freezed,
  }) {
    return _then(_value.copyWith(
      isCollapse: isCollapse == freezed
          ? _value.isCollapse
          : isCollapse // ignore: cast_nullable_to_non_nullable
              as bool,
      apps: apps == freezed
          ? _value.apps
          : apps // ignore: cast_nullable_to_non_nullable
              as Option<List<App>>,
      successOrFailure: successOrFailure == freezed
          ? _value.successOrFailure
          : successOrFailure // ignore: cast_nullable_to_non_nullable
              as Either<Unit, FlowyError>,
      stackContext: stackContext == freezed
          ? _value.stackContext
          : stackContext // ignore: cast_nullable_to_non_nullable
              as HomeStackContext<dynamic, dynamic>,
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
      Option<List<App>> apps,
      Either<Unit, FlowyError> successOrFailure,
      HomeStackContext<dynamic, dynamic> stackContext});
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
    Object? stackContext = freezed,
  }) {
    return _then(_MenuState(
      isCollapse: isCollapse == freezed
          ? _value.isCollapse
          : isCollapse // ignore: cast_nullable_to_non_nullable
              as bool,
      apps: apps == freezed
          ? _value.apps
          : apps // ignore: cast_nullable_to_non_nullable
              as Option<List<App>>,
      successOrFailure: successOrFailure == freezed
          ? _value.successOrFailure
          : successOrFailure // ignore: cast_nullable_to_non_nullable
              as Either<Unit, FlowyError>,
      stackContext: stackContext == freezed
          ? _value.stackContext
          : stackContext // ignore: cast_nullable_to_non_nullable
              as HomeStackContext<dynamic, dynamic>,
    ));
  }
}

/// @nodoc

class _$_MenuState implements _MenuState {
  const _$_MenuState(
      {required this.isCollapse,
      required this.apps,
      required this.successOrFailure,
      required this.stackContext});

  @override
  final bool isCollapse;
  @override
  final Option<List<App>> apps;
  @override
  final Either<Unit, FlowyError> successOrFailure;
  @override
  final HomeStackContext<dynamic, dynamic> stackContext;

  @override
  String toString() {
    return 'MenuState(isCollapse: $isCollapse, apps: $apps, successOrFailure: $successOrFailure, stackContext: $stackContext)';
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
            (identical(other.stackContext, stackContext) ||
                const DeepCollectionEquality()
                    .equals(other.stackContext, stackContext)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(isCollapse) ^
      const DeepCollectionEquality().hash(apps) ^
      const DeepCollectionEquality().hash(successOrFailure) ^
      const DeepCollectionEquality().hash(stackContext);

  @JsonKey(ignore: true)
  @override
  _$MenuStateCopyWith<_MenuState> get copyWith =>
      __$MenuStateCopyWithImpl<_MenuState>(this, _$identity);
}

abstract class _MenuState implements MenuState {
  const factory _MenuState(
      {required bool isCollapse,
      required Option<List<App>> apps,
      required Either<Unit, FlowyError> successOrFailure,
      required HomeStackContext<dynamic, dynamic> stackContext}) = _$_MenuState;

  @override
  bool get isCollapse => throw _privateConstructorUsedError;
  @override
  Option<List<App>> get apps => throw _privateConstructorUsedError;
  @override
  Either<Unit, FlowyError> get successOrFailure =>
      throw _privateConstructorUsedError;
  @override
  HomeStackContext<dynamic, dynamic> get stackContext =>
      throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$MenuStateCopyWith<_MenuState> get copyWith =>
      throw _privateConstructorUsedError;
}
