import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/widgets.dart';

import 'auth_state.dart';

abstract class IWelcomeAuth {
  Future<AuthState> currentUserProfile();
}

abstract class IWelcomeRoute {
  Widget pushSignInScreen();
  Future<void> pushHomeScreen(BuildContext context, UserProfile profile);
}
