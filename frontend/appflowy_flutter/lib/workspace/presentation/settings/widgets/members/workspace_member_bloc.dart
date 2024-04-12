import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';

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
          await _setCurrentWorkspaceId();

          final result = await _userBackendService.getWorkspaceMembers(
            _workspaceId,
          );
          final members = result.fold<List<WorkspaceMemberPB>>(
            (s) => s.items,
            (e) => [],
          );
          final myRole = _getMyRole(members);
          emit(
            state.copyWith(
              members: members,
              myRole: myRole,
              isLoading: false,
              actionResult: WorkspaceMemberActionResult(
                actionType: WorkspaceMemberActionType.get,
                result: result,
              ),
            ),
          );
        },
        getWorkspaceMembers: () async {
          final result = await _userBackendService.getWorkspaceMembers(
            _workspaceId,
          );
          final members = result.fold<List<WorkspaceMemberPB>>(
            (s) => s.items,
            (e) => [],
          );
          final myRole = _getMyRole(members);
          emit(
            state.copyWith(
              members: members,
              myRole: myRole,
              actionResult: WorkspaceMemberActionResult(
                actionType: WorkspaceMemberActionType.get,
                result: result,
              ),
            ),
          );
        },
        addWorkspaceMember: (email) async {
          final result = await _userBackendService.addWorkspaceMember(
            _workspaceId,
            email,
          );
          emit(
            state.copyWith(
              actionResult: WorkspaceMemberActionResult(
                actionType: WorkspaceMemberActionType.add,
                result: result,
              ),
            ),
          );
          // the addWorkspaceMember doesn't return the updated members,
          //  so we need to get the members again
          result.onSuccess((s) {
            add(const WorkspaceMemberEvent.getWorkspaceMembers());
          });
        },
        inviteWorkspaceMember: (email) async {
          final result = await _userBackendService.inviteWorkspaceMember(
            _workspaceId,
            email,
          );
          emit(
            state.copyWith(
              actionResult: WorkspaceMemberActionResult(
                actionType: WorkspaceMemberActionType.invite,
                result: result,
              ),
            ),
          );
        },
        removeWorkspaceMember: (email) async {
          final result = await _userBackendService.removeWorkspaceMember(
            _workspaceId,
            email,
          );
          final members = result.fold(
            (s) => state.members.where((e) => e.email != email).toList(),
            (e) => state.members,
          );
          emit(
            state.copyWith(
              members: members,
              actionResult: WorkspaceMemberActionResult(
                actionType: WorkspaceMemberActionType.remove,
                result: result,
              ),
            ),
          );
        },
        updateWorkspaceMember: (email, role) async {
          final result = await _userBackendService.updateWorkspaceMember(
            _workspaceId,
            email,
            role,
          );
          final members = result.fold(
            (s) => state.members.map((e) {
              if (e.email == email) {
                e.freeze();
                return e.rebuild((p0) {
                  p0.role = role;
                });
              }
              return e;
            }).toList(),
            (e) => state.members,
          );
          emit(
            state.copyWith(
              members: members,
              actionResult: WorkspaceMemberActionResult(
                actionType: WorkspaceMemberActionType.updateRole,
                result: result,
              ),
            ),
          );
        },
      );
    });
  }

  final UserProfilePB userProfile;

  // if the workspace is null, use the current workspace
  final UserWorkspacePB? workspace;

  late final String _workspaceId;
  final UserBackendService _userBackendService;

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

  Future<void> _setCurrentWorkspaceId() async {
    if (workspace != null) {
      _workspaceId = workspace!.workspaceId;
    } else {
      final currentWorkspace = await FolderEventReadCurrentWorkspace().send();
      currentWorkspace.fold((s) {
        _workspaceId = s.id;
      }, (e) {
        assert(false, 'Failed to read current workspace: $e');
        Log.error('Failed to read current workspace: $e');
        _workspaceId = '';
      });
    }
  }
}

@freezed
class WorkspaceMemberEvent with _$WorkspaceMemberEvent {
  const factory WorkspaceMemberEvent.initial() = Initial;
  const factory WorkspaceMemberEvent.getWorkspaceMembers() =
      GetWorkspaceMembers;
  const factory WorkspaceMemberEvent.addWorkspaceMember(String email) =
      AddWorkspaceMember;
  const factory WorkspaceMemberEvent.inviteWorkspaceMember(String email) =
      InviteWorkspaceMember;
  const factory WorkspaceMemberEvent.removeWorkspaceMember(String email) =
      RemoveWorkspaceMember;
  const factory WorkspaceMemberEvent.updateWorkspaceMember(
    String email,
    AFRolePB role,
  ) = UpdateWorkspaceMember;
}

enum WorkspaceMemberActionType {
  none,
  get,
  // this event will send an invitation to the member
  invite,
  // this event will add the member without sending an invitation
  add,
  remove,
  updateRole,
}

class WorkspaceMemberActionResult {
  const WorkspaceMemberActionResult({
    required this.actionType,
    required this.result,
  });

  final WorkspaceMemberActionType actionType;
  final FlowyResult<void, FlowyError> result;
}

@freezed
class WorkspaceMemberState with _$WorkspaceMemberState {
  const WorkspaceMemberState._();

  const factory WorkspaceMemberState({
    @Default([]) List<WorkspaceMemberPB> members,
    @Default(AFRolePB.Guest) AFRolePB myRole,
    @Default(null) WorkspaceMemberActionResult? actionResult,
    @Default(true) bool isLoading,
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
        identical(other.actionResult, actionResult);
  }
}
