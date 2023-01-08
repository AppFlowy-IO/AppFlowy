import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show SignInPayloadPB, SignUpPayloadPB, UserProfilePB;

import '../../generated/locale_keys.g.dart';

class AuthService {
  Future<Either<UserProfilePB, FlowyError>> signIn(
      {required String? email, required String? password}) {
    //
    final request = SignInPayloadPB.create()
      ..email = email ?? ''
      ..password = password ?? '';

    return UserEventSignIn(request).send();
  }

  Future<Either<UserProfilePB, FlowyError>> signUp(
      {required String? name,
      required String? password,
      required String? email}) {
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

  Future<Either<UserProfilePB, FlowyError>> signUpWithRandomUser() {
    const password = "AppFlowy123@";
    final uid = uuid();
    final userEmail = "$uid@appflowy.io";
    return signUp(
      name: LocaleKeys.defaultUsername.tr(),
      password: password,
      email: userEmail,
    );
  }
}
