import 'package:app_flowy/welcome/domain/deps.dart';
import 'package:app_flowy/welcome/presentation/widgets/body.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/welcome/application/welcome_bloc.dart';
import 'package:flowy_style/route/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flowy_style/time/prelude.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<WelcomeBloc>()..add(const WelcomeEvent.check()),
      child: Scaffold(
        body: BlocListener<WelcomeBloc, WelcomeState>(
          listener: (context, state) {
            state.auth.map(
              authenticated: (_) =>
                  _pushToScreen(context, getIt<IWelcomeRoute>().home()),
              unauthenticated: (_) =>
                  _pushToScreen(context, getIt<IWelcomeRoute>().signIn()),
            );
          },
          child: const Body(),
        ),
      ),
    );
  }

  void _pushToScreen(BuildContext context, Widget screen) {
    /// Let the splash view sit for a bit. Mainly for aesthetics and to ensure a smooth intro animation.
    Future<void>.delayed(1.0.seconds, () {
      Navigator.push(
          context,
          PageRoutes.fade(
              () => screen, RouteDurations.slow.inMilliseconds * .001));
    });
  }
}
