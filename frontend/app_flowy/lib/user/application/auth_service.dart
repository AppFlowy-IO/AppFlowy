import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart' show SignInPayloadPB, SignUpPayloadPB, UserProfilePB;
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';

class AuthService {
  Future<Either<UserProfilePB, FlowyError>> signIn({required String? email, required String? password}) {
    //
    final request = SignInPayloadPB.create()
      ..email = email ?? ''
      ..password = password ?? '';

    return UserEventSignIn(request).send();
  }

  Future<Either<UserProfilePB, FlowyError>> signUp(
      {required String? name, required String? password, required String? email}) {
    final request = SignUpPayloadPB.create()
      ..email = email ?? ''
      ..name = name ?? ''
      ..password = password ?? '';

    return UserEventSignUp(request).send();

    // return UserEventSignUp(request).send().then((result) {
    //   return result.fold((userProfile) async {
    //     return await FolderEventCreateDefaultWorkspace().send().then((result) {
    //       return result.fold((workspaceIdentifier) {
    //         return left(Tuple2(userProfile, workspaceIdentifier.workspaceId));
    //       }, (error) {
    //         throw UnimplementedError;
    //       });
    //     });
    //   }, (error) => right(error));
    // });
  }

  Future<Either<Unit, FlowyError>> signOut() {
    return UserEventSignOut().send();
  }
}
