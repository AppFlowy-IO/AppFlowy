import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/user/application/splash_bloc.dart';
import 'package:app_flowy/user/domain/auth_state.dart';
import 'package:app_flowy/user/presentation/router.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/errors.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        return getIt<SplashBloc>()..add(const SplashEvent.getUser());
      },
      child: Scaffold(
        body: BlocListener<SplashBloc, SplashState>(
          listener: (context, state) {
            state.auth.map(
              authenticated: (r) => _handleAuthenticated(context, r),
              unauthenticated: (r) => _handleUnauthenticated(context, r),
              initial: (r) => {},
            );
          },
          child: const Body(),
        ),
      ),
    );
  }

  void _handleAuthenticated(BuildContext context, Authenticated result) {
    final userProfile = result.userProfile;
    FolderEventReadCurWorkspace().send().then(
      (result) {
        return result.fold(
          (workspaceSetting) => getIt<SplashRoute>().pushHomeScreen(context, userProfile, workspaceSetting),
          (error) async {
            Log.error(error);
            assert(error.code == ErrorCode.RecordNotFound.value);
            getIt<SplashRoute>().pushWelcomeScreen(context, userProfile);
          },
        );
      },
    );
  }

  void _handleUnauthenticated(BuildContext context, Unauthenticated result) {
    // getIt<SplashRoute>().pushSignInScreen(context);
    getIt<SplashRoute>().pushSkipLoginScreen(context);
  }
}

class Body extends StatelessWidget {
  const Body({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

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
                image: const AssetImage('assets/images/appflowy_launch_splash.jpg')),
            const CircularProgressIndicator.adaptive(),
          ],
        ),
      ),
    );
  }
}
