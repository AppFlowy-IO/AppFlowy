import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-user/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/workspace_create.pb.dart';

export 'package:flowy_sdk/protobuf/flowy-workspace/workspace_create.pb.dart';
export 'package:flowy_sdk/protobuf/flowy-user/errors.pb.dart';
export 'package:flowy_sdk/protobuf/flowy-user/user_profile.pb.dart';

typedef UserCreateWorkspaceCallback = void Function(
    Either<List<Workspace>, WorkspaceError> workspacesOrFailed);
typedef UserDeleteWorkspaceCallback = void Function(
    Either<List<Workspace>, WorkspaceError> workspacesOrFailed);

abstract class IUser {
  UserProfile get user;
  Future<Either<UserProfile, UserError>> fetchUserProfile(String userId);
  Future<Either<List<Workspace>, WorkspaceError>> fetchWorkspaces();
  Future<Either<Unit, WorkspaceError>> deleteWorkspace(String workspaceId);
  Future<Either<Unit, UserError>> signOut();
}

abstract class IUserWatch {
  void startWatching(
      {UserCreateWorkspaceCallback? createWorkspaceCallback,
      UserDeleteWorkspaceCallback? deleteWorkspaceCallback});

  Future<void> stopWatching();
}
