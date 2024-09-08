import 'dart:async';

import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/auth/backend_auth_service.dart';
import 'package:appflowy/user/application/auth/device_id.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter/material.dart';

/// Only used for testing.
class AppFlowyCloudMockAuthService implements AuthService {
  AppFlowyCloudMockAuthService({String? email})
      : userEmail = email ?? "${uuid()}@appflowy.io";

  final String userEmail;

  final BackendAuthService _appFlowyAuthService =
      BackendAuthService(AuthenticatorPB.AppFlowyCloud);

  @override
  Future<FlowyResult<UserProfilePB, FlowyError>> signUp({
    required String name,
    required String email,
    required String password,
    Map<String, String> params = const {},
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<FlowyResult<UserProfilePB, FlowyError>> signInWithEmailPassword({
    required String email,
    required String password,
    Map<String, String> params = const {},
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<FlowyResult<UserProfilePB, FlowyError>> signUpWithOAuth({
    required String platform,
    Map<String, String> params = const {},
  }) async {
    final payload = SignInUrlPayloadPB.create()
      ..authenticator = AuthenticatorPB.AppFlowyCloud
      // don't use nanoid here, the gotrue server will transform the email
      ..email = userEmail;

    final deviceId = await getDeviceId();
    final getSignInURLResult = await UserEventGenerateSignInURL(payload).send();

    return getSignInURLResult.fold(
      (urlPB) async {
        final payload = OauthSignInPB(
          authenticator: AuthenticatorPB.AppFlowyCloud,
          map: {
            AuthServiceMapKeys.signInURL: urlPB.signInUrl,
            AuthServiceMapKeys.deviceId: deviceId,
          },
        );
        Log.info("UserEventOauthSignIn with payload: $payload");
        return UserEventOauthSignIn(payload).send().then((value) {
          value.fold(
            (l) => null,
            (err) {
              debugPrint("Error: $err");
              Log.error(err);
            },
          );
          return value;
        });
      },
      (r) {
        debugPrint("Error: $r");
        return FlowyResult.failure(r);
      },
    );
  }

  @override
  Future<void> signOut() async {
    await _appFlowyAuthService.signOut();
  }

  @override
  Future<FlowyResult<UserProfilePB, FlowyError>> signUpAsGuest({
    Map<String, String> params = const {},
  }) async {
    return _appFlowyAuthService.signUpAsGuest();
  }

  @override
  Future<FlowyResult<UserProfilePB, FlowyError>> signInWithMagicLink({
    required String email,
    Map<String, String> params = const {},
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<FlowyResult<UserProfilePB, FlowyError>> getUser() async {
    return UserBackendService.getCurrentUserProfile();
  }
}
