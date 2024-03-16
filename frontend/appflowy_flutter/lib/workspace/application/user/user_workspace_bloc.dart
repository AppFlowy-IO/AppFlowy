import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';

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
            final (workspaces, createWorkspaceResult) = result.fold(
              (s) {
                final workspaces = [...state.workspaces, s];
                return (
                  workspaces,
                  FlowyResult<void, FlowyError>.success(null)
                );
              },
              (e) {
                Log.error(e);
                return (state.workspaces, FlowyResult.failure(e));
              },
            );
            emit(
              state.copyWith(
                openWorkspaceResult: null,
                deleteWorkspaceResult: null,
                updateWorkspaceIconResult: null,
                createWorkspaceResult: createWorkspaceResult,
                workspaces: workspaces,
              ),
            );
          },
          deleteWorkspace: (workspaceId) async {
            if (state.workspaces.length <= 1) {
              // do not allow to delete the last workspace
              return emit(
                state.copyWith(
                  openWorkspaceResult: null,
                  createWorkspaceResult: null,
                  updateWorkspaceIconResult: null,
                  renameWorkspaceResult: null,
                  deleteWorkspaceResult: FlowyResult.failure(
                    FlowyError(
                      code: ErrorCode.Internal,
                      msg: 'Cannot delete the last workspace',
                    ),
                  ),
                ),
              );
            }

            final result = await _userService.deleteWorkspaceById(workspaceId);
            final (workspaces, deleteWorkspaceResult) = result.fold(
              (s) {
                // if the current workspace is deleted, open the first workspace
                if (state.currentWorkspace?.workspaceId == workspaceId) {
                  add(OpenWorkspace(state.workspaces.first.workspaceId));
                }
                // remove the deleted workspace from the list instead of fetching
                // the workspaces again
                final workspaces = [...state.workspaces]..removeWhere(
                    (e) => e.workspaceId == workspaceId,
                  );
                return (
                  workspaces,
                  FlowyResult<void, FlowyError>.success(null)
                );
              },
              (e) {
                Log.error(e);
                return (state.workspaces, FlowyResult.failure(e));
              },
            );

            emit(
              state.copyWith(
                openWorkspaceResult: null,
                createWorkspaceResult: null,
                updateWorkspaceIconResult: null,
                renameWorkspaceResult: null,
                deleteWorkspaceResult: deleteWorkspaceResult,
                workspaces: workspaces,
              ),
            );
          },
          openWorkspace: (workspaceId) async {
            final (currentWorkspace, openWorkspaceResult) =
                await _userService.openWorkspace(workspaceId).fold(
              (s) {
                final openedWorkspace = state.workspaces.firstWhere(
                  (e) => e.workspaceId == workspaceId,
                );
                return (
                  openedWorkspace,
                  FlowyResult<void, FlowyError>.success(null)
                );
              },
              (f) {
                Log.error(f);
                return (state.currentWorkspace, FlowyResult.failure(f));
              },
            );

            emit(
              state.copyWith(
                createWorkspaceResult: null,
                deleteWorkspaceResult: null,
                updateWorkspaceIconResult: null,
                openWorkspaceResult: openWorkspaceResult,
                currentWorkspace: currentWorkspace,
              ),
            );
          },
          renameWorkspace: (workspaceId, name) async {
            final result = await _userService.renameWorkspace(
              workspaceId,
              name,
            );
            final (workspaces, currentWorkspace, renameWorkspaceResult) =
                result.fold(
              (s) {
                final workspaces = state.workspaces.map((e) {
                  if (e.workspaceId == workspaceId) {
                    e.freeze();
                    return e.rebuild((p0) {
                      p0.name = name;
                    });
                  }
                  return e;
                }).toList();

                final currentWorkspace = workspaces.firstWhere(
                  (e) => e.workspaceId == state.currentWorkspace?.workspaceId,
                );

                return (
                  workspaces,
                  currentWorkspace,
                  FlowyResult<void, FlowyError>.success(null),
                );
              },
              (e) {
                Log.error(e);
                return (
                  state.workspaces,
                  state.currentWorkspace,
                  FlowyResult.failure(e),
                );
              },
            );
            emit(
              state.copyWith(
                createWorkspaceResult: null,
                deleteWorkspaceResult: null,
                openWorkspaceResult: null,
                updateWorkspaceIconResult: null,
                workspaces: workspaces,
                currentWorkspace: currentWorkspace,
                renameWorkspaceResult: renameWorkspaceResult,
              ),
            );
          },
          updateWorkspaceIcon: (workspaceId, icon) async {
            final result = await _userService.updateWorkspaceIcon(
              workspaceId,
              icon,
            );

            final (workspaces, currentWorkspace, updateWorkspaceIconResult) =
                result.fold(
              (s) {
                final workspaces = state.workspaces.map((e) {
                  if (e.workspaceId == workspaceId) {
                    e.freeze();
                    return e.rebuild((p0) {
                      p0.icon = icon;
                    });
                  }
                  return e;
                }).toList();

                final currentWorkspace = workspaces.firstWhere(
                  (e) => e.workspaceId == state.currentWorkspace?.workspaceId,
                );

                return (
                  workspaces,
                  currentWorkspace,
                  FlowyResult<void, FlowyError>.success(null),
                );
              },
              (e) {
                Log.error(e);
                return (
                  state.workspaces,
                  state.currentWorkspace,
                  FlowyResult.failure(e),
                );
              },
            );

            emit(
              state.copyWith(
                createWorkspaceResult: null,
                deleteWorkspaceResult: null,
                openWorkspaceResult: null,
                renameWorkspaceResult: null,
                updateWorkspaceIconResult: updateWorkspaceIconResult,
                workspaces: workspaces,
                currentWorkspace: currentWorkspace,
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
    try {
      final currentWorkspace =
          await _userService.getCurrentWorkspace().getOrThrow();
      final workspaces = await _userService.getWorkspaces().getOrThrow();
      final currentWorkspaceInList =
          workspaces.firstWhere((e) => e.workspaceId == currentWorkspace.id);
      return (currentWorkspaceInList, workspaces);
    } catch (e) {
      Log.error(e);
      return null;
    }
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
  const factory UserWorkspaceEvent.renameWorkspace(
    String workspaceId,
    String name,
  ) = _RenameWorkspace;
  const factory UserWorkspaceEvent.updateWorkspaceIcon(
    String workspaceId,
    String icon,
  ) = _UpdateWorkspaceIcon;
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
    @Default(null) FlowyResult<void, FlowyError>? renameWorkspaceResult,
    @Default(null) FlowyResult<void, FlowyError>? updateWorkspaceIconResult,
  }) = _UserWorkspaceState;

  factory UserWorkspaceState.initial() =>
      const UserWorkspaceState(currentWorkspace: null, workspaces: []);
}
