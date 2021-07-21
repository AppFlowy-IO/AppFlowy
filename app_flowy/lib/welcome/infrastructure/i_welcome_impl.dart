import 'package:app_flowy/home/application/edit_pannel/edit_pannel_bloc.dart';
import 'package:app_flowy/home/application/home_bloc.dart';

import 'package:app_flowy/home/presentation/home_screen.dart';
import 'package:app_flowy/user/presentation/sign_in/sign_in_screen.dart';
import 'package:app_flowy/welcome/domain/auth_state.dart';
import 'package:app_flowy/welcome/domain/i_welcome.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

export 'package:app_flowy/welcome/domain/i_welcome.dart';

class WelcomeAuthImpl implements IWelcomeAuth {
  @override
  Future<AuthState> currentUserState() {
    final result = UserEventGetStatus().send();
    return result.then((result) {
      return result.fold(
        (userDetail) {
          return AuthState.authenticated(userDetail);
        },
        (userError) {
          return AuthState.unauthenticated(userError);
        },
      );
    });
  }
}

class WelcomeRoute implements IWelcomeRoute {
  @override
  Widget pushHomeScreen(UserDetail user) {
    return HomeScreen(user);
  }

  @override
  Widget pushSignInScreen() {
    return const SignInScreen();
  }
}
