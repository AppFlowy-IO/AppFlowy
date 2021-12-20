import 'package:dartz/dartz.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user-data-model/protobuf.dart' show UserProfile;
import 'package:flowy_sdk/protobuf/flowy-core-data-model/workspace_create.pb.dart';
export 'package:flowy_sdk/protobuf/flowy-user-data-model/protobuf.dart' show UserProfile;

abstract class IUser {
  UserProfile get user;
  Future<Either<UserProfile, FlowyError>> fetchUserProfile(String userId);
  Future<Either<List<Workspace>, FlowyError>> fetchWorkspaces();
  Future<Either<Unit, FlowyError>> deleteWorkspace(String workspaceId);
  Future<Either<Unit, FlowyError>> signOut();
  Future<Either<Unit, FlowyError>> initUser();
}

typedef UserProfileUpdatedNotifierValue = Either<UserProfile, FlowyError>;
typedef AuthNotifierValue = Either<Unit, FlowyError>;
typedef WorkspaceUpdatedNotifierValue = Either<List<Workspace>, FlowyError>;

abstract class IUserListener {
  void start();

  PublishNotifier<UserProfileUpdatedNotifierValue> get profileUpdatedNotifier;
  PublishNotifier<AuthNotifierValue> get authDidChangedNotifier;
  PublishNotifier<WorkspaceUpdatedNotifierValue> get workspaceUpdatedNotifier;

  Future<void> stop();
}
