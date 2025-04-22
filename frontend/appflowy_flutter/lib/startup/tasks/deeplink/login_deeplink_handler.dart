import 'dart:async';

import 'package:appflowy/startup/tasks/deeplink/deeplink_handler.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/auth/device_id.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';

class LoginDeepLinkHandler extends DeepLinkHandler<UserProfilePB> {
  @override
  bool canHandle(Uri uri) {
    final isLoginCallback = uri.host == 'login-callback';
    if (!isLoginCallback) {
      return false;
    }

    final containsAccessToken = uri.fragment.contains('access_token');
    if (!containsAccessToken) {
      return false;
    }

    return true;
  }

  @override
  Future<FlowyResult<UserProfilePB, FlowyError>> handle({
    required Uri uri,
    required DeepLinkStateHandler onStateChange,
  }) async {
    final deviceId = await getDeviceId();
    final payload = OauthSignInPB(
      authenticator: AuthTypePB.Server,
      map: {
        AuthServiceMapKeys.signInURL: uri.toString(),
        AuthServiceMapKeys.deviceId: deviceId,
      },
    );

    onStateChange(this, DeepLinkState.loading);

    final result = await UserEventOauthSignIn(payload).send();

    onStateChange(this, DeepLinkState.finish);

    return result;
  }
}
