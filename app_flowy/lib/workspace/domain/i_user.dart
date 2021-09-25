import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-user/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/workspace_create.pb.dart';

export 'package:flowy_sdk/protobuf/flowy-workspace/workspace_create.pb.dart';
export 'package:flowy_sdk/protobuf/flowy-user/errors.pb.dart';
export 'package:flowy_sdk/protobuf/flowy-user/user_profile.pb.dart';

abstract class IUser {
  UserProfile get user;
  Future<Either<UserProfile, UserError>> fetchUserProfile(String userId);
  Future<Either<List<Workspace>, WorkspaceError>> fetchWorkspaces();
  Future<Either<Unit, WorkspaceError>> deleteWorkspace(String workspaceId);
  Future<Either<Unit, UserError>> signOut();
  Future<Either<Unit, UserError>> initUser();
}

typedef UserProfileUpdateCallback = void Function(
    Either<UserProfile, UserError>);

typedef AuthChangedCallback = void Function(Either<Unit, UserError>);
typedef WorkspacesUpdatedCallback = void Function(
    Either<List<Workspace>, WorkspaceError> workspacesOrFailed);

abstract class IUserWatch {
  void startWatching();
  void setProfileCallback(UserProfileUpdateCallback profileCallback);
  void setAuthCallback(AuthChangedCallback authCallback);
  void setWorkspacesCallback(WorkspacesUpdatedCallback workspacesCallback);

  Future<void> stopWatching();
}
