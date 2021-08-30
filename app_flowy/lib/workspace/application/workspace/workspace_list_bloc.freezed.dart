// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'workspace_list_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
class _$WorkspaceListEventTearOff {
  const _$WorkspaceListEventTearOff();

  Initial initial() {
    return const Initial();
  }

  FetchWorkspace fetchWorkspaces() {
    return const FetchWorkspace();
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
}

/// @nodoc
const $WorkspaceListEvent = _$WorkspaceListEventTearOff();

/// @nodoc
mixin _$WorkspaceListEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() fetchWorkspaces,
    required TResult Function(String name, String desc) createWorkspace,
    required TResult Function(Workspace workspace) openWorkspace,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? fetchWorkspaces,
    TResult Function(String name, String desc)? createWorkspace,
    TResult Function(Workspace workspace)? openWorkspace,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(FetchWorkspace value) fetchWorkspaces,
    required TResult Function(CreateWorkspace value) createWorkspace,
    required TResult Function(OpenWorkspace value) openWorkspace,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(FetchWorkspace value)? fetchWorkspaces,
    TResult Function(CreateWorkspace value)? createWorkspace,
    TResult Function(OpenWorkspace value)? openWorkspace,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkspaceListEventCopyWith<$Res> {
  factory $WorkspaceListEventCopyWith(
          WorkspaceListEvent value, $Res Function(WorkspaceListEvent) then) =
      _$WorkspaceListEventCopyWithImpl<$Res>;
}

/// @nodoc
class _$WorkspaceListEventCopyWithImpl<$Res>
    implements $WorkspaceListEventCopyWith<$Res> {
  _$WorkspaceListEventCopyWithImpl(this._value, this._then);

  final WorkspaceListEvent _value;
  // ignore: unused_field
  final $Res Function(WorkspaceListEvent) _then;
}

/// @nodoc
abstract class $InitialCopyWith<$Res> {
  factory $InitialCopyWith(Initial value, $Res Function(Initial) then) =
      _$InitialCopyWithImpl<$Res>;
}

/// @nodoc
class _$InitialCopyWithImpl<$Res> extends _$WorkspaceListEventCopyWithImpl<$Res>
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
    return 'WorkspaceListEvent.initial()';
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
    required TResult Function() fetchWorkspaces,
    required TResult Function(String name, String desc) createWorkspace,
    required TResult Function(Workspace workspace) openWorkspace,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? fetchWorkspaces,
    TResult Function(String name, String desc)? createWorkspace,
    TResult Function(Workspace workspace)? openWorkspace,
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
    required TResult Function(FetchWorkspace value) fetchWorkspaces,
    required TResult Function(CreateWorkspace value) createWorkspace,
    required TResult Function(OpenWorkspace value) openWorkspace,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(FetchWorkspace value)? fetchWorkspaces,
    TResult Function(CreateWorkspace value)? createWorkspace,
    TResult Function(OpenWorkspace value)? openWorkspace,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class Initial implements WorkspaceListEvent {
  const factory Initial() = _$Initial;
}

/// @nodoc
abstract class $FetchWorkspaceCopyWith<$Res> {
  factory $FetchWorkspaceCopyWith(
          FetchWorkspace value, $Res Function(FetchWorkspace) then) =
      _$FetchWorkspaceCopyWithImpl<$Res>;
}

/// @nodoc
class _$FetchWorkspaceCopyWithImpl<$Res>
    extends _$WorkspaceListEventCopyWithImpl<$Res>
    implements $FetchWorkspaceCopyWith<$Res> {
  _$FetchWorkspaceCopyWithImpl(
      FetchWorkspace _value, $Res Function(FetchWorkspace) _then)
      : super(_value, (v) => _then(v as FetchWorkspace));

  @override
  FetchWorkspace get _value => super._value as FetchWorkspace;
}

/// @nodoc

class _$FetchWorkspace implements FetchWorkspace {
  const _$FetchWorkspace();

  @override
  String toString() {
    return 'WorkspaceListEvent.fetchWorkspaces()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) || (other is FetchWorkspace);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() fetchWorkspaces,
    required TResult Function(String name, String desc) createWorkspace,
    required TResult Function(Workspace workspace) openWorkspace,
  }) {
    return fetchWorkspaces();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? fetchWorkspaces,
    TResult Function(String name, String desc)? createWorkspace,
    TResult Function(Workspace workspace)? openWorkspace,
    required TResult orElse(),
  }) {
    if (fetchWorkspaces != null) {
      return fetchWorkspaces();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(FetchWorkspace value) fetchWorkspaces,
    required TResult Function(CreateWorkspace value) createWorkspace,
    required TResult Function(OpenWorkspace value) openWorkspace,
  }) {
    return fetchWorkspaces(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(FetchWorkspace value)? fetchWorkspaces,
    TResult Function(CreateWorkspace value)? createWorkspace,
    TResult Function(OpenWorkspace value)? openWorkspace,
    required TResult orElse(),
  }) {
    if (fetchWorkspaces != null) {
      return fetchWorkspaces(this);
    }
    return orElse();
  }
}

abstract class FetchWorkspace implements WorkspaceListEvent {
  const factory FetchWorkspace() = _$FetchWorkspace;
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
    extends _$WorkspaceListEventCopyWithImpl<$Res>
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
    return 'WorkspaceListEvent.createWorkspace(name: $name, desc: $desc)';
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
    required TResult Function() fetchWorkspaces,
    required TResult Function(String name, String desc) createWorkspace,
    required TResult Function(Workspace workspace) openWorkspace,
  }) {
    return createWorkspace(name, desc);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? fetchWorkspaces,
    TResult Function(String name, String desc)? createWorkspace,
    TResult Function(Workspace workspace)? openWorkspace,
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
    required TResult Function(FetchWorkspace value) fetchWorkspaces,
    required TResult Function(CreateWorkspace value) createWorkspace,
    required TResult Function(OpenWorkspace value) openWorkspace,
  }) {
    return createWorkspace(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(FetchWorkspace value)? fetchWorkspaces,
    TResult Function(CreateWorkspace value)? createWorkspace,
    TResult Function(OpenWorkspace value)? openWorkspace,
    required TResult orElse(),
  }) {
    if (createWorkspace != null) {
      return createWorkspace(this);
    }
    return orElse();
  }
}

abstract class CreateWorkspace implements WorkspaceListEvent {
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
class _$OpenWorkspaceCopyWithImpl<$Res>
    extends _$WorkspaceListEventCopyWithImpl<$Res>
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
    return 'WorkspaceListEvent.openWorkspace(workspace: $workspace)';
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
    required TResult Function() fetchWorkspaces,
    required TResult Function(String name, String desc) createWorkspace,
    required TResult Function(Workspace workspace) openWorkspace,
  }) {
    return openWorkspace(workspace);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? fetchWorkspaces,
    TResult Function(String name, String desc)? createWorkspace,
    TResult Function(Workspace workspace)? openWorkspace,
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
    required TResult Function(FetchWorkspace value) fetchWorkspaces,
    required TResult Function(CreateWorkspace value) createWorkspace,
    required TResult Function(OpenWorkspace value) openWorkspace,
  }) {
    return openWorkspace(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(FetchWorkspace value)? fetchWorkspaces,
    TResult Function(CreateWorkspace value)? createWorkspace,
    TResult Function(OpenWorkspace value)? openWorkspace,
    required TResult orElse(),
  }) {
    if (openWorkspace != null) {
      return openWorkspace(this);
    }
    return orElse();
  }
}

abstract class OpenWorkspace implements WorkspaceListEvent {
  const factory OpenWorkspace(Workspace workspace) = _$OpenWorkspace;

  Workspace get workspace => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $OpenWorkspaceCopyWith<OpenWorkspace> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
class _$WorkspaceListStateTearOff {
  const _$WorkspaceListStateTearOff();

  _WorkspaceListState call(
      {required bool isLoading,
      required List<Workspace> workspaces,
      required Either<Unit, WorkspaceError> successOrFailure}) {
    return _WorkspaceListState(
      isLoading: isLoading,
      workspaces: workspaces,
      successOrFailure: successOrFailure,
    );
  }
}

/// @nodoc
const $WorkspaceListState = _$WorkspaceListStateTearOff();

/// @nodoc
mixin _$WorkspaceListState {
  bool get isLoading => throw _privateConstructorUsedError;
  List<Workspace> get workspaces => throw _privateConstructorUsedError;
  Either<Unit, WorkspaceError> get successOrFailure =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $WorkspaceListStateCopyWith<WorkspaceListState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkspaceListStateCopyWith<$Res> {
  factory $WorkspaceListStateCopyWith(
          WorkspaceListState value, $Res Function(WorkspaceListState) then) =
      _$WorkspaceListStateCopyWithImpl<$Res>;
  $Res call(
      {bool isLoading,
      List<Workspace> workspaces,
      Either<Unit, WorkspaceError> successOrFailure});
}

/// @nodoc
class _$WorkspaceListStateCopyWithImpl<$Res>
    implements $WorkspaceListStateCopyWith<$Res> {
  _$WorkspaceListStateCopyWithImpl(this._value, this._then);

  final WorkspaceListState _value;
  // ignore: unused_field
  final $Res Function(WorkspaceListState) _then;

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
abstract class _$WorkspaceListStateCopyWith<$Res>
    implements $WorkspaceListStateCopyWith<$Res> {
  factory _$WorkspaceListStateCopyWith(
          _WorkspaceListState value, $Res Function(_WorkspaceListState) then) =
      __$WorkspaceListStateCopyWithImpl<$Res>;
  @override
  $Res call(
      {bool isLoading,
      List<Workspace> workspaces,
      Either<Unit, WorkspaceError> successOrFailure});
}

/// @nodoc
class __$WorkspaceListStateCopyWithImpl<$Res>
    extends _$WorkspaceListStateCopyWithImpl<$Res>
    implements _$WorkspaceListStateCopyWith<$Res> {
  __$WorkspaceListStateCopyWithImpl(
      _WorkspaceListState _value, $Res Function(_WorkspaceListState) _then)
      : super(_value, (v) => _then(v as _WorkspaceListState));

  @override
  _WorkspaceListState get _value => super._value as _WorkspaceListState;

  @override
  $Res call({
    Object? isLoading = freezed,
    Object? workspaces = freezed,
    Object? successOrFailure = freezed,
  }) {
    return _then(_WorkspaceListState(
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

class _$_WorkspaceListState implements _WorkspaceListState {
  const _$_WorkspaceListState(
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
    return 'WorkspaceListState(isLoading: $isLoading, workspaces: $workspaces, successOrFailure: $successOrFailure)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _WorkspaceListState &&
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
  _$WorkspaceListStateCopyWith<_WorkspaceListState> get copyWith =>
      __$WorkspaceListStateCopyWithImpl<_WorkspaceListState>(this, _$identity);
}

abstract class _WorkspaceListState implements WorkspaceListState {
  const factory _WorkspaceListState(
          {required bool isLoading,
          required List<Workspace> workspaces,
          required Either<Unit, WorkspaceError> successOrFailure}) =
      _$_WorkspaceListState;

  @override
  bool get isLoading => throw _privateConstructorUsedError;
  @override
  List<Workspace> get workspaces => throw _privateConstructorUsedError;
  @override
  Either<Unit, WorkspaceError> get successOrFailure =>
      throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$WorkspaceListStateCopyWith<_WorkspaceListState> get copyWith =>
      throw _privateConstructorUsedError;
}
