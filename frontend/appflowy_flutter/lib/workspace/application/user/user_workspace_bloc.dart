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
          workspacesReceived: (workspaceId) async {},
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
              state.copyWith(
                openWorkspaceResult: null,
                deleteWorkspaceResult: null,
                createWorkspaceResult:
                    result.fold((s) => FlowyResult.success(null), (e) {
                  Log.error(e);
                  return FlowyResult.failure(e);
                }),
              ),
            );
          },
          deleteWorkspace: (workspaceId) async {
            final result = await _userService.deleteWorkspaceById(workspaceId);
            emit(
              state.copyWith(
                openWorkspaceResult: null,
                createWorkspaceResult: null,
                deleteWorkspaceResult:
                    result.fold((s) => FlowyResult.success(null), (e) {
                  Log.error(e);
                  return FlowyResult.failure(e);
                }),
              ),
            );
          },
          openWorkspace: (workspaceId) async {
            final result = await _userService.openWorkspace(workspaceId);
            emit(
              state.copyWith(
                createWorkspaceResult: null,
                deleteWorkspaceResult: null,
                openWorkspaceResult:
                    result.fold((s) => FlowyResult.success(null), (e) {
                  Log.error(e);
                  return FlowyResult.failure(e);
                }),
              ),
            );
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
    @Default(null) FlowyResult<void, FlowyError>? createWorkspaceResult,
    @Default(null) FlowyResult<void, FlowyError>? deleteWorkspaceResult,
    @Default(null) FlowyResult<void, FlowyError>? openWorkspaceResult,
  }) = _UserWorkspaceState;

  factory UserWorkspaceState.initial() => const UserWorkspaceState(
        currentWorkspace: null,
        workspaces: [],
        createWorkspaceResult: null,
        deleteWorkspaceResult: null,
        openWorkspaceResult: null,
      );
}
