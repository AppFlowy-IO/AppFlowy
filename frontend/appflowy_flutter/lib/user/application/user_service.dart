import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';

class UserBackendService {
  UserBackendService({
    required this.userId,
  });

  final String userId;

  static Future<Either<UserProfilePB, FlowyError>> getCurrentUserProfile() {
    return UserEventGetUserProfile().send();
  }

  Future<Either<Unit, FlowyError>> updateUserProfile({
    final String? name,
    final String? password,
    final String? email,
    final String? iconUrl,
    final String? openAIKey,
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

    return UserEventUpdateUserProfile(payload).send();
  }

  Future<Either<Unit, FlowyError>> deleteWorkspace({
    required final String workspaceId,
  }) {
    throw UnimplementedError();
  }

  Future<Either<Unit, FlowyError>> signOut() {
    return UserEventSignOut().send();
  }

  Future<Either<Unit, FlowyError>> initUser() async {
    return UserEventInitUser().send();
  }

  Future<Either<List<WorkspacePB>, FlowyError>> getWorkspaces() {
    final request = WorkspaceIdPB.create();

    return FolderEventReadWorkspaces(request).send().then((final result) {
      return result.fold(
        (final workspaces) => left(workspaces.items),
        (final error) => right(error),
      );
    });
  }

  Future<Either<WorkspacePB, FlowyError>> openWorkspace(final String workspaceId) {
    final request = WorkspaceIdPB.create()..value = workspaceId;
    return FolderEventOpenWorkspace(request).send().then((final result) {
      return result.fold(
        (final workspace) => left(workspace),
        (final error) => right(error),
      );
    });
  }

  Future<Either<WorkspacePB, FlowyError>> createWorkspace(
    final String name,
    final String desc,
  ) {
    final request = CreateWorkspacePayloadPB.create()
      ..name = name
      ..desc = desc;
    return FolderEventCreateWorkspace(request).send().then((final result) {
      return result.fold(
        (final workspace) => left(workspace),
        (final error) => right(error),
      );
    });
  }
}
