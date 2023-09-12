import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

part 'workspace_bloc.freezed.dart';

class WorkspaceBloc extends Bloc<WorkspaceEvent, WorkspaceState> {
  final UserBackendService userService;
  WorkspaceBloc({
    required this.userService,
  }) : super(WorkspaceState.initial()) {
    on<WorkspaceEvent>(
      (event, emit) async {
        await event.map(
          initial: (e) async {
            await _fetchWorkspaces(emit);
          },
          openWorkspace: (e) async {
            await _openWorkspace(e.workspace, emit);
          },
          createWorkspace: (e) async {
            await _createWorkspace(e.name, e.desc, emit);
          },
          workspacesReveived: (e) async {
            emit(
              e.workspacesOrFail.fold(
                (workspaces) => state.copyWith(
                  workspaces: workspaces,
                  successOrFailure: left(unit),
                ),
                (error) => state.copyWith(successOrFailure: right(error)),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _fetchWorkspaces(Emitter<WorkspaceState> emit) async {
    final workspacesOrFailed = await userService.getWorkspaces();
    emit(
      workspacesOrFailed.fold(
        (workspaces) => state.copyWith(
          workspaces: workspaces,
          successOrFailure: left(unit),
        ),
        (error) {
          Log.error(error);
          return state.copyWith(successOrFailure: right(error));
        },
      ),
    );
  }

  Future<void> _openWorkspace(
    WorkspacePB workspace,
    Emitter<WorkspaceState> emit,
  ) async {
    final result = await userService.openWorkspace(workspace.id);
    emit(
      result.fold(
        (workspaces) => state.copyWith(successOrFailure: left(unit)),
        (error) {
          Log.error(error);
          return state.copyWith(successOrFailure: right(error));
        },
      ),
    );
  }

  Future<void> _createWorkspace(
    String name,
    String desc,
    Emitter<WorkspaceState> emit,
  ) async {
    final result = await userService.createWorkspace(name, desc);
    emit(
      result.fold(
        (workspace) {
          return state.copyWith(successOrFailure: left(unit));
        },
        (error) {
          Log.error(error);
          return state.copyWith(successOrFailure: right(error));
        },
      ),
    );
  }
}

@freezed
class WorkspaceEvent with _$WorkspaceEvent {
  const factory WorkspaceEvent.initial() = Initial;
  const factory WorkspaceEvent.createWorkspace(String name, String desc) =
      CreateWorkspace;
  const factory WorkspaceEvent.openWorkspace(WorkspacePB workspace) =
      OpenWorkspace;
  const factory WorkspaceEvent.workspacesReveived(
    Either<List<WorkspacePB>, FlowyError> workspacesOrFail,
  ) = WorkspacesReceived;
}

@freezed
class WorkspaceState with _$WorkspaceState {
  const factory WorkspaceState({
    required bool isLoading,
    required List<WorkspacePB> workspaces,
    required Either<Unit, FlowyError> successOrFailure,
  }) = _WorkspaceState;

  factory WorkspaceState.initial() => WorkspaceState(
        isLoading: false,
        workspaces: List.empty(),
        successOrFailure: left(unit),
      );
}
