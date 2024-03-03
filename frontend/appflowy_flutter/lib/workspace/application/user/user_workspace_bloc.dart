import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
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
        await event.when(
          initial: () async {
            // do nothing
          },
          fetchWorkspaces: () async {
            final result = await _fetchWorkspaces();
            if (result != null) {
              emit(
                state.copyWith(
                  currentWorkspace: result.$1,
                  workspaces: result.$2,
                  successOrFailure: FlowyResult.success(null),
                ),
              );
            } else {
              emit(
                state.copyWith(
                  successOrFailure: FlowyResult.failure(
                    FlowyError(
                      msg: 'Failed to fetch workspaces',
                    ),
                  ),
                ),
              );
            }
          },
          createWorkspace: (name, desc) async {
            await _createWorkspace(name, desc, emit);
          },
          workspacesReceived: (workspaceId) async {},
          deleteWorkspace: (workspaceId) async {
            await _deleteWorkspace(workspaceId, emit);
          },
          openWorkspace: (workspaceId) async {
            await _openWorkspace(workspaceId, emit);
          },
        );
      },
    );
  }

  final UserProfilePB userProfile;
  final UserBackendService _userService;

  Future<(UserWorkspacePB currentWorkspace, List<UserWorkspacePB> workspaces)?>
      _fetchWorkspaces() async {
    final result = await _userService.getCurrentWorkspace();
    return result.fold((currentWorkspace) async {
      final result = await _userService.getWorkspaces();
      return result.fold((workspaces) {
        return (
          workspaces.firstWhere(
            (e) => e.workspaceId == currentWorkspace.id,
          ),
          workspaces
        );
      }, (e) {
        Log.error(e);
        return null;
      });
    }, (e) {
      Log.error(e);
      return null;
    });
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
    required UserWorkspacePB? currentWorkspace,
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
