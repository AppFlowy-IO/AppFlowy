import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart';

class AuthRepository {
  Future<Either<UserProfile, UserError>> signIn({required String? email, required String? password}) {
    //
    final request = SignInRequest.create()
      ..email = email ?? ''
      ..password = password ?? '';

    return UserEventSignIn(request).send();
  }

  Future<Either<Tuple2<UserProfile, String>, UserError>> signUp(
      {required String? name, required String? password, required String? email}) {
    final request = SignUpRequest.create()
      ..email = email ?? ''
      ..name = name ?? ''
      ..password = password ?? '';

    return UserEventSignUp(request).send().then((result) {
      return result.fold((userProfile) async {
        return await WorkspaceEventCreateDefaultWorkspace().send().then((result) {
          return result.fold((workspaceIdentifier) {
            return left(Tuple2(userProfile, workspaceIdentifier.workspaceId));
          }, (error) {
            throw UnimplementedError;
          });
        });
      }, (error) => right(error));
    });
  }

  Future<Either<Unit, UserError>> signOut() {
    return UserEventSignOut().send();
  }
}
