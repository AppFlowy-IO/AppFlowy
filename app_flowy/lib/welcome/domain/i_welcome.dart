import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/widgets.dart';

import 'auth_state.dart';

abstract class ISplashAuth {
  Future<AuthState> currentUserProfile();
}

abstract class IWelcomeRoute {
  void pushSignInScreen(BuildContext context);
  Future<void> pushWelcomeScreen(BuildContext context, UserProfile profile);
  void pushHomeScreen(
      BuildContext context, UserProfile profile, String workspaceId);
}
