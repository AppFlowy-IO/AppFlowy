import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/widgets.dart';

import 'auth_state.dart';

abstract class ISplashUser {
  Future<AuthState> currentUserProfile();
}

abstract class ISplashUserWatch {
  void startWatching({
    void Function(AuthState)? authStateCallback,
  });

  Future<void> stopWatching();
}

abstract class ISplashRoute {
  void pushSignInScreen(BuildContext context);
  void pushSkipLoginScreen(BuildContext context);

  Future<void> pushWelcomeScreen(BuildContext context, UserProfile profile);
  void pushHomeScreen(BuildContext context, UserProfile profile, String workspaceId);
}
