import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
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
    on<WorkspaceMemberEvent>((event, emit) {
      event.map(
        getWorkspaceMembers: (_) {
          _getWorkspaceMembers(emit);
        },
        addWorkspaceMember: (e) {},
        removeWorkspaceMember: (e) {},
        updateWorkspaceMember: (e) {},
      );
    });
  }

  final UserProfilePB userProfile;

  Future<void> _getWorkspaceMembers(Emitter emit) async {
    // will the current workspace be synced across the app?
    final currentWorkspace = await FolderEventReadCurrentWorkspace().send();
    return currentWorkspace.onSuccess((s) async {
      final result = await UserEventGetWorkspaceMember(
        QueryWorkspacePB()..workspaceId = s.id,
      ).send();
      return result.onSuccess((s) {
        emit(
          WorkspaceMemberState(
            members: s.items,
            myRole: s.items
                .firstWhere(
                  (e) => e.email == userProfile.email,
                  orElse: () => WorkspaceMemberPB()..role = AFRolePB.Guest,
                )
                .role,
          ),
        );
      });
    });
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
