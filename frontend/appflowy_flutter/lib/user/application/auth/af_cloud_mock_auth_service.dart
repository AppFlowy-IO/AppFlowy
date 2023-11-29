import 'dart:async';

import 'package:appflowy/user/application/auth/backend_auth_service.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/auth/device_id.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/uuid.dart';

/// Only used for testing.
class AppFlowyCloudMockAuthService implements AuthService {
  final String userEmail;

  AppFlowyCloudMockAuthService({String? email})
      : userEmail = email ?? "${uuid()}@appflowy.io";

  final BackendAuthService _appFlowyAuthService =
      BackendAuthService(AuthTypePB.Supabase);

  @override
  Future<Either<FlowyError, UserProfilePB>> signUp({
    required String name,
    required String email,
    required String password,
    Map<String, String> params = const {},
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> signInWithEmailPassword({
    required String email,
    required String password,
    Map<String, String> params = const {},
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> signUpWithOAuth({
    required String platform,
    Map<String, String> params = const {},
  }) async {
    final payload = SignInUrlPayloadPB.create()
      ..authType = AuthTypePB.AFCloud
      // don't use nanoid here, the gotrue server will transform the email
      ..email = userEmail;

    final deviceId = await getDeviceId();
    final getSignInURLResult = await UserEventGenerateSignInURL(payload).send();

    return getSignInURLResult.fold(
      (urlPB) async {
        final payload = OauthSignInPB(
          authType: AuthTypePB.AFCloud,
          map: {
            AuthServiceMapKeys.signInURL: urlPB.signInUrl,
            AuthServiceMapKeys.deviceId: deviceId,
          },
        );
        return await UserEventOauthSignIn(payload)
            .send()
            .then((value) => value.swap());
      },
      (r) => left(r),
    );
  }

  @override
  Future<void> signOut() async {
    await _appFlowyAuthService.signOut();
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> signUpAsGuest({
    Map<String, String> params = const {},
  }) async {
    return _appFlowyAuthService.signUpAsGuest();
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> signInWithMagicLink({
    required String email,
    Map<String, String> params = const {},
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<FlowyError, UserProfilePB>> getUser() async {
    return UserBackendService.getCurrentUserProfile();
  }
}
