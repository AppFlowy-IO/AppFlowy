import 'package:flutter/foundation.dart';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';

part 'workspace_settings_bloc.freezed.dart';

class WorkspaceSettingsBloc
    extends Bloc<WorkspaceSettingsEvent, WorkspaceSettingsState> {
  WorkspaceSettingsBloc() : super(WorkspaceSettingsState.initial()) {
    on<WorkspaceSettingsEvent>(
      (event, emit) async {
        await event.when(
          initial: (userProfile, workspace) async {
            _userService = UserBackendService(userId: userProfile.id);

            late UserWorkspacePB currentWorkspace;
            final kvStore = getIt<KeyValueStorage>();
            final lastOpenedWorkspaceId =
                await kvStore.get(KVKeys.lastOpenedWorkspaceId);

            if (lastOpenedWorkspaceId != null) {
              currentWorkspace = await _getWorkspace(lastOpenedWorkspaceId);
            } else {
              currentWorkspace = await _getWorkspace(userProfile.workspaceId);
              await kvStore.set(
                KVKeys.lastOpenedWorkspaceId,
                userProfile.workspaceId,
              );
            }

            // We emit here because the next event might take longer.
            emit(state.copyWith(workspace: currentWorkspace));

            final members = await _getWorkspaceMembers(
              currentWorkspace.workspaceId,
            );
            final role = members
                    .firstWhereOrNull((e) => e.email == userProfile.email)
                    ?.role ??
                AFRolePB.Guest;

            emit(state.copyWith(members: members, myRole: role));
          },
          updateWorkspaceName: (name) async {
            final request = RenameWorkspacePB(
              workspaceId: state.workspace?.workspaceId,
              newName: name,
            );
            final result = await UserEventRenameWorkspace(request).send();

            result.fold(
              (_) => emit(
                state.copyWith(workspace: state.workspace?..name = name),
              ),
              (e) => Log.error('Failed to rename workspace: $e'),
            );
          },
          updateWorkspaceIcon: (icon) async {
            if (state.workspace == null) {
              return null;
            }

            final request = ChangeWorkspaceIconPB()
              ..workspaceId = state.workspace!.workspaceId
              ..newIcon = icon;
            final result = await UserEventChangeWorkspaceIcon(request).send();

            result.fold(
              (_) {
                final workspace = state.workspace?..freeze();
                if (workspace != null) {
                  final newWorkspace = workspace.rebuild((p0) {
                    p0.icon = icon;
                  });

                  return emit(state.copyWith(workspace: newWorkspace));
                }

                Log.error('Failed to update workspace icon, no workspace.');
              },
              (e) => Log.error('Failed to update workspace icon: $e'),
            );
          },
          deleteWorkspace: () async {
            final request =
                UserWorkspaceIdPB(workspaceId: state.workspace!.workspaceId);
            final result = await UserEventDeleteWorkspace(request).send();

            await result.fold(
              (_) async {
                final workspaces = await _userService?.getWorkspaces();
                final workspace = workspaces?.toNullable()?.first;
                if (workspace != null) {
                  await getIt<KeyValueStorage>().set(
                    KVKeys.lastOpenedWorkspaceId,
                    workspace.workspaceId,
                  );
                  emit(state.copyWith(workspace: workspace));
                }
              },
              (f) async => Log.error('Failed to delete workspace $f'),
            );
          },
          addWorkspaceMember: (email) {},
          removeWorkspaceMember: (email) {},
          updateWorkspaceMember: (email, role) {},
          leaveWorkspace: () async {
            final result = await _userService
                ?.leaveWorkspace(state.workspace!.workspaceId);

            await result?.fold(
              (_) async {
                final workspaces = await _userService?.getWorkspaces();
                final workspace = workspaces?.toNullable()?.first;
                if (workspace != null) {
                  await getIt<KeyValueStorage>().set(
                    KVKeys.lastOpenedWorkspaceId,
                    workspace.workspaceId,
                  );
                  emit(state.copyWith(workspace: workspace));
                }
              },
              (f) async => Log.error('Failed to leave workspace: $f'),
            );
          },
        );
      },
    );
  }

  UserBackendService? _userService;

  Future<UserWorkspacePB> _getWorkspace(String workspaceId) async {
    final request = UserWorkspaceIdPB(workspaceId: workspaceId);
    final result = await UserEventGetWorkspace(request).send();
    return result.fold(
      (workspace) => workspace,
      (e) {
        Log.error('Failed to read workspace: $e');
        return UserWorkspacePB();
      },
    );
  }

  Future<List<WorkspaceMemberPB>> _getWorkspaceMembers(
    String workspaceId,
  ) async {
    final data = QueryWorkspacePB()..workspaceId = workspaceId;
    final result = await UserEventGetWorkspaceMember(data).send();
    return result.fold(
      (s) => s.items,
      (e) {
        Log.error('Failed to read workspace members: $e');
        return [];
      },
    );
  }
}

@freezed
class WorkspaceSettingsEvent with _$WorkspaceSettingsEvent {
  const factory WorkspaceSettingsEvent.initial({
    required UserProfilePB userProfile,
    @Default(null) UserWorkspacePB? workspace,
  }) = Initial;

  // Workspace itself
  const factory WorkspaceSettingsEvent.updateWorkspaceName(String name) =
      UpdateWorkspaceName;
  const factory WorkspaceSettingsEvent.updateWorkspaceIcon(String icon) =
      UpdateWorkspaceIcon;
  const factory WorkspaceSettingsEvent.deleteWorkspace() = DeleteWorkspace;

  // Workspace Member
  const factory WorkspaceSettingsEvent.addWorkspaceMember(String email) =
      AddWorkspaceMember;
  const factory WorkspaceSettingsEvent.removeWorkspaceMember(String email) =
      RemoveWorkspaceMember;
  const factory WorkspaceSettingsEvent.updateWorkspaceMember(
    String email,
    AFRolePB role,
  ) = UpdateWorkspaceMember;
  const factory WorkspaceSettingsEvent.leaveWorkspace() = leaveWorkspace;
}

@freezed
class WorkspaceSettingsState with _$WorkspaceSettingsState {
  const factory WorkspaceSettingsState({
    @Default(null) UserWorkspacePB? workspace,
    @Default([]) List<WorkspaceMemberPB> members,
    @Default(AFRolePB.Guest) AFRolePB myRole,
  }) = _WorkspaceSettingsState;

  factory WorkspaceSettingsState.initial() => const WorkspaceSettingsState();
}
