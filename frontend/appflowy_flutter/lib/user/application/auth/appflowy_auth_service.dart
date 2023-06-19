import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/protobuf/flowy-user/auth.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show SignInPayloadPB, SignUpPayloadPB, UserProfilePB;

import '../../../generated/locale_keys.g.dart';

class AppFlowyAuthService implements AuthService {
  @override
  Future<Either<FlowyError, UserProfilePB>> signIn({
    required String email,
    required String password,
    AuthTypePB authType = AuthTypePB.Local,
    Map<String, String> map = const {},
  }) async {
    final request = SignInPayloadPB.create()
      ..email = email
      ..password = password
      ..authType = authType;
    final response = UserEventSignIn(request).send();
    return response.then((value) => value.swap());
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> signUp({
    required String name,
    required String email,
    required String password,
    AuthTypePB authType = AuthTypePB.Local,
    Map<String, String> map = const {},
  }) async {
    final request = SignUpPayloadPB.create()
      ..name = name
      ..email = email
      ..password = password
      ..authType = authType;
    final response = await UserEventSignUp(request).send().then(
          (value) => value.swap(),
        );
    return response;
  }

  @override
  Future<void> signOut({
    AuthTypePB authType = AuthTypePB.Local,
    Map<String, String> map = const {},
  }) async {
    final payload = SignOutPB()..authType = authType;
    await UserEventSignOut(payload).send();
    return;
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> signUpAsGuest({
    AuthTypePB authType = AuthTypePB.Local,
    Map<String, String> map = const {},
  }) {
    const password = "AppFlowy123@";
    final uid = uuid();
    final userEmail = "$uid@appflowy.io";
    return signUp(
      name: LocaleKeys.defaultUsername.tr(),
      password: password,
      email: userEmail,
    );
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> signUpWithOAuth({
    required String platform,
    AuthTypePB authType = AuthTypePB.Local,
    Map<String, String> map = const {},
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> getUser() async {
    return UserBackendService.getCurrentUserProfile();
  }
}
