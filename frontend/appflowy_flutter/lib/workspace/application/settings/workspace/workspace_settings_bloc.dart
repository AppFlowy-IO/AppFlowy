import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
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

            try {
              final currentWorkspace =
                  await _userService!.getCurrentWorkspace().getOrThrow();

              final workspaces =
                  await _userService!.getWorkspaces().getOrThrow();
              if (workspaces.isEmpty) {
                workspaces.add(
                  UserWorkspacePB.create()
                    ..workspaceId = currentWorkspace.id
                    ..name = currentWorkspace.name
                    ..createdAtTimestamp = currentWorkspace.createTime,
                );
              }

              final currentWorkspaceInList = workspaces.firstWhereOrNull(
                    (e) => e.workspaceId == currentWorkspace.id,
                  ) ??
                  workspaces.firstOrNull;

              // We emit here because the next event might take longer.
              emit(state.copyWith(workspace: currentWorkspaceInList));

              if (currentWorkspaceInList == null) {
                return;
              }

              final members = await _getWorkspaceMembers(
                currentWorkspaceInList.workspaceId,
              );

              final role = members
                      .firstWhereOrNull((e) => e.email == userProfile.email)
                      ?.role ??
                  AFRolePB.Guest;

              emit(state.copyWith(members: members, myRole: role));
            } catch (e) {
              Log.error('Failed to get or create current workspace');
            }
          },
          updateWorkspaceName: (name) async {
            final request = RenameWorkspacePB(
              workspaceId: state.workspace?.workspaceId,
              newName: name,
            );
            final result = await UserEventRenameWorkspace(request).send();

            state.workspace!.freeze();
            final update = state.workspace!.rebuild((p0) => p0.name = name);

            result.fold(
              (_) => emit(state.copyWith(workspace: update)),
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
                state.workspace!.freeze();
                final newWorkspace =
                    state.workspace!.rebuild((p0) => p0.icon = icon);

                return emit(state.copyWith(workspace: newWorkspace));
              },
              (e) => Log.error('Failed to update workspace icon: $e'),
            );
          },
          deleteWorkspace: () async =>
              emit(state.copyWith(deleteWorkspace: true)),
          leaveWorkspace: () async {
            final result = await _userService
                ?.leaveWorkspace(state.workspace!.workspaceId);

            await result?.fold(
              (_) async {
                final workspaces = await _userService?.getWorkspaces();
                final workspace = workspaces?.toNullable()?.first;
                if (workspace != null) {
                  emit(state.copyWith(workspace: workspace));
                  await _userService?.openWorkspace(workspace.workspaceId);
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
  const factory WorkspaceSettingsEvent.leaveWorkspace() = leaveWorkspace;
}

@freezed
class WorkspaceSettingsState with _$WorkspaceSettingsState {
  const factory WorkspaceSettingsState({
    @Default(null) UserWorkspacePB? workspace,
    @Default([]) List<WorkspaceMemberPB> members,
    @Default(AFRolePB.Guest) AFRolePB myRole,
    @Default(false) bool deleteWorkspace,
  }) = _WorkspaceSettingsState;

  factory WorkspaceSettingsState.initial() => const WorkspaceSettingsState();
}
