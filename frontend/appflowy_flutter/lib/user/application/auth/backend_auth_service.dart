import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/auth.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show SignInPayloadPB, SignUpPayloadPB, UserProfilePB;

import '../../../generated/locale_keys.g.dart';
import 'device_id.dart';

class BackendAuthService implements AuthService {
  final AuthTypePB authType;

  BackendAuthService(this.authType);

  @override
  Future<Either<FlowyError, UserProfilePB>> signInWithEmailPassword({
    required String email,
    required String password,
    Map<String, String> params = const {},
  }) async {
    final request = SignInPayloadPB.create()
      ..email = email
      ..password = password
      ..authType = authType
      ..deviceId = await getDeviceId();
    final response = UserEventSignInWithEmailPassword(request).send();
    return response.then((value) => value.swap());
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> signUp({
    required String name,
    required String email,
    required String password,
    Map<String, String> params = const {},
  }) async {
    final request = SignUpPayloadPB.create()
      ..name = name
      ..email = email
      ..password = password
      ..authType = authType
      ..deviceId = await getDeviceId();
    final response = await UserEventSignUp(request).send().then(
          (value) => value.swap(),
        );
    return response;
  }

  @override
  Future<void> signOut({
    Map<String, String> params = const {},
  }) async {
    await UserEventSignOut().send();
    return;
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> signUpAsGuest({
    Map<String, String> params = const {},
  }) async {
    const password = "Guest!@123456";
    final uid = uuid();
    final userEmail = "$uid@appflowy.io";

    final request = SignUpPayloadPB.create()
      ..name = LocaleKeys.defaultUsername.tr()
      ..email = userEmail
      ..password = password
      // When sign up as guest, the auth type is always local.
      ..authType = AuthTypePB.Local
      ..deviceId = await getDeviceId();
    final response = await UserEventSignUp(request).send().then(
          (value) => value.swap(),
        );
    return response;
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> signUpWithOAuth({
    required String platform,
    AuthTypePB authType = AuthTypePB.Local,
    Map<String, String> params = const {},
  }) async {
    return left(
      FlowyError.create()
        ..code = ErrorCode.Internal
        ..msg = "Unsupported sign up action",
    );
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> getUser() async {
    return UserBackendService.getCurrentUserProfile();
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> signInWithMagicLink({
    required String email,
    Map<String, String> params = const {},
  }) async {
    return left(
      FlowyError.create()
        ..code = ErrorCode.Internal
        ..msg = "Unsupported sign up action",
    );
  }
}
