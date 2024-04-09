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
            final currentWorkspace =
                workspace ?? await _getWorkspace(userProfile.workspaceId);

            // We emit here because the next event might take longer.
            emit(state.copyWith(workspace: currentWorkspace));

            final members = await _getWorkspaceMembers(userProfile.workspaceId);
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
          addWorkspaceMember: (email) {},
          removeWorkspaceMember: (email) {},
          updateWorkspaceMember: (email, role) {},
        );
      },
    );
  }

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

  // Workspace Member
  const factory WorkspaceSettingsEvent.addWorkspaceMember(String email) =
      AddWorkspaceMember;
  const factory WorkspaceSettingsEvent.removeWorkspaceMember(String email) =
      RemoveWorkspaceMember;
  const factory WorkspaceSettingsEvent.updateWorkspaceMember(
    String email,
    AFRolePB role,
  ) = UpdateWorkspaceMember;
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
