import 'package:app_flowy/welcome/domain/interface.dart';
import 'package:app_flowy/welcome/domain/auth_state.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/welcome/application/welcome_bloc.dart';
import 'package:flowy_infra_ui/widget/route/animation.dart';
import 'package:flowy_logger/flowy_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flowy_infra/time/prelude.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        return getIt<WelcomeBloc>()..add(const WelcomeEvent.getUser());
      },
      child: Scaffold(
        body: BlocListener<WelcomeBloc, WelcomeState>(
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

  void _pushToScreen(BuildContext context, Widget screen) {
    /// Let the splash view sit for a bit. Mainly for aesthetics and to ensure a smooth intro animation.
    Navigator.push(
        context,
        PageRoutes.fade(
            () => screen, RouteDurations.slow.inMilliseconds * .001));
  }

  void _handleAuthenticated(BuildContext context, Authenticated result) {
    _pushToScreen(
        context, getIt<IWelcomeRoute>().pushHomeScreen(result.userDetail));
  }

  void _handleUnauthenticated(BuildContext context, Unauthenticated result) {
    Log.error(result.error);

    _pushToScreen(context, getIt<IWelcomeRoute>().pushSignInScreen());
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
                image: const AssetImage(
                    'assets/images/appflowy_launch_splash.jpg')),
            const CircularProgressIndicator.adaptive(),
          ],
        ),
      ),
    );
  }
}
