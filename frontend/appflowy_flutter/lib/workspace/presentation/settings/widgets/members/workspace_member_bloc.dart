import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
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
  })  : _userBackendService = UserBackendService(userId: userProfile.id),
        super(WorkspaceMemberState.initial()) {
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

          add(const WorkspaceMemberEvent.getWorkspaceMembers());
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
          final result = await _userBackendService.addWorkspaceMember(
            workspaceId,
            email,
          );
          emit(state.copyWith(addMemberResult: result));
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
  late final UserBackendService _userBackendService;

  Future<List<WorkspaceMemberPB>> _getWorkspaceMembers() async {
    return _userBackendService.getWorkspaceMembers(workspaceId).fold(
      (s) => s.items,
      (e) {
        Log.error('Failed to read workspace members: $e');
        return [];
      },
    );
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

  Future<void> _removeWorkspaceMember(String email) async {
    return _userBackendService.removeWorkspaceMember(workspaceId, email).fold(
          (s) => Log.debug('Removed workspace member: $email'),
          (e) => Log.error('Failed to remove workspace member: $e'),
        );
  }

  Future<void> _updateWorkspaceMember(String email, AFRolePB role) async {
    return _userBackendService
        .updateWorkspaceMember(workspaceId, email, role)
        .fold(
          (s) => Log.debug('Updated workspace member: $email'),
          (e) => Log.error('Failed to update workspace member: $e'),
        );
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
  const WorkspaceMemberState._();

  const factory WorkspaceMemberState({
    @Default([]) List<WorkspaceMemberPB> members,
    @Default(AFRolePB.Guest) AFRolePB myRole,
    @Default(null) FlowyResult<void, FlowyError>? addMemberResult,
  }) = _WorkspaceMemberState;

  factory WorkspaceMemberState.initial() => const WorkspaceMemberState();

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WorkspaceMemberState &&
        other.members == members &&
        other.myRole == myRole &&
        identical(other.addMemberResult, addMemberResult);
  }
}
