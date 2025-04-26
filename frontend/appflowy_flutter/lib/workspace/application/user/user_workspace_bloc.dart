import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/user/application/user_listener.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';

part 'user_workspace_bloc.freezed.dart';

class UserWorkspaceBloc extends Bloc<UserWorkspaceEvent, UserWorkspaceState> {
  UserWorkspaceBloc({
    required UserProfilePB userProfile,
    this.initialWorkspaceId,
  })  : _userService = UserBackendService(userId: userProfile.id),
        _listener = UserListener(userProfile: userProfile),
        super(UserWorkspaceState.initial(userProfile)) {
    on<UserWorkspaceEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _listener.start(
              onProfileUpdated: (result) {
                if (!isClosed) {
                  result.fold(
                    (newProfile) =>
                        add(UserWorkspaceEvent.updateUserProfile(newProfile)),
                    (error) => Log.error("Failed to get user profile: $error"),
                  );
                }
              },
              onUserWorkspaceListUpdated: (workspaces) =>
                  add(UserWorkspaceEvent.updateWorkspaces(workspaces)),
              onUserWorkspaceUpdated: (workspace) {
                if (!isClosed) {
                  // If currentWorkspace is updated, eg. Icon or Name, we should notify
                  // the UI to render the updated information.
                  final currentWorkspace = state.currentWorkspace;
                  if (currentWorkspace?.workspaceId == workspace.workspaceId) {
                    add(UserWorkspaceEvent.updateCurrentWorkspace(workspace));
                  }
                }
              },
            );

            final result = await _fetchWorkspaces(
              initialWorkspaceId: initialWorkspaceId,
            );
            final currentWorkspace = result.$1;
            final workspaces = result.$2;
            final isCollabWorkspaceOn =
                userProfile.userAuthType == AuthTypePB.Server &&
                    FeatureFlag.collaborativeWorkspace.isOn;
            Log.info(
              'init workspace, current workspace: ${currentWorkspace?.workspaceId}, '
              'workspaces: ${workspaces.map((e) => e.workspaceId)}, isCollabWorkspaceOn: $isCollabWorkspaceOn',
            );
            if (currentWorkspace != null && result.$3 == true) {
              Log.info('init open workspace: ${currentWorkspace.workspaceId}');
              await _userService.openWorkspace(
                currentWorkspace.workspaceId,
                currentWorkspace.workspaceType,
              );
            }

            emit(
              state.copyWith(
                currentWorkspace: currentWorkspace,
                workspaces: workspaces,
                isCollabWorkspaceOn: isCollabWorkspaceOn,
                actionResult: null,
              ),
            );
          },
          fetchWorkspaces: (initialWorkspaceId) async {
            final result = await _fetchWorkspaces(
              initialWorkspaceId: initialWorkspaceId,
            );

            final currentWorkspace = result.$1;
            final workspaces = result.$2;
            Log.info(
              'fetch workspaces: current workspace: ${currentWorkspace?.workspaceId}, workspaces: ${workspaces.map((e) => e.workspaceId)}',
            );

            emit(
              state.copyWith(
                workspaces: workspaces,
              ),
            );

            // try to open the workspace if the current workspace is not the same
            if (currentWorkspace != null &&
                currentWorkspace.workspaceId !=
                    state.currentWorkspace?.workspaceId) {
              Log.info(
                'fetch workspaces: try to open workspace: ${currentWorkspace.workspaceId}',
              );
              add(
                OpenWorkspace(
                  currentWorkspace.workspaceId,
                  currentWorkspace.workspaceType,
                ),
              );
            }
          },
          createWorkspace: (name, workspaceType) async {
            emit(
              state.copyWith(
                actionResult: const UserWorkspaceActionResult(
                  actionType: UserWorkspaceActionType.create,
                  isLoading: true,
                  result: null,
                ),
              ),
            );
            final result = await _userService.createUserWorkspace(
              name,
              workspaceType,
            );
            final workspaces = result.fold(
              (s) => [...state.workspaces, s],
              (e) => state.workspaces,
            );
            emit(
              state.copyWith(
                workspaces: workspaces,
                actionResult: UserWorkspaceActionResult(
                  actionType: UserWorkspaceActionType.create,
                  isLoading: false,
                  result: result,
                ),
              ),
            );
            // open the created workspace by default
            result
              ..onSuccess((s) {
                Log.info('create workspace success: $s');
                add(
                  OpenWorkspace(
                    s.workspaceId,
                    s.workspaceType,
                  ),
                );
              })
              ..onFailure((f) {
                Log.error('create workspace error: $f');
              });
          },
          deleteWorkspace: (workspaceId) async {
            Log.info('try to delete workspace: $workspaceId');
            emit(
              state.copyWith(
                actionResult: const UserWorkspaceActionResult(
                  actionType: UserWorkspaceActionType.delete,
                  isLoading: true,
                  result: null,
                ),
              ),
            );
            final remoteWorkspaces = await _fetchWorkspaces().then(
              (value) => value.$2,
            );
            if (state.workspaces.length <= 1 || remoteWorkspaces.length <= 1) {
              // do not allow to delete the last workspace, otherwise the user
              // cannot do create workspace again
              Log.error('cannot delete the only workspace');
              final result = FlowyResult.failure(
                FlowyError(
                  code: ErrorCode.Internal,
                  msg: LocaleKeys.workspace_cannotDeleteTheOnlyWorkspace.tr(),
                ),
              );
              return emit(
                state.copyWith(
                  actionResult: UserWorkspaceActionResult(
                    actionType: UserWorkspaceActionType.delete,
                    result: result,
                    isLoading: false,
                  ),
                ),
              );
            }

            final result = await _userService.deleteWorkspaceById(workspaceId);
            // fetch the workspaces again to check if the current workspace is deleted
            final workspacesResult = await _fetchWorkspaces();
            final workspaces = workspacesResult.$2;
            final containsDeletedWorkspace = workspaces.any(
              (e) => e.workspaceId == workspaceId,
            );
            result
              ..onSuccess((_) {
                Log.info('delete workspace success: $workspaceId');
                final firstWorkspace = workspaces.firstOrNull;
                // if the current workspace is deleted, open the first workspace
                assert(
                  firstWorkspace != null,
                  'the first workspace must not be null',
                );
                if (state.currentWorkspace?.workspaceId == workspaceId &&
                    firstWorkspace != null) {
                  Log.info(
                    'delete workspace: open the first workspace: ${firstWorkspace.workspaceId}',
                  );
                  add(
                    OpenWorkspace(
                      firstWorkspace.workspaceId,
                      firstWorkspace.workspaceType,
                    ),
                  );
                }
              })
              ..onFailure((f) {
                Log.error('delete workspace error: $f');
                // if the workspace is deleted but return an error, we need to
                // open the first workspace
                if (!containsDeletedWorkspace) {
                  add(
                    OpenWorkspace(
                      workspaces.first.workspaceId,
                      workspaces.first.workspaceType,
                    ),
                  );
                }
              });
            emit(
              state.copyWith(
                workspaces: workspaces,
                actionResult: UserWorkspaceActionResult(
                  actionType: UserWorkspaceActionType.delete,
                  result: result,
                  isLoading: false,
                ),
              ),
            );
          },
          openWorkspace: (workspaceId, workspaceType) async {
            emit(
              state.copyWith(
                actionResult: const UserWorkspaceActionResult(
                  actionType: UserWorkspaceActionType.open,
                  isLoading: true,
                  result: null,
                ),
              ),
            );
            final result = await _userService.openWorkspace(
              workspaceId,
              workspaceType,
            );
            final currentWorkspace = result.fold(
              (s) => state.workspaces.firstWhereOrNull(
                (e) => e.workspaceId == workspaceId,
              ),
              (e) => state.currentWorkspace,
            );

            result
              ..onSuccess((s) {
                Log.info(
                  'open workspace success: $workspaceId, current workspace: ${currentWorkspace?.toProto3Json()}',
                );
              })
              ..onFailure((f) {
                Log.error('open workspace error: $f');
              });

            emit(
              state.copyWith(
                currentWorkspace: currentWorkspace,
                actionResult: UserWorkspaceActionResult(
                  actionType: UserWorkspaceActionType.open,
                  isLoading: false,
                  result: result,
                ),
              ),
            );
          },
          renameWorkspace: (workspaceId, name) async {
            final result =
                await _userService.renameWorkspace(workspaceId, name);
            final workspaces = result.fold(
              (s) => state.workspaces.map(
                (e) {
                  if (e.workspaceId == workspaceId) {
                    e.freeze();
                    return e.rebuild((p0) {
                      p0.name = name;
                    });
                  }
                  return e;
                },
              ).toList(),
              (f) => state.workspaces,
            );
            final currentWorkspace = workspaces.firstWhere(
              (e) => e.workspaceId == state.currentWorkspace?.workspaceId,
            );

            Log.info(
              'rename workspace: $workspaceId, name: $name',
            );

            result.onFailure((f) {
              Log.error('rename workspace error: $f');
            });

            emit(
              state.copyWith(
                workspaces: workspaces,
                currentWorkspace: currentWorkspace,
                actionResult: UserWorkspaceActionResult(
                  actionType: UserWorkspaceActionType.rename,
                  isLoading: false,
                  result: result,
                ),
              ),
            );
          },
          updateWorkspaceIcon: (workspaceId, icon) async {
            final workspace = state.workspaces.firstWhere(
              (e) => e.workspaceId == workspaceId,
            );
            if (icon == workspace.icon) {
              Log.info('ignore same icon update');
              return;
            }

            final result = await _userService.updateWorkspaceIcon(
              workspaceId,
              icon,
            );
            final workspaces = result.fold(
              (s) => state.workspaces.map(
                (e) {
                  if (e.workspaceId == workspaceId) {
                    e.freeze();
                    return e.rebuild((p0) {
                      p0.icon = icon;
                    });
                  }
                  return e;
                },
              ).toList(),
              (f) => state.workspaces,
            );
            final currentWorkspace = workspaces.firstWhere(
              (e) => e.workspaceId == state.currentWorkspace?.workspaceId,
            );

            Log.info(
              'update workspace icon: $workspaceId, icon: $icon',
            );

            result.onFailure((f) {
              Log.error('update workspace icon error: $f');
            });

            emit(
              state.copyWith(
                workspaces: workspaces,
                currentWorkspace: currentWorkspace,
                actionResult: UserWorkspaceActionResult(
                  actionType: UserWorkspaceActionType.updateIcon,
                  isLoading: false,
                  result: result,
                ),
              ),
            );
          },
          leaveWorkspace: (workspaceId) async {
            final result = await _userService.leaveWorkspace(workspaceId);
            final workspaces = result.fold(
              (s) => state.workspaces
                  .where((e) => e.workspaceId != workspaceId)
                  .toList(),
              (e) => state.workspaces,
            );
            result
              ..onSuccess((_) {
                Log.info('leave workspace success: $workspaceId');
                // if leaving the current workspace, open the first workspace
                if (state.currentWorkspace?.workspaceId == workspaceId) {
                  add(
                    OpenWorkspace(
                      workspaces.first.workspaceId,
                      workspaces.first.workspaceType,
                    ),
                  );
                }
              })
              ..onFailure((f) {
                Log.error('leave workspace error: $f');
              });
            emit(
              state.copyWith(
                workspaces: workspaces,
                actionResult: UserWorkspaceActionResult(
                  actionType: UserWorkspaceActionType.leave,
                  isLoading: false,
                  result: result,
                ),
              ),
            );
          },
          updateWorkspaces: (workspaces) async {
            emit(
              state.copyWith(
                workspaces: workspaces.items
                  ..sort(
                    (a, b) =>
                        a.createdAtTimestamp.compareTo(b.createdAtTimestamp),
                  ),
              ),
            );
          },
          updateCurrentWorkspace: (workspace) async {
            final workspaces = [...state.workspaces];
            final index = workspaces
                .indexWhere((e) => e.workspaceId == workspace.workspaceId);
            if (index != -1) {
              workspaces[index] = workspace;
            }

            emit(
              state.copyWith(
                currentWorkspace: workspace,
                workspaces: workspaces
                  ..sort(
                    (a, b) =>
                        a.createdAtTimestamp.compareTo(b.createdAtTimestamp),
                  ),
              ),
            );
          },
          updateUserProfile: (newUserProfile) {
            emit(
              state.copyWith(
                userProfile: newUserProfile,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Future<void> close() {
    _listener.stop();
    return super.close();
  }

  final UserBackendService _userService;
  final UserListener _listener;
  final String? initialWorkspaceId;

  Future<
      (
        UserWorkspacePB? currentWorkspace,
        List<UserWorkspacePB> workspaces,
        bool shouldOpenWorkspace,
      )> _fetchWorkspaces({String? initialWorkspaceId}) async {
    try {
      final currentWorkspaceResult =
          await UserBackendService.getCurrentWorkspace();
      final currentWorkspace = currentWorkspaceResult.fold(
        (s) => s,
        (e) => null,
      );
      // if the initialWorkspaceId is not provided, use the current workspace id
      final currentWorkspaceId = initialWorkspaceId ?? currentWorkspace?.id;
      final workspaces = await _userService.getWorkspaces().getOrThrow();
      if (workspaces.isEmpty && currentWorkspace != null) {
        workspaces.add(convertWorkspacePBToUserWorkspace(currentWorkspace));
      }
      final currentWorkspaceInList = workspaces
              .firstWhereOrNull((e) => e.workspaceId == currentWorkspaceId) ??
          workspaces.firstOrNull;
      final sortedWorkspaces = workspaces
        ..sort(
          (a, b) => a.createdAtTimestamp.compareTo(b.createdAtTimestamp),
        );
      Log.info(
        'fetch workspaces: current workspace: ${currentWorkspaceInList?.workspaceId}, sorted workspaces: ${sortedWorkspaces.map((e) => '${e.name}: ${e.workspaceId}')}',
      );
      return (
        currentWorkspaceInList,
        sortedWorkspaces,
        currentWorkspaceInList?.workspaceId != currentWorkspaceId,
      );
    } catch (e) {
      Log.error('fetch workspace error: $e');
      return (null, <UserWorkspacePB>[], false);
    }
  }

  UserWorkspacePB convertWorkspacePBToUserWorkspace(WorkspacePB workspace) {
    return UserWorkspacePB.create()
      ..workspaceId = workspace.id
      ..name = workspace.name
      ..createdAtTimestamp = workspace.createTime;
  }
}

@freezed
class UserWorkspaceEvent with _$UserWorkspaceEvent {
  const factory UserWorkspaceEvent.initial() = Initial;
  const factory UserWorkspaceEvent.fetchWorkspaces({
    String? initialWorkspaceId,
  }) = FetchWorkspaces;
  const factory UserWorkspaceEvent.createWorkspace(
    String name,
    WorkspaceTypePB workspaceType,
  ) = CreateWorkspace;
  const factory UserWorkspaceEvent.deleteWorkspace(String workspaceId) =
      DeleteWorkspace;
  const factory UserWorkspaceEvent.openWorkspace(
    String workspaceId,
    WorkspaceTypePB workspaceType,
  ) = OpenWorkspace;
  const factory UserWorkspaceEvent.renameWorkspace(
    String workspaceId,
    String name,
  ) = _RenameWorkspace;
  const factory UserWorkspaceEvent.updateWorkspaceIcon(
    String workspaceId,
    String icon,
  ) = _UpdateWorkspaceIcon;
  const factory UserWorkspaceEvent.leaveWorkspace(String workspaceId) =
      LeaveWorkspace;
  const factory UserWorkspaceEvent.updateWorkspaces(
    RepeatedUserWorkspacePB workspaces,
  ) = UpdateWorkspaces;
  const factory UserWorkspaceEvent.updateCurrentWorkspace(
    UserWorkspacePB workspace,
  ) = UpdateCurrentWorkspace;
  const factory UserWorkspaceEvent.updateUserProfile(
    UserProfilePB userProfile,
  ) = UpdateUserProfile;
}

enum UserWorkspaceActionType {
  none,
  create,
  delete,
  open,
  rename,
  updateIcon,
  fetchWorkspaces,
  leave;
}

class UserWorkspaceActionResult {
  const UserWorkspaceActionResult({
    required this.actionType,
    required this.isLoading,
    required this.result,
  });

  final UserWorkspaceActionType actionType;
  final bool isLoading;
  final FlowyResult<void, FlowyError>? result;

  @override
  String toString() {
    return 'UserWorkspaceActionResult(actionType: $actionType, isLoading: $isLoading, result: $result)';
  }
}

@freezed
class UserWorkspaceState with _$UserWorkspaceState {
  const UserWorkspaceState._();

  const factory UserWorkspaceState({
    @Default(null) UserWorkspacePB? currentWorkspace,
    @Default([]) List<UserWorkspacePB> workspaces,
    @Default(null) UserWorkspaceActionResult? actionResult,
    @Default(false) bool isCollabWorkspaceOn,
    required UserProfilePB userProfile,
  }) = _UserWorkspaceState;

  factory UserWorkspaceState.initial(UserProfilePB userProfile) =>
      UserWorkspaceState(
        userProfile: userProfile,
      );

  @override
  int get hashCode => runtimeType.hashCode;

  final DeepCollectionEquality _deepCollectionEquality =
      const DeepCollectionEquality();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserWorkspaceState &&
        other.currentWorkspace == currentWorkspace &&
        _deepCollectionEquality.equals(other.workspaces, workspaces) &&
        identical(other.actionResult, actionResult) &&
        other.userProfile == userProfile;
  }
}
