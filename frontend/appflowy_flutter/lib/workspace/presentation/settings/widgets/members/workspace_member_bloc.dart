import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'workspace_member_bloc.freezed.dart';

// 1. get the workspace members
// 2. display the content based on the user role
//  Owner:
//   - invite member button
//   - delete member button
//   - member list
//  Member:
//  Guest:
//   - member list
class WorkspaceMemberBloc
    extends Bloc<WorkspaceMemberEvent, WorkspaceMemberState> {
  WorkspaceMemberBloc({
    required this.userProfile,
    this.workspace,
  }) : super(WorkspaceMemberState.initial()) {
    on<WorkspaceMemberEvent>((event, emit) async {
      await event.when(
        initial: () async {
          if (workspace != null) {
            workspaceId = workspace!.workspaceId;
          } else {
            final currentWorkspace =
                await FolderEventReadCurrentWorkspace().send();
            currentWorkspace.fold((s) {
              workspaceId = s.id;
            }, (e) {
              assert(false, 'Failed to read current workspace: $e');
              Log.error('Failed to read current workspace: $e');
              workspaceId = '';
            });
          }
        },
        getWorkspaceMembers: () async {
          final members = await _getWorkspaceMembers();
          final myRole = _getMyRole(members);
          emit(
            state.copyWith(
              members: members,
              myRole: myRole,
            ),
          );
        },
        addWorkspaceMember: (email) async {
          await _addWorkspaceMember(email);
          add(const WorkspaceMemberEvent.getWorkspaceMembers());
        },
        removeWorkspaceMember: (email) async {
          await _removeWorkspaceMember(email);
          add(const WorkspaceMemberEvent.getWorkspaceMembers());
        },
        updateWorkspaceMember: (email, role) async {
          await _updateWorkspaceMember(email, role);
          add(const WorkspaceMemberEvent.getWorkspaceMembers());
        },
      );
    });
  }

  final UserProfilePB userProfile;

  // if the workspace is null, use the current workspace
  final UserWorkspacePB? workspace;

  late final String workspaceId;

  Future<List<WorkspaceMemberPB>> _getWorkspaceMembers() async {
    final data = QueryWorkspacePB()..workspaceId = workspaceId;
    final result = await UserEventGetWorkspaceMember(data).send();
    return result.fold((s) => s.items, (e) {
      Log.error('Failed to read workspace members: $e');
      return [];
    });
  }

  AFRolePB _getMyRole(List<WorkspaceMemberPB> members) {
    final role = members
        .firstWhereOrNull(
          (e) => e.email == userProfile.email,
        )
        ?.role;
    if (role == null) {
      Log.error('Failed to get my role');
      return AFRolePB.Guest;
    }
    return role;
  }

  Future<void> _addWorkspaceMember(String email) async {
    final data = AddWorkspaceMemberPB()
      ..workspaceId = workspaceId
      ..email = email;
    final result = await UserEventAddWorkspaceMember(data).send();
    result.fold((s) {
      Log.info('Added workspace member: $data');
    }, (e) {
      Log.error('Failed to add workspace member: $e');
    });
  }

  Future<void> _removeWorkspaceMember(String email) async {
    final data = RemoveWorkspaceMemberPB()
      ..workspaceId = workspaceId
      ..email = email;
    final result = await UserEventRemoveWorkspaceMember(data).send();
    result.fold((s) {
      Log.info('Removed workspace member: $data');
    }, (e) {
      Log.error('Failed to remove workspace member: $e');
    });
  }

  Future<void> _updateWorkspaceMember(String email, AFRolePB role) async {
    final data = UpdateWorkspaceMemberPB()
      ..workspaceId = workspaceId
      ..email = email
      ..role = role;
    final result = await UserEventUpdateWorkspaceMember(data).send();
    result.fold((s) {
      Log.info('Updated workspace member: $data');
    }, (e) {
      Log.error('Failed to update workspace member: $e');
    });
  }
}

@freezed
class WorkspaceMemberEvent with _$WorkspaceMemberEvent {
  const factory WorkspaceMemberEvent.initial() = Initial;
  const factory WorkspaceMemberEvent.getWorkspaceMembers() =
      GetWorkspaceMembers;
  const factory WorkspaceMemberEvent.addWorkspaceMember(String email) =
      AddWorkspaceMember;
  const factory WorkspaceMemberEvent.removeWorkspaceMember(String email) =
      RemoveWorkspaceMember;
  const factory WorkspaceMemberEvent.updateWorkspaceMember(
    String email,
    AFRolePB role,
  ) = UpdateWorkspaceMember;
}

@freezed
class WorkspaceMemberState with _$WorkspaceMemberState {
  const factory WorkspaceMemberState({
    @Default([]) List<WorkspaceMemberPB> members,
    @Default(AFRolePB.Guest) AFRolePB myRole,
  }) = _WorkspaceMemberState;

  factory WorkspaceMemberState.initial() => const WorkspaceMemberState();
}
