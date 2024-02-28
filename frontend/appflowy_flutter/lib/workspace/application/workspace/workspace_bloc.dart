import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'workspace_bloc.freezed.dart';

class WorkspaceBloc extends Bloc<WorkspaceEvent, WorkspaceState> {
  WorkspaceBloc({required this.userService}) : super(WorkspaceState.initial()) {
    _dispatch();
  }

  final UserBackendService userService;

  void _dispatch() {
    on<WorkspaceEvent>(
      (event, emit) async {
        await event.map(
          initial: (e) async {
            await _fetchWorkspaces(emit);
          },
          createWorkspace: (e) async {
            await _createWorkspace(e.name, e.desc, emit);
          },
          workspacesReceived: (e) async {
            emit(
              e.workspacesOrFail.fold(
                (workspaces) => state.copyWith(
                  workspaces: workspaces,
                  successOrFailure: FlowyResult.success(null),
                ),
                (error) => state.copyWith(
                  successOrFailure: FlowyResult.failure(error),
                ),
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
          workspaces: [],
          successOrFailure: FlowyResult.success(null),
        ),
        (error) {
          Log.error(error);
          return state.copyWith(successOrFailure: FlowyResult.failure(error));
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
          return state.copyWith(successOrFailure: FlowyResult.success(null));
        },
        (error) {
          Log.error(error);
          return state.copyWith(successOrFailure: FlowyResult.failure(error));
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
  const factory WorkspaceEvent.workspacesReceived(
    FlowyResult<List<WorkspacePB>, FlowyError> workspacesOrFail,
  ) = WorkspacesReceived;
}

@freezed
class WorkspaceState with _$WorkspaceState {
  const factory WorkspaceState({
    required bool isLoading,
    required List<WorkspacePB> workspaces,
    required FlowyResult<void, FlowyError> successOrFailure,
  }) = _WorkspaceState;

  factory WorkspaceState.initial() => WorkspaceState(
        isLoading: false,
        workspaces: List.empty(),
        successOrFailure: FlowyResult.success(null),
      );
}
