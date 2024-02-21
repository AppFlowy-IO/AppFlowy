import 'dart:async';

import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:dartz/dartz.dart';
import 'package:fixnum/fixnum.dart';

class UserBackendService {
  UserBackendService({
    required this.userId,
  });

  final Int64 userId;

  static Future<Either<FlowyError, UserProfilePB>>
      getCurrentUserProfile() async {
    final result = await UserEventGetUserProfile().send();
    return result.swap();
  }

  Future<Either<Unit, FlowyError>> updateUserProfile({
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

  Future<Either<Unit, FlowyError>> deleteWorkspace({
    required String workspaceId,
  }) {
    throw UnimplementedError();
  }

  static Future<Either<Unit, FlowyError>> signOut() {
    return UserEventSignOut().send();
  }

  Future<Either<Unit, FlowyError>> initUser() async {
    return UserEventInitUser().send();
  }

  static Future<Either<UserProfilePB, FlowyError>> getAnonUser() async {
    return UserEventGetAnonUser().send();
  }

  static Future<Either<Unit, FlowyError>> openAnonUser() async {
    return UserEventOpenAnonUser().send();
  }

  Future<Either<List<UserWorkspacePB>, FlowyError>> getWorkspaces() {
    return UserEventGetAllWorkspace().send().then((value) {
      return value.fold(
        (workspaces) => left(workspaces.items),
        (error) => right(error),
      );
    });
  }

  Future<Either<Unit, FlowyError>> openWorkspace(String workspaceId) {
    final payload = UserWorkspaceIdPB.create()..workspaceId = workspaceId;
    return UserEventOpenWorkspace(payload).send();
  }

  Future<Either<WorkspacePB, FlowyError>> getCurrentWorkspace() {
    return FolderEventReadCurrentWorkspace().send().then((result) {
      return result.fold(
        (workspace) => left(workspace),
        (error) => right(error),
      );
    });
  }

  Future<Either<WorkspacePB, FlowyError>> createWorkspace(
    String name,
    String desc,
  ) {
    final request = CreateWorkspacePayloadPB.create()
      ..name = name
      ..desc = desc;
    return FolderEventCreateWorkspace(request).send().then((result) {
      return result.fold(
        (workspace) => left(workspace),
        (error) => right(error),
      );
    });
  }

  Future<Either<UserWorkspacePB, FlowyError>> createUserWorkspace(
    String name,
  ) {
    final request = CreateWorkspacePB.create()..name = name;
    return UserEventCreateWorkspace(request).send().then((result) {
      return result.fold(
        (workspace) => left(workspace),
        (error) => right(error),
      );
    });
  }

  Future<Either<Unit, FlowyError>> deleteWorkspaceById(String workspaceId) {
    final request = UserWorkspaceIdPB.create()..workspaceId = workspaceId;
    return UserEventDeleteWorkspace(request).send();
  }
}
