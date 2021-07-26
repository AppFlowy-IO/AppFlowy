import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-user/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_detail.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/workspace_create.pb.dart';

class UserRepo {
  final UserDetail user;
  UserRepo({
    required this.user,
  });

  Future<Either<UserDetail, UserError>> fetchUserDetail(
      {required String userId}) {
    return UserEventGetStatus().send();
  }

  Future<Either<Unit, WorkspaceError>> deleteWorkspace(
      {required String workspaceId}) {
    throw UnimplementedError();
  }

  Future<Either<Unit, UserError>> signOut() {
    return UserEventSignOut().send();
  }

  Future<Either<List<Workspace>, WorkspaceError>> fetchWorkspaces() {
    return WorkspaceEventReadAllWorkspace().send().then((result) {
      return result.fold(
        (workspaces) => left(workspaces.items),
        (r) => right(r),
      );
    });
  }
}
