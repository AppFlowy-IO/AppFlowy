import 'package:app_flowy/home/presentation/home_screen.dart';
import 'package:app_flowy/welcome/application/welcome_bloc.dart';
import 'package:app_flowy/welcome/domain/auth_state.dart';
import 'package:app_flowy/welcome/domain/deps.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:time/time.dart';

class Welcome {
  static Future<void> dependencyResolved(GetIt getIt) async {
    getIt.registerFactory<IWelcomeAuth>(() => AuthCheck());
    getIt.registerFactory<IWelcomeRoute>(() => WelcomeRoute());

    getIt
        .registerFactory<WelcomeBloc>(() => WelcomeBloc(getIt<IWelcomeAuth>()));
  }
}

class AuthCheck implements IWelcomeAuth {
  @override
  Future<AuthState> getAuthState() async {
    return Future<AuthState>.delayed(3.0.seconds, () {
      return const AuthState.authenticated();
    });
  }
}

class WelcomeRoute implements IWelcomeRoute {
  @override
  Widget home() {
    return const HomeScreen();
  }

  @override
  Widget signIn() {
    return Container();
  }
}
