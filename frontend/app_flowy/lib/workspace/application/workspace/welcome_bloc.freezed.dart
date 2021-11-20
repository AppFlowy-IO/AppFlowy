// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'welcome_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
class _$WelcomeEventTearOff {
  const _$WelcomeEventTearOff();

  Initial initial() {
    return const Initial();
  }

  CreateWorkspace createWorkspace(String name, String desc) {
    return CreateWorkspace(
      name,
      desc,
    );
  }

  OpenWorkspace openWorkspace(Workspace workspace) {
    return OpenWorkspace(
      workspace,
    );
  }

  WorkspacesReceived workspacesReveived(
      Either<List<Workspace>, WorkspaceError> workspacesOrFail) {
    return WorkspacesReceived(
      workspacesOrFail,
    );
  }
}

/// @nodoc
const $WelcomeEvent = _$WelcomeEventTearOff();

/// @nodoc
mixin _$WelcomeEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(String name, String desc) createWorkspace,
    required TResult Function(Workspace workspace) openWorkspace,
    required TResult Function(
            Either<List<Workspace>, WorkspaceError> workspacesOrFail)
        workspacesReveived,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String name, String desc)? createWorkspace,
    TResult Function(Workspace workspace)? openWorkspace,
    TResult Function(Either<List<Workspace>, WorkspaceError> workspacesOrFail)?
        workspacesReveived,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String name, String desc)? createWorkspace,
    TResult Function(Workspace workspace)? openWorkspace,
    TResult Function(Either<List<Workspace>, WorkspaceError> workspacesOrFail)?
        workspacesReveived,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(CreateWorkspace value) createWorkspace,
    required TResult Function(OpenWorkspace value) openWorkspace,
    required TResult Function(WorkspacesReceived value) workspacesReveived,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(CreateWorkspace value)? createWorkspace,
    TResult Function(OpenWorkspace value)? openWorkspace,
    TResult Function(WorkspacesReceived value)? workspacesReveived,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(CreateWorkspace value)? createWorkspace,
    TResult Function(OpenWorkspace value)? openWorkspace,
    TResult Function(WorkspacesReceived value)? workspacesReveived,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WelcomeEventCopyWith<$Res> {
  factory $WelcomeEventCopyWith(
          WelcomeEvent value, $Res Function(WelcomeEvent) then) =
      _$WelcomeEventCopyWithImpl<$Res>;
}

/// @nodoc
class _$WelcomeEventCopyWithImpl<$Res> implements $WelcomeEventCopyWith<$Res> {
  _$WelcomeEventCopyWithImpl(this._value, this._then);

  final WelcomeEvent _value;
  // ignore: unused_field
  final $Res Function(WelcomeEvent) _then;
}

/// @nodoc
abstract class $InitialCopyWith<$Res> {
  factory $InitialCopyWith(Initial value, $Res Function(Initial) then) =
      _$InitialCopyWithImpl<$Res>;
}

/// @nodoc
class _$InitialCopyWithImpl<$Res> extends _$WelcomeEventCopyWithImpl<$Res>
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
    return 'WelcomeEvent.initial()';
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
    required TResult Function(String name, String desc) createWorkspace,
    required TResult Function(Workspace workspace) openWorkspace,
    required TResult Function(
            Either<List<Workspace>, WorkspaceError> workspacesOrFail)
        workspacesReveived,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String name, String desc)? createWorkspace,
    TResult Function(Workspace workspace)? openWorkspace,
    TResult Function(Either<List<Workspace>, WorkspaceError> workspacesOrFail)?
        workspacesReveived,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String name, String desc)? createWorkspace,
    TResult Function(Workspace workspace)? openWorkspace,
    TResult Function(Either<List<Workspace>, WorkspaceError> workspacesOrFail)?
        workspacesReveived,
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
    required TResult Function(CreateWorkspace value) createWorkspace,
    required TResult Function(OpenWorkspace value) openWorkspace,
    required TResult Function(WorkspacesReceived value) workspacesReveived,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(CreateWorkspace value)? createWorkspace,
    TResult Function(OpenWorkspace value)? openWorkspace,
    TResult Function(WorkspacesReceived value)? workspacesReveived,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(CreateWorkspace value)? createWorkspace,
    TResult Function(OpenWorkspace value)? openWorkspace,
    TResult Function(WorkspacesReceived value)? workspacesReveived,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class Initial implements WelcomeEvent {
  const factory Initial() = _$Initial;
}

/// @nodoc
abstract class $CreateWorkspaceCopyWith<$Res> {
  factory $CreateWorkspaceCopyWith(
          CreateWorkspace value, $Res Function(CreateWorkspace) then) =
      _$CreateWorkspaceCopyWithImpl<$Res>;
  $Res call({String name, String desc});
}

/// @nodoc
class _$CreateWorkspaceCopyWithImpl<$Res>
    extends _$WelcomeEventCopyWithImpl<$Res>
    implements $CreateWorkspaceCopyWith<$Res> {
  _$CreateWorkspaceCopyWithImpl(
      CreateWorkspace _value, $Res Function(CreateWorkspace) _then)
      : super(_value, (v) => _then(v as CreateWorkspace));

  @override
  CreateWorkspace get _value => super._value as CreateWorkspace;

  @override
  $Res call({
    Object? name = freezed,
    Object? desc = freezed,
  }) {
    return _then(CreateWorkspace(
      name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      desc == freezed
          ? _value.desc
          : desc // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$CreateWorkspace implements CreateWorkspace {
  const _$CreateWorkspace(this.name, this.desc);

  @override
  final String name;
  @override
  final String desc;

  @override
  String toString() {
    return 'WelcomeEvent.createWorkspace(name: $name, desc: $desc)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is CreateWorkspace &&
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
  $CreateWorkspaceCopyWith<CreateWorkspace> get copyWith =>
      _$CreateWorkspaceCopyWithImpl<CreateWorkspace>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(String name, String desc) createWorkspace,
    required TResult Function(Workspace workspace) openWorkspace,
    required TResult Function(
            Either<List<Workspace>, WorkspaceError> workspacesOrFail)
        workspacesReveived,
  }) {
    return createWorkspace(name, desc);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String name, String desc)? createWorkspace,
    TResult Function(Workspace workspace)? openWorkspace,
    TResult Function(Either<List<Workspace>, WorkspaceError> workspacesOrFail)?
        workspacesReveived,
  }) {
    return createWorkspace?.call(name, desc);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String name, String desc)? createWorkspace,
    TResult Function(Workspace workspace)? openWorkspace,
    TResult Function(Either<List<Workspace>, WorkspaceError> workspacesOrFail)?
        workspacesReveived,
    required TResult orElse(),
  }) {
    if (createWorkspace != null) {
      return createWorkspace(name, desc);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(CreateWorkspace value) createWorkspace,
    required TResult Function(OpenWorkspace value) openWorkspace,
    required TResult Function(WorkspacesReceived value) workspacesReveived,
  }) {
    return createWorkspace(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(CreateWorkspace value)? createWorkspace,
    TResult Function(OpenWorkspace value)? openWorkspace,
    TResult Function(WorkspacesReceived value)? workspacesReveived,
  }) {
    return createWorkspace?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(CreateWorkspace value)? createWorkspace,
    TResult Function(OpenWorkspace value)? openWorkspace,
    TResult Function(WorkspacesReceived value)? workspacesReveived,
    required TResult orElse(),
  }) {
    if (createWorkspace != null) {
      return createWorkspace(this);
    }
    return orElse();
  }
}

abstract class CreateWorkspace implements WelcomeEvent {
  const factory CreateWorkspace(String name, String desc) = _$CreateWorkspace;

  String get name => throw _privateConstructorUsedError;
  String get desc => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CreateWorkspaceCopyWith<CreateWorkspace> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OpenWorkspaceCopyWith<$Res> {
  factory $OpenWorkspaceCopyWith(
          OpenWorkspace value, $Res Function(OpenWorkspace) then) =
      _$OpenWorkspaceCopyWithImpl<$Res>;
  $Res call({Workspace workspace});
}

/// @nodoc
class _$OpenWorkspaceCopyWithImpl<$Res> extends _$WelcomeEventCopyWithImpl<$Res>
    implements $OpenWorkspaceCopyWith<$Res> {
  _$OpenWorkspaceCopyWithImpl(
      OpenWorkspace _value, $Res Function(OpenWorkspace) _then)
      : super(_value, (v) => _then(v as OpenWorkspace));

  @override
  OpenWorkspace get _value => super._value as OpenWorkspace;

  @override
  $Res call({
    Object? workspace = freezed,
  }) {
    return _then(OpenWorkspace(
      workspace == freezed
          ? _value.workspace
          : workspace // ignore: cast_nullable_to_non_nullable
              as Workspace,
    ));
  }
}

/// @nodoc

class _$OpenWorkspace implements OpenWorkspace {
  const _$OpenWorkspace(this.workspace);

  @override
  final Workspace workspace;

  @override
  String toString() {
    return 'WelcomeEvent.openWorkspace(workspace: $workspace)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is OpenWorkspace &&
            (identical(other.workspace, workspace) ||
                const DeepCollectionEquality()
                    .equals(other.workspace, workspace)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(workspace);

  @JsonKey(ignore: true)
  @override
  $OpenWorkspaceCopyWith<OpenWorkspace> get copyWith =>
      _$OpenWorkspaceCopyWithImpl<OpenWorkspace>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(String name, String desc) createWorkspace,
    required TResult Function(Workspace workspace) openWorkspace,
    required TResult Function(
            Either<List<Workspace>, WorkspaceError> workspacesOrFail)
        workspacesReveived,
  }) {
    return openWorkspace(workspace);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String name, String desc)? createWorkspace,
    TResult Function(Workspace workspace)? openWorkspace,
    TResult Function(Either<List<Workspace>, WorkspaceError> workspacesOrFail)?
        workspacesReveived,
  }) {
    return openWorkspace?.call(workspace);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String name, String desc)? createWorkspace,
    TResult Function(Workspace workspace)? openWorkspace,
    TResult Function(Either<List<Workspace>, WorkspaceError> workspacesOrFail)?
        workspacesReveived,
    required TResult orElse(),
  }) {
    if (openWorkspace != null) {
      return openWorkspace(workspace);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(CreateWorkspace value) createWorkspace,
    required TResult Function(OpenWorkspace value) openWorkspace,
    required TResult Function(WorkspacesReceived value) workspacesReveived,
  }) {
    return openWorkspace(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(CreateWorkspace value)? createWorkspace,
    TResult Function(OpenWorkspace value)? openWorkspace,
    TResult Function(WorkspacesReceived value)? workspacesReveived,
  }) {
    return openWorkspace?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(CreateWorkspace value)? createWorkspace,
    TResult Function(OpenWorkspace value)? openWorkspace,
    TResult Function(WorkspacesReceived value)? workspacesReveived,
    required TResult orElse(),
  }) {
    if (openWorkspace != null) {
      return openWorkspace(this);
    }
    return orElse();
  }
}

abstract class OpenWorkspace implements WelcomeEvent {
  const factory OpenWorkspace(Workspace workspace) = _$OpenWorkspace;

  Workspace get workspace => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $OpenWorkspaceCopyWith<OpenWorkspace> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkspacesReceivedCopyWith<$Res> {
  factory $WorkspacesReceivedCopyWith(
          WorkspacesReceived value, $Res Function(WorkspacesReceived) then) =
      _$WorkspacesReceivedCopyWithImpl<$Res>;
  $Res call({Either<List<Workspace>, WorkspaceError> workspacesOrFail});
}

/// @nodoc
class _$WorkspacesReceivedCopyWithImpl<$Res>
    extends _$WelcomeEventCopyWithImpl<$Res>
    implements $WorkspacesReceivedCopyWith<$Res> {
  _$WorkspacesReceivedCopyWithImpl(
      WorkspacesReceived _value, $Res Function(WorkspacesReceived) _then)
      : super(_value, (v) => _then(v as WorkspacesReceived));

  @override
  WorkspacesReceived get _value => super._value as WorkspacesReceived;

  @override
  $Res call({
    Object? workspacesOrFail = freezed,
  }) {
    return _then(WorkspacesReceived(
      workspacesOrFail == freezed
          ? _value.workspacesOrFail
          : workspacesOrFail // ignore: cast_nullable_to_non_nullable
              as Either<List<Workspace>, WorkspaceError>,
    ));
  }
}

/// @nodoc

class _$WorkspacesReceived implements WorkspacesReceived {
  const _$WorkspacesReceived(this.workspacesOrFail);

  @override
  final Either<List<Workspace>, WorkspaceError> workspacesOrFail;

  @override
  String toString() {
    return 'WelcomeEvent.workspacesReveived(workspacesOrFail: $workspacesOrFail)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is WorkspacesReceived &&
            (identical(other.workspacesOrFail, workspacesOrFail) ||
                const DeepCollectionEquality()
                    .equals(other.workspacesOrFail, workspacesOrFail)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(workspacesOrFail);

  @JsonKey(ignore: true)
  @override
  $WorkspacesReceivedCopyWith<WorkspacesReceived> get copyWith =>
      _$WorkspacesReceivedCopyWithImpl<WorkspacesReceived>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(String name, String desc) createWorkspace,
    required TResult Function(Workspace workspace) openWorkspace,
    required TResult Function(
            Either<List<Workspace>, WorkspaceError> workspacesOrFail)
        workspacesReveived,
  }) {
    return workspacesReveived(workspacesOrFail);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String name, String desc)? createWorkspace,
    TResult Function(Workspace workspace)? openWorkspace,
    TResult Function(Either<List<Workspace>, WorkspaceError> workspacesOrFail)?
        workspacesReveived,
  }) {
    return workspacesReveived?.call(workspacesOrFail);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String name, String desc)? createWorkspace,
    TResult Function(Workspace workspace)? openWorkspace,
    TResult Function(Either<List<Workspace>, WorkspaceError> workspacesOrFail)?
        workspacesReveived,
    required TResult orElse(),
  }) {
    if (workspacesReveived != null) {
      return workspacesReveived(workspacesOrFail);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(CreateWorkspace value) createWorkspace,
    required TResult Function(OpenWorkspace value) openWorkspace,
    required TResult Function(WorkspacesReceived value) workspacesReveived,
  }) {
    return workspacesReveived(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(CreateWorkspace value)? createWorkspace,
    TResult Function(OpenWorkspace value)? openWorkspace,
    TResult Function(WorkspacesReceived value)? workspacesReveived,
  }) {
    return workspacesReveived?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(CreateWorkspace value)? createWorkspace,
    TResult Function(OpenWorkspace value)? openWorkspace,
    TResult Function(WorkspacesReceived value)? workspacesReveived,
    required TResult orElse(),
  }) {
    if (workspacesReveived != null) {
      return workspacesReveived(this);
    }
    return orElse();
  }
}

abstract class WorkspacesReceived implements WelcomeEvent {
  const factory WorkspacesReceived(
          Either<List<Workspace>, WorkspaceError> workspacesOrFail) =
      _$WorkspacesReceived;

  Either<List<Workspace>, WorkspaceError> get workspacesOrFail =>
      throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkspacesReceivedCopyWith<WorkspacesReceived> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
class _$WelcomeStateTearOff {
  const _$WelcomeStateTearOff();

  _WelcomeState call(
      {required bool isLoading,
      required List<Workspace> workspaces,
      required Either<Unit, WorkspaceError> successOrFailure}) {
    return _WelcomeState(
      isLoading: isLoading,
      workspaces: workspaces,
      successOrFailure: successOrFailure,
    );
  }
}

/// @nodoc
const $WelcomeState = _$WelcomeStateTearOff();

/// @nodoc
mixin _$WelcomeState {
  bool get isLoading => throw _privateConstructorUsedError;
  List<Workspace> get workspaces => throw _privateConstructorUsedError;
  Either<Unit, WorkspaceError> get successOrFailure =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $WelcomeStateCopyWith<WelcomeState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WelcomeStateCopyWith<$Res> {
  factory $WelcomeStateCopyWith(
          WelcomeState value, $Res Function(WelcomeState) then) =
      _$WelcomeStateCopyWithImpl<$Res>;
  $Res call(
      {bool isLoading,
      List<Workspace> workspaces,
      Either<Unit, WorkspaceError> successOrFailure});
}

/// @nodoc
class _$WelcomeStateCopyWithImpl<$Res> implements $WelcomeStateCopyWith<$Res> {
  _$WelcomeStateCopyWithImpl(this._value, this._then);

  final WelcomeState _value;
  // ignore: unused_field
  final $Res Function(WelcomeState) _then;

  @override
  $Res call({
    Object? isLoading = freezed,
    Object? workspaces = freezed,
    Object? successOrFailure = freezed,
  }) {
    return _then(_value.copyWith(
      isLoading: isLoading == freezed
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      workspaces: workspaces == freezed
          ? _value.workspaces
          : workspaces // ignore: cast_nullable_to_non_nullable
              as List<Workspace>,
      successOrFailure: successOrFailure == freezed
          ? _value.successOrFailure
          : successOrFailure // ignore: cast_nullable_to_non_nullable
              as Either<Unit, WorkspaceError>,
    ));
  }
}

/// @nodoc
abstract class _$WelcomeStateCopyWith<$Res>
    implements $WelcomeStateCopyWith<$Res> {
  factory _$WelcomeStateCopyWith(
          _WelcomeState value, $Res Function(_WelcomeState) then) =
      __$WelcomeStateCopyWithImpl<$Res>;
  @override
  $Res call(
      {bool isLoading,
      List<Workspace> workspaces,
      Either<Unit, WorkspaceError> successOrFailure});
}

/// @nodoc
class __$WelcomeStateCopyWithImpl<$Res> extends _$WelcomeStateCopyWithImpl<$Res>
    implements _$WelcomeStateCopyWith<$Res> {
  __$WelcomeStateCopyWithImpl(
      _WelcomeState _value, $Res Function(_WelcomeState) _then)
      : super(_value, (v) => _then(v as _WelcomeState));

  @override
  _WelcomeState get _value => super._value as _WelcomeState;

  @override
  $Res call({
    Object? isLoading = freezed,
    Object? workspaces = freezed,
    Object? successOrFailure = freezed,
  }) {
    return _then(_WelcomeState(
      isLoading: isLoading == freezed
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      workspaces: workspaces == freezed
          ? _value.workspaces
          : workspaces // ignore: cast_nullable_to_non_nullable
              as List<Workspace>,
      successOrFailure: successOrFailure == freezed
          ? _value.successOrFailure
          : successOrFailure // ignore: cast_nullable_to_non_nullable
              as Either<Unit, WorkspaceError>,
    ));
  }
}

/// @nodoc

class _$_WelcomeState implements _WelcomeState {
  const _$_WelcomeState(
      {required this.isLoading,
      required this.workspaces,
      required this.successOrFailure});

  @override
  final bool isLoading;
  @override
  final List<Workspace> workspaces;
  @override
  final Either<Unit, WorkspaceError> successOrFailure;

  @override
  String toString() {
    return 'WelcomeState(isLoading: $isLoading, workspaces: $workspaces, successOrFailure: $successOrFailure)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _WelcomeState &&
            (identical(other.isLoading, isLoading) ||
                const DeepCollectionEquality()
                    .equals(other.isLoading, isLoading)) &&
            (identical(other.workspaces, workspaces) ||
                const DeepCollectionEquality()
                    .equals(other.workspaces, workspaces)) &&
            (identical(other.successOrFailure, successOrFailure) ||
                const DeepCollectionEquality()
                    .equals(other.successOrFailure, successOrFailure)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(isLoading) ^
      const DeepCollectionEquality().hash(workspaces) ^
      const DeepCollectionEquality().hash(successOrFailure);

  @JsonKey(ignore: true)
  @override
  _$WelcomeStateCopyWith<_WelcomeState> get copyWith =>
      __$WelcomeStateCopyWithImpl<_WelcomeState>(this, _$identity);
}

abstract class _WelcomeState implements WelcomeState {
  const factory _WelcomeState(
          {required bool isLoading,
          required List<Workspace> workspaces,
          required Either<Unit, WorkspaceError> successOrFailure}) =
      _$_WelcomeState;

  @override
  bool get isLoading => throw _privateConstructorUsedError;
  @override
  List<Workspace> get workspaces => throw _privateConstructorUsedError;
  @override
  Either<Unit, WorkspaceError> get successOrFailure =>
      throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$WelcomeStateCopyWith<_WelcomeState> get copyWith =>
      throw _privateConstructorUsedError;
}
