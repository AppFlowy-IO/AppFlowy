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
                ),
              );
            }
          },
          createWorkspace: (name, desc) async {
            final result = await _userService.createUserWorkspace(name);
            emit(
              result.fold(
                (workspace) {
                  return state.copyWith(
                    createWorkspaceResult: FlowyResult.success(null),
                  );
                },
                (error) {
                  Log.error(error);
                  return state.copyWith(
                    createWorkspaceResult: FlowyResult.failure(error),
                  );
                },
              ),
            );
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

  Future<void> _deleteWorkspace(
    String workspaceId,
    Emitter<UserWorkspaceState> emit,
  ) async {
    final result = await _userService.deleteWorkspaceById(workspaceId);
  }

  Future<void> _openWorkspace(
    String workspaceId,
    Emitter<UserWorkspaceState> emit,
  ) async {
    final result = await _userService.openWorkspace(workspaceId);
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
    required UserWorkspacePB? currentWorkspace,
    required List<UserWorkspacePB> workspaces,
    required FlowyResult<void, FlowyError>? createWorkspaceResult,
  }) = _UserWorkspaceState;

  factory UserWorkspaceState.initial() => const UserWorkspaceState(
        currentWorkspace: null,
        workspaces: [],
        createWorkspaceResult: null,
      );
}
