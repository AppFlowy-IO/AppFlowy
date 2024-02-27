import 'dart:async';

import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:fixnum/fixnum.dart';

class UserBackendService {
  UserBackendService({
    required this.userId,
  });

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

  Future<FlowyResult<List<WorkspacePB>, FlowyError>> getWorkspaces() {
    // final request = WorkspaceIdPB.create();
    // return FolderEventReadAllWorkspaces(request).send().then((result) {
    //   return result.fold(
    //     (workspaces) => FlowyResult.success(workspaces.items),
    //     (error) => FlowyResult.failure(error),
    //   );
    // });
    return Future.value(FlowyResult.success([]));
  }

  Future<FlowyResult<void, FlowyError>> openWorkspace(String workspaceId) {
    final payload = UserWorkspaceIdPB.create()..workspaceId = workspaceId;
    return UserEventOpenWorkspace(payload).send();
  }

  Future<FlowyResult<WorkspacePB, FlowyError>> getCurrentWorkspace() {
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
    return FolderEventCreateWorkspace(request).send().then((result) {
      return result.fold(
        (workspace) => FlowyResult.success(workspace),
        (error) => FlowyResult.failure(error),
      );
    });
  }
}
