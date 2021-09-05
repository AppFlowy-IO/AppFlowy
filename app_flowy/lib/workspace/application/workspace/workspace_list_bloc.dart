import 'package:app_flowy/workspace/infrastructure/repos/user_repo.dart';
import 'package:flowy_infra/flowy_logger.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/workspace_create.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

part 'workspace_list_bloc.freezed.dart';

class WorkspaceListBloc extends Bloc<WorkspaceListEvent, WorkspaceListState> {
  UserRepo repo;
  WorkspaceListBloc(this.repo) : super(WorkspaceListState.initial());

  @override
  Stream<WorkspaceListState> mapEventToState(
    WorkspaceListEvent event,
  ) async* {
    yield* event.map(initial: (e) async* {
      yield* _fetchWorkspaces();
    }, openWorkspace: (e) async* {
      yield* _openWorkspace(e.workspace);
    }, createWorkspace: (e) async* {
      yield* _createWorkspace(e.name, e.desc);
    }, fetchWorkspaces: (e) async* {
      yield* _fetchWorkspaces();
    });
  }

  Stream<WorkspaceListState> _fetchWorkspaces() async* {
    final workspacesOrFailed = await repo.fetchWorkspaces();
    yield workspacesOrFailed.fold(
      (workspaces) =>
          state.copyWith(workspaces: workspaces, successOrFailure: left(unit)),
      (error) {
        Log.error(error);
        return state.copyWith(successOrFailure: right(error));
      },
    );
  }

  Stream<WorkspaceListState> _openWorkspace(Workspace workspace) async* {
    final result = await repo.openWorkspace(workspace.id);
    yield result.fold(
      (workspaces) => state.copyWith(successOrFailure: left(unit)),
      (error) {
        Log.error(error);
        return state.copyWith(successOrFailure: right(error));
      },
    );
  }

  Stream<WorkspaceListState> _createWorkspace(String name, String desc) async* {
    final result = await repo.createWorkspace(name, desc);
    yield result.fold(
      (workspace) {
        add(const WorkspaceListEvent.fetchWorkspaces());
        return state.copyWith(successOrFailure: left(unit));
      },
      (error) {
        Log.error(error);
        return state.copyWith(successOrFailure: right(error));
      },
    );
  }
}

@freezed
abstract class WorkspaceListEvent with _$WorkspaceListEvent {
  const factory WorkspaceListEvent.initial() = Initial;
  const factory WorkspaceListEvent.fetchWorkspaces() = FetchWorkspace;
  const factory WorkspaceListEvent.createWorkspace(String name, String desc) =
      CreateWorkspace;
  const factory WorkspaceListEvent.openWorkspace(Workspace workspace) =
      OpenWorkspace;
}

@freezed
abstract class WorkspaceListState implements _$WorkspaceListState {
  const factory WorkspaceListState({
    required bool isLoading,
    required List<Workspace> workspaces,
    required Either<Unit, WorkspaceError> successOrFailure,
  }) = _WorkspaceListState;

  factory WorkspaceListState.initial() => WorkspaceListState(
        isLoading: false,
        workspaces: List.empty(),
        successOrFailure: left(unit),
      );
}
