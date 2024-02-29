import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_workspace_bloc.freezed.dart';

class UserWorkspaceBloc extends Bloc<UserWorkspaceEvent, UserWorkspaceState> {
  UserWorkspaceBloc({
    required this.userProfile,
  })  : _userService = UserBackendService(userId: userProfile.id),
        super(UserWorkspaceState.initial()) {
    on<UserWorkspaceEvent>(
      (event, emit) async {
        await event.map(
          initial: (e) async {
            // do nothing
          },
          fetchWorkspaces: (e) async {
            await _fetchCurrentWorkspace(emit);
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
          deleteWorkspace: (e) async {
            await _deleteWorkspace(e.workspaceId, emit);
          },
          openWorkspace: (e) async {
            await _openWorkspace(e.workspaceId, emit);
          },
        );
      },
    );
  }

  final UserProfilePB userProfile;
  final UserBackendService _userService;

  Future<void> _fetchCurrentWorkspace(Emitter<UserWorkspaceState> emit) async {
    final currentWorkspace = await _userService.getCurrentWorkspace();
    emit(
      currentWorkspace.fold(
        (workspace) => state.copyWith(
          currentWorkspace: workspace,
          successOrFailure: FlowyResult.success(null),
        ),
        (error) {
          Log.error(error);
          return state.copyWith(successOrFailure: FlowyResult.failure(error));
        },
      ),
    );
  }

  Future<void> _fetchWorkspaces(Emitter<UserWorkspaceState> emit) async {
    final workspacesOrFailed = await _userService.getWorkspaces();
    emit(
      workspacesOrFailed.fold(
        (workspaces) {
          Log.debug('fetching workspaces: $workspaces');
          return state.copyWith(
            workspaces: workspaces,
            successOrFailure: FlowyResult.success(null),
          );
        },
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
    Emitter<UserWorkspaceState> emit,
  ) async {
    final result = await _userService.createUserWorkspace(name);
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

  Future<void> _deleteWorkspace(
    String workspaceId,
    Emitter<UserWorkspaceState> emit,
  ) async {
    final result = await _userService.deleteWorkspaceById(workspaceId);
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

  Future<void> _openWorkspace(
    String workspaceId,
    Emitter<UserWorkspaceState> emit,
  ) async {
    final result = await _userService.openWorkspace(workspaceId);
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
class UserWorkspaceEvent with _$UserWorkspaceEvent {
  const factory UserWorkspaceEvent.initial() = Initial;
  const factory UserWorkspaceEvent.createWorkspace(String name, String desc) =
      CreateWorkspace;
  const factory UserWorkspaceEvent.fetchWorkspaces() = FetchWorkspaces;
  const factory UserWorkspaceEvent.deleteWorkspace(String workspaceId) =
      DeleteWorkspace;
  const factory UserWorkspaceEvent.openWorkspace(String workspaceId) =
      OpenWorkspace;
  const factory UserWorkspaceEvent.workspacesReceived(
    FlowyResult<List<UserWorkspacePB>, FlowyError> workspacesOrFail,
  ) = WorkspacesReceived;
}

@freezed
class UserWorkspaceState with _$UserWorkspaceState {
  const factory UserWorkspaceState({
    required bool isLoading,
    required WorkspacePB? currentWorkspace,
    required List<UserWorkspacePB> workspaces,
    required FlowyResult<void, FlowyError> successOrFailure,
  }) = _UserWorkspaceState;

  factory UserWorkspaceState.initial() => UserWorkspaceState(
        isLoading: false,
        currentWorkspace: null,
        workspaces: [],
        successOrFailure: FlowyResult.success(null),
      );
}
