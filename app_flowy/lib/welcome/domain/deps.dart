import 'package:flutter/widgets.dart';

import 'auth_state.dart';

abstract class IWelcomeAuth {
  Future<AuthState> getAuthState();
}

abstract class IWelcomeRoute {
  Widget signIn();
  Widget home();
}
