import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../startup/startup.dart';
import '../application/auth_service.dart';
import '../application/splash_bloc.dart';
import '../domain/auth_state.dart';
import 'router.dart';

// [[diagram: splash screen]]
// ┌────────────────┐1.get user ┌──────────┐     ┌────────────┐ 2.send UserEventCheckUser
// │  SplashScreen  │──────────▶│SplashBloc│────▶│ISplashUser │─────┐
// └────────────────┘           └──────────┘     └────────────┘     │
//                                                                  │
//                                                                  ▼
//    ┌───────────┐            ┌─────────────┐                 ┌────────┐
//    │HomeScreen │◀───────────│BlocListener │◀────────────────│RustSDK │
//    └───────────┘            └─────────────┘                 └────────┘
//           4. Show HomeScreen or SignIn      3.return AuthState
class SplashScreen extends StatelessWidget {
  const SplashScreen({
    final Key? key,
    required this.autoRegister,
  }) : super(key: key);

  final bool autoRegister;

  @override
  Widget build(final BuildContext context) {
    if (!autoRegister) {
      return _buildChild(context);
    } else {
      return FutureBuilder<void>(
        future: _registerIfNeeded(),
        builder: (final context, final snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Container();
          }
          return _buildChild(context);
        },
      );
    }
  }

  BlocProvider<SplashBloc> _buildChild(final BuildContext context) {
    return BlocProvider(
      create: (final context) {
        return getIt<SplashBloc>()..add(const SplashEvent.getUser());
      },
      child: Scaffold(
        body: BlocListener<SplashBloc, SplashState>(
          listener: (final context, final state) {
            state.auth.map(
              authenticated: (final r) => _handleAuthenticated(context, r),
              unauthenticated: (final r) => _handleUnauthenticated(context, r),
              initial: (final r) => {},
            );
          },
          child: const Body(),
        ),
      ),
    );
  }

  void _handleAuthenticated(final BuildContext context, final Authenticated result) {
    final userProfile = result.userProfile;
    FolderEventReadCurrentWorkspace().send().then(
      (final result) {
        return result.fold(
          (final workspaceSetting) {
            getIt<SplashRoute>()
                .pushHomeScreen(context, userProfile, workspaceSetting);
          },
          (final error) async {
            Log.error(error);
            getIt<SplashRoute>().pushWelcomeScreen(context, userProfile);
          },
        );
      },
    );
  }

  void _handleUnauthenticated(final BuildContext context, final Unauthenticated result) {
    // getIt<SplashRoute>().pushSignInScreen(context);
    getIt<SplashRoute>().pushSkipLoginScreen(context);
  }

  Future<void> _registerIfNeeded() async {
    final result = await UserEventCheckUser().send();
    if (!result.isLeft()) {
      await getIt<AuthService>().autoSignUp();
    }
  }
}

class Body extends StatelessWidget {
  const Body({final Key? key}) : super(key: key);
  @override
  Widget build(final BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image(
              fit: BoxFit.cover,
              width: size.width,
              height: size.height,
              image:
                  const AssetImage('assets/images/appflowy_launch_splash.jpg'),
            ),
            const CircularProgressIndicator.adaptive(),
          ],
        ),
      ),
    );
  }
}
