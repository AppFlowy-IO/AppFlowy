import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/workspace.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_profile.pb.dart';

class UserService {
  final String userId;
  UserService({
    required this.userId,
  });
  Future<Either<UserProfilePB, FlowyError>> getUserProfile(
      {required String userId}) {
    return UserEventGetUserProfile().send();
  }

  Future<Either<Unit, FlowyError>> updateUserProfile({
    String? name,
    String? password,
    String? email,
    String? iconUrl,
  }) {
    var payload = UpdateUserProfilePayloadPB.create()..id = userId;

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

    return UserEventUpdateUserProfile(payload).send();
  }

  Future<Either<Unit, FlowyError>> deleteWorkspace(
      {required String workspaceId}) {
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

    return FolderEventReadWorkspaces(request).send().then((result) {
      return result.fold(
        (workspaces) => left(workspaces.items),
        (error) => right(error),
      );
    });
  }

  Future<Either<WorkspacePB, FlowyError>> openWorkspace(String workspaceId) {
    final request = WorkspaceIdPB.create()..value = workspaceId;
    return FolderEventOpenWorkspace(request).send().then((result) {
      return result.fold(
        (workspace) => left(workspace),
        (error) => right(error),
      );
    });
  }

  Future<Either<WorkspacePB, FlowyError>> createWorkspace(
      String name, String desc) {
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
}
