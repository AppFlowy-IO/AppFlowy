import 'dart:async';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/settings/plan/workspace_subscription_ext.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:fixnum/fixnum.dart';

abstract class IUserBackendService {
  Future<FlowyResult<void, FlowyError>> cancelSubscription(
    String workspaceId,
    SubscriptionPlanPB plan,
  );
  Future<FlowyResult<PaymentLinkPB, FlowyError>> createSubscription(
    String workspaceId,
    SubscriptionPlanPB plan,
  );
}

class UserBackendService implements IUserBackendService {
  UserBackendService({required this.userId});

  final Int64 userId;

  static Future<FlowyResult<UserProfilePB, FlowyError>>
      getCurrentUserProfile() async {
    final result = await UserEventGetUserProfile().send();
    return result;
  }

  Future<FlowyResult<void, FlowyError>> updateUserProfile({
    String? name,
    String? password,
    String? email,
    String? iconUrl,
    String? openAIKey,
    String? stabilityAiKey,
  }) {
    final payload = UpdateUserProfilePayloadPB.create()..id = userId;

    if (name != null) {
      payload.name = name;
    }

    if (password != null) {
      payload.password = password;
    }

    if (email != null) {
      payload.email = email;
    }

    if (iconUrl != null) {
      payload.iconUrl = iconUrl;
    }

    if (openAIKey != null) {
      payload.openaiKey = openAIKey;
    }

    if (stabilityAiKey != null) {
      payload.stabilityAiKey = stabilityAiKey;
    }

    return UserEventUpdateUserProfile(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> deleteWorkspace({
    required String workspaceId,
  }) {
    throw UnimplementedError();
  }

  static Future<FlowyResult<UserProfilePB, FlowyError>> signInWithMagicLink(
    String email,
    String redirectTo,
  ) async {
    final payload = MagicLinkSignInPB(email: email, redirectTo: redirectTo);
    return UserEventMagicLinkSignIn(payload).send();
  }

  static Future<FlowyResult<void, FlowyError>> signOut() {
    return UserEventSignOut().send();
  }

  Future<FlowyResult<void, FlowyError>> initUser() async {
    return UserEventInitUser().send();
  }

  static Future<FlowyResult<UserProfilePB, FlowyError>> getAnonUser() async {
    return UserEventGetAnonUser().send();
  }

  static Future<FlowyResult<void, FlowyError>> openAnonUser() async {
    return UserEventOpenAnonUser().send();
  }

  Future<FlowyResult<List<UserWorkspacePB>, FlowyError>> getWorkspaces() {
    return UserEventGetAllWorkspace().send().then((value) {
      return value.fold(
        (workspaces) => FlowyResult.success(workspaces.items),
        (error) => FlowyResult.failure(error),
      );
    });
  }

  Future<FlowyResult<void, FlowyError>> openWorkspace(String workspaceId) {
    final payload = UserWorkspaceIdPB.create()..workspaceId = workspaceId;
    return UserEventOpenWorkspace(payload).send();
  }

  static Future<FlowyResult<WorkspacePB, FlowyError>> getCurrentWorkspace() {
    return FolderEventReadCurrentWorkspace().send().then((result) {
      return result.fold(
        (workspace) => FlowyResult.success(workspace),
        (error) => FlowyResult.failure(error),
      );
    });
  }

  Future<FlowyResult<WorkspacePB, FlowyError>> createWorkspace(
    String name,
    String desc,
  ) {
    final request = CreateWorkspacePayloadPB.create()
      ..name = name
      ..desc = desc;
    return FolderEventCreateFolderWorkspace(request).send().then((result) {
      return result.fold(
        (workspace) => FlowyResult.success(workspace),
        (error) => FlowyResult.failure(error),
      );
    });
  }

  Future<FlowyResult<UserWorkspacePB, FlowyError>> createUserWorkspace(
    String name,
  ) {
    final request = CreateWorkspacePB.create()..name = name;
    return UserEventCreateWorkspace(request).send();
  }

  Future<FlowyResult<void, FlowyError>> deleteWorkspaceById(
    String workspaceId,
  ) {
    final request = UserWorkspaceIdPB.create()..workspaceId = workspaceId;
    return UserEventDeleteWorkspace(request).send();
  }

  Future<FlowyResult<void, FlowyError>> renameWorkspace(
    String workspaceId,
    String name,
  ) {
    final request = RenameWorkspacePB()
      ..workspaceId = workspaceId
      ..newName = name;
    return UserEventRenameWorkspace(request).send();
  }

  Future<FlowyResult<void, FlowyError>> updateWorkspaceIcon(
    String workspaceId,
    String icon,
  ) {
    final request = ChangeWorkspaceIconPB()
      ..workspaceId = workspaceId
      ..newIcon = icon;
    return UserEventChangeWorkspaceIcon(request).send();
  }

  Future<FlowyResult<RepeatedWorkspaceMemberPB, FlowyError>>
      getWorkspaceMembers(
    String workspaceId,
  ) async {
    final data = QueryWorkspacePB()..workspaceId = workspaceId;
    return UserEventGetWorkspaceMembers(data).send();
  }

  Future<FlowyResult<void, FlowyError>> addWorkspaceMember(
    String workspaceId,
    String email,
  ) async {
    final data = AddWorkspaceMemberPB()
      ..workspaceId = workspaceId
      ..email = email;
    return UserEventAddWorkspaceMember(data).send();
  }

  Future<FlowyResult<void, FlowyError>> inviteWorkspaceMember(
    String workspaceId,
    String email, {
    AFRolePB? role,
  }) async {
    final data = WorkspaceMemberInvitationPB()
      ..workspaceId = workspaceId
      ..inviteeEmail = email;
    if (role != null) {
      data.role = role;
    }
    return UserEventInviteWorkspaceMember(data).send();
  }

  Future<FlowyResult<void, FlowyError>> removeWorkspaceMember(
    String workspaceId,
    String email,
  ) async {
    final data = RemoveWorkspaceMemberPB()
      ..workspaceId = workspaceId
      ..email = email;
    return UserEventRemoveWorkspaceMember(data).send();
  }

  Future<FlowyResult<void, FlowyError>> updateWorkspaceMember(
    String workspaceId,
    String email,
    AFRolePB role,
  ) async {
    final data = UpdateWorkspaceMemberPB()
      ..workspaceId = workspaceId
      ..email = email
      ..role = role;
    return UserEventUpdateWorkspaceMember(data).send();
  }

  Future<FlowyResult<void, FlowyError>> leaveWorkspace(
    String workspaceId,
  ) async {
    final data = UserWorkspaceIdPB.create()..workspaceId = workspaceId;
    return UserEventLeaveWorkspace(data).send();
  }

  static Future<FlowyResult<WorkspaceSubscriptionInfoPB, FlowyError>>
      getWorkspaceSubscriptionInfo(String workspaceId) {
    final params = UserWorkspaceIdPB.create()..workspaceId = workspaceId;
    return UserEventGetWorkspaceSubscriptionInfo(params).send();
  }

  static Future<FlowyResult<void, FlowyError>>
      invalidateWorkspaceSubscriptionCache(String workspaceId) {
    final params = UserWorkspaceIdPB.create()..workspaceId = workspaceId;
    return UserEventInvalidateWorkspaceSubscriptionInfoCache(params).send();
  }

  Future<FlowyResult<WorkspaceMemberPB, FlowyError>>
      getWorkspaceMember() async {
    final data = WorkspaceMemberIdPB.create()..uid = userId;

    return UserEventGetMemberInfo(data).send();
  }

  @override
  Future<FlowyResult<PaymentLinkPB, FlowyError>> createSubscription(
    String workspaceId,
    SubscriptionPlanPB plan,
  ) {
    final request = SubscribeWorkspacePB()
      ..workspaceId = workspaceId
      ..recurringInterval = RecurringIntervalPB.Year
      ..workspaceSubscriptionPlan = plan
      ..successUrl =
          '${getIt<AppFlowyCloudSharedEnv>().appflowyCloudConfig.base_url}/web/payment-success?plan=${plan.toRecognizable()}';
    return UserEventSubscribeWorkspace(request).send();
  }

  @override
  Future<FlowyResult<void, FlowyError>> cancelSubscription(
    String workspaceId,
    SubscriptionPlanPB plan,
  ) {
    final request = CancelWorkspaceSubscriptionPB()
      ..workspaceId = workspaceId
      ..plan = plan;

    return UserEventCancelWorkspaceSubscription(request).send();
  }
}
