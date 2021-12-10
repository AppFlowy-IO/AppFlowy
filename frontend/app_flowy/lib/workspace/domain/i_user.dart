import 'package:dartz/dartz.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:flowy_sdk/protobuf/flowy-user/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user-infra/protobuf.dart' show UserProfile;
import 'package:flowy_sdk/protobuf/flowy-core-infra/workspace_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-core/errors.pb.dart';
export 'package:flowy_sdk/protobuf/flowy-user/errors.pb.dart';
export 'package:flowy_sdk/protobuf/flowy-user-infra/protobuf.dart' show UserProfile;

abstract class IUser {
  UserProfile get user;
  Future<Either<UserProfile, UserError>> fetchUserProfile(String userId);
  Future<Either<List<Workspace>, WorkspaceError>> fetchWorkspaces();
  Future<Either<Unit, WorkspaceError>> deleteWorkspace(String workspaceId);
  Future<Either<Unit, UserError>> signOut();
  Future<Either<Unit, UserError>> initUser();
}

typedef UserProfileUpdatedNotifierValue = Either<UserProfile, UserError>;
typedef AuthNotifierValue = Either<Unit, UserError>;
typedef WorkspaceUpdatedNotifierValue = Either<List<Workspace>, WorkspaceError>;

abstract class IUserListener {
  void start();

  PublishNotifier<UserProfileUpdatedNotifierValue> get profileUpdatedNotifier;
  PublishNotifier<AuthNotifierValue> get authDidChangedNotifier;
  PublishNotifier<WorkspaceUpdatedNotifierValue> get workspaceUpdatedNotifier;

  Future<void> stop();
}
