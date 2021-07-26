import 'package:dartz/dartz.dart';

import 'package:app_flowy/workspace/domain/i_user.dart';
import 'package:app_flowy/workspace/infrastructure/repos/user_repo.dart';
export 'package:app_flowy/workspace/domain/i_user.dart';
export 'package:app_flowy/workspace/infrastructure/repos/user_repo.dart';

class IUserImpl extends IUser {
  UserRepo repo;
  IUserImpl({
    required this.repo,
  });

  @override
  Future<Either<Unit, WorkspaceError>> deleteWorkspace(String workspaceId) {
    // TODO: implement deleteWorkspace
    throw UnimplementedError();
  }

  @override
  Future<Either<UserDetail, UserError>> fetchUserDetail(String userId) {
    return repo.fetchUserDetail(userId: userId);
  }

  @override
  Future<Either<Unit, UserError>> signOut() {
    // TODO: implement signOut
    throw UnimplementedError();
  }
}
