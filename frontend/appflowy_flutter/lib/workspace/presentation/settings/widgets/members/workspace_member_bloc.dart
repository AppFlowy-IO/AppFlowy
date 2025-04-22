import 'dart:async';

import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/shared/af_role_pb_extension.dart';
import 'package:appflowy/shared/af_user_profile_extension.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/members/inivitation/member_http_service.dart';
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
    String? workspaceId,
    this.workspace,
  })  : _userBackendService = UserBackendService(userId: userProfile.id),
        super(WorkspaceMemberState.initial()) {
    on<WorkspaceMemberEvent>((event, emit) async {
      await event.when(
        initial: () async => _onInitial(emit, workspaceId),
        getWorkspaceMembers: () async => _onGetWorkspaceMembers(emit),
        addWorkspaceMember: (email) async => _onAddWorkspaceMember(emit, email),
        inviteWorkspaceMemberByEmail: (email) async =>
            _onInviteWorkspaceMemberByEmail(emit, email),
        removeWorkspaceMemberByEmail: (email) async =>
            _onRemoveWorkspaceMemberByEmail(emit, email),
        inviteWorkspaceMemberByLink: (link) async =>
            _onInviteWorkspaceMemberByLink(emit, link),
        generateInviteLink: () async => _onGenerateInviteLink(emit),
        updateWorkspaceMember: (email, role) async =>
            _onUpdateWorkspaceMember(emit, email, role),
        updateSubscriptionInfo: (info) async =>
            _onUpdateSubscriptionInfo(emit, info),
        upgradePlan: () async => _onUpgradePlan(),
      );
    });
  }

  final UserProfilePB userProfile;
  final UserWorkspacePB? workspace;
  late final String _workspaceId;
  final UserBackendService _userBackendService;
  MemberHttpService? _memberHttpService;

  Future<void> _onInitial(
    Emitter<WorkspaceMemberState> emit,
    String? workspaceId,
  ) async {
    await _setCurrentWorkspaceId(workspaceId);

    final result = await _userBackendService.getWorkspaceMembers(_workspaceId);
    final members = result.fold<List<WorkspaceMemberPB>>(
      (s) => s.items,
      (e) => [],
    );
    final myRole = _getMyRole(members);

    if (myRole.isOwner) {
      unawaited(_fetchWorkspaceSubscriptionInfo());
    }

    final baseUrl = await getAppFlowyCloudUrl();
    final authToken = userProfile.authToken;
    if (authToken != null) {
      _memberHttpService = MemberHttpService(
        baseUrl: baseUrl,
        authToken: authToken,
      );
      unawaited(
        _memberHttpService?.getInviteCode(workspaceId: _workspaceId).fold(
          (s) async {
            final inviteLink = await _buildInviteLink(inviteCode: s);
            emit(state.copyWith(inviteLink: inviteLink));
          },
          (e) => Log.info('Failed to get invite code: ${e.msg}', e),
        ),
      );
    } else {
      Log.error('Failed to get auth token');
    }

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
  }

  Future<void> _onGetWorkspaceMembers(
    Emitter<WorkspaceMemberState> emit,
  ) async {
    final result = await _userBackendService.getWorkspaceMembers(_workspaceId);
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
  }

  Future<void> _onAddWorkspaceMember(
    Emitter<WorkspaceMemberState> emit,
    String email,
  ) async {
    final result = await _userBackendService.addWorkspaceMember(
      _workspaceId,
      email,
    );
    emit(
      state.copyWith(
        actionResult: WorkspaceMemberActionResult(
          actionType: WorkspaceMemberActionType.addByEmail,
          result: result,
        ),
      ),
    );
    // the addWorkspaceMember doesn't return the updated members,
    //  so we need to get the members again
    result.onSuccess((s) {
      add(const WorkspaceMemberEvent.getWorkspaceMembers());
    });
  }

  Future<void> _onInviteWorkspaceMemberByEmail(
    Emitter<WorkspaceMemberState> emit,
    String email,
  ) async {
    final result = await _userBackendService.inviteWorkspaceMember(
      _workspaceId,
      email,
      role: AFRolePB.Member,
    );
    emit(
      state.copyWith(
        actionResult: WorkspaceMemberActionResult(
          actionType: WorkspaceMemberActionType.inviteByEmail,
          result: result,
        ),
      ),
    );
  }

  Future<void> _onRemoveWorkspaceMemberByEmail(
    Emitter<WorkspaceMemberState> emit,
    String email,
  ) async {
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
          actionType: WorkspaceMemberActionType.removeByEmail,
          result: result,
        ),
      ),
    );
  }

  Future<void> _onInviteWorkspaceMemberByLink(
    Emitter<WorkspaceMemberState> emit,
    String link,
  ) async {}

  Future<void> _onGenerateInviteLink(Emitter<WorkspaceMemberState> emit) async {
    final result = await _memberHttpService?.generateInviteCode(
      workspaceId: _workspaceId,
    );

    await result?.fold(
      (s) async {
        final inviteLink = await _buildInviteLink(inviteCode: s);
        emit(
          state.copyWith(
            inviteLink: inviteLink,
            actionResult: WorkspaceMemberActionResult(
              actionType: WorkspaceMemberActionType.generateInviteLink,
              result: result,
            ),
          ),
        );
      },
      (e) async {
        Log.error('Failed to generate invite link: ${e.msg}', e);
        emit(
          state.copyWith(
            actionResult: WorkspaceMemberActionResult(
              actionType: WorkspaceMemberActionType.generateInviteLink,
              result: result,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onUpdateWorkspaceMember(
    Emitter<WorkspaceMemberState> emit,
    String email,
    AFRolePB role,
  ) async {
    final result = await _userBackendService.updateWorkspaceMember(
      _workspaceId,
      email,
      role,
    );
    final members = result.fold(
      (s) => state.members.map((e) {
        if (e.email == email) {
          e.freeze();
          return e.rebuild((p0) => p0.role = role);
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
  }

  Future<void> _onUpdateSubscriptionInfo(
    Emitter<WorkspaceMemberState> emit,
    WorkspaceSubscriptionInfoPB info,
  ) async {
    emit(state.copyWith(subscriptionInfo: info));
  }

  Future<void> _onUpgradePlan() async {
    final plan = state.subscriptionInfo?.plan;
    if (plan == null) {
      return Log.error('Failed to upgrade plan: plan is null');
    }

    if (plan == WorkspacePlanPB.FreePlan) {
      final checkoutLink = await _userBackendService.createSubscription(
        _workspaceId,
        SubscriptionPlanPB.Pro,
      );

      checkoutLink.fold(
        (pl) => afLaunchUrlString(pl.paymentLink),
        (f) => Log.error('Failed to create subscription: ${f.msg}', f),
      );
    }
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

  Future<void> _setCurrentWorkspaceId(String? workspaceId) async {
    if (workspace != null) {
      _workspaceId = workspace!.workspaceId;
    } else if (workspaceId != null && workspaceId.isNotEmpty) {
      _workspaceId = workspaceId;
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

  Future<void> _fetchWorkspaceSubscriptionInfo() async {
    final result =
        await UserBackendService.getWorkspaceSubscriptionInfo(_workspaceId);

    result.fold(
      (info) {
        if (!isClosed) {
          add(WorkspaceMemberEvent.updateSubscriptionInfo(info));
        }
      },
      (f) => Log.error('Failed to fetch subscription info: ${f.msg}', f),
    );
  }

  Future<String> _buildInviteLink({required String inviteCode}) async {
    final baseUrl = await getAppFlowyShareDomain();
    final authToken = userProfile.authToken;
    if (authToken != null) {
      return '$baseUrl/app/invited/$inviteCode';
    }
    return '';
  }
}

@freezed
class WorkspaceMemberEvent with _$WorkspaceMemberEvent {
  const factory WorkspaceMemberEvent.initial() = Initial;
  const factory WorkspaceMemberEvent.getWorkspaceMembers() =
      GetWorkspaceMembers;
  const factory WorkspaceMemberEvent.addWorkspaceMember(String email) =
      AddWorkspaceMember;
  const factory WorkspaceMemberEvent.inviteWorkspaceMemberByEmail(
    String email,
  ) = InviteWorkspaceMemberByEmail;
  const factory WorkspaceMemberEvent.removeWorkspaceMemberByEmail(
    String email,
  ) = RemoveWorkspaceMemberByEmail;
  const factory WorkspaceMemberEvent.inviteWorkspaceMemberByLink(String link) =
      InviteWorkspaceMemberByLink;
  const factory WorkspaceMemberEvent.generateInviteLink() = GenerateInviteLink;
  const factory WorkspaceMemberEvent.updateWorkspaceMember(
    String email,
    AFRolePB role,
  ) = UpdateWorkspaceMember;
  const factory WorkspaceMemberEvent.updateSubscriptionInfo(
    WorkspaceSubscriptionInfoPB subscriptionInfo,
  ) = UpdateSubscriptionInfo;

  const factory WorkspaceMemberEvent.upgradePlan() = UpgradePlan;
}

enum WorkspaceMemberActionType {
  none,
  get,
  // this event will send an invitation to the member
  inviteByEmail,
  inviteByLink,
  generateInviteLink,
  // this event will add the member without sending an invitation
  addByEmail,
  removeByEmail,
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
    @Default(null) WorkspaceSubscriptionInfoPB? subscriptionInfo,
    @Default(null) String? inviteLink,
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
        other.subscriptionInfo == subscriptionInfo &&
        other.inviteLink == inviteLink &&
        identical(other.actionResult, actionResult);
  }
}
