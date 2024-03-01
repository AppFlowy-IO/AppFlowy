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
//   - invite member button
//   - member list
//  Guest:
//   - member list
class WorkspaceMemberBloc
    extends Bloc<WorkspaceMemberEvent, WorkspaceMemberState> {
  WorkspaceMemberBloc({
    required this.userProfile,
  }) : super(WorkspaceMemberState.initial()) {
    on<WorkspaceMemberEvent>((event, emit) async {
      await event.map(
        getWorkspaceMembers: (_) async {
          final members = await _getWorkspaceMembers();
          final myRole = _getMyRole(members);
          emit(
            state.copyWith(
              members: members,
              myRole: myRole,
            ),
          );
        },
        addWorkspaceMember: (e) {},
        removeWorkspaceMember: (e) {},
        updateWorkspaceMember: (e) {},
      );
    });
  }

  final UserProfilePB userProfile;

  Future<List<WorkspaceMemberPB>> _getWorkspaceMembers() async {
    // will the current workspace be synced across the app?
    final currentWorkspace = await FolderEventReadCurrentWorkspace().send();
    return currentWorkspace.fold((s) async {
      final result = await UserEventGetWorkspaceMember(
        QueryWorkspacePB()..workspaceId = s.id,
      ).send();
      return result.fold((s) => s.items, (e) {
        Log.error('Failed to read workspace members: $e');
        return [];
      });
    }, (e) {
      Log.error('Failed to read current workspace: $e');
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
}

@freezed
class WorkspaceMemberEvent with _$WorkspaceMemberEvent {
  const factory WorkspaceMemberEvent.getWorkspaceMembers() =
      GetWorkspaceMembers;
  const factory WorkspaceMemberEvent.addWorkspaceMember(String email) =
      AddWorkspaceMember;
  const factory WorkspaceMemberEvent.removeWorkspaceMember(String email) =
      RemoveWorkspaceMember;
  const factory WorkspaceMemberEvent.updateWorkspaceMember(AFRolePB role) =
      UpdateWorkspaceMember;
}

@freezed
class WorkspaceMemberState with _$WorkspaceMemberState {
  const factory WorkspaceMemberState({
    @Default([]) List<WorkspaceMemberPB> members,
    @Default(AFRolePB.Guest) AFRolePB myRole,
  }) = _WorkspaceMemberState;

  factory WorkspaceMemberState.initial() => const WorkspaceMemberState();
}
