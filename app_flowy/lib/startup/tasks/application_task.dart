import 'package:app_flowy/startup/startup.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_size/window_size.dart';
import 'package:app_flowy/startup/launcher.dart';
import 'package:bloc/bloc.dart';
import 'package:flowy_log/flowy_log.dart';

class AppWidgetTask extends LaunchTask {
  @override
  LaunchTaskType get type => LaunchTaskType.appLauncher;

  @override
  Future<void> initialize(LaunchContext context) {
    final widget = context.getIt<EntryPoint>().create();
    final app = ApplicationWidget(child: widget);
    Bloc.observer = ApplicationBlocObserver();
    runApp(app);

    return Future(() => {});
  }
}

class ApplicationWidget extends StatelessWidget {
  final Widget child;
  const ApplicationWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const ratio = 1.73;
    const minWidth = 1000.0;
    setWindowMinSize(const Size(minWidth, minWidth / ratio));
    // const launchWidth = 1310.0;
    // setWindowFrame(const Rect.fromLTWH(0, 0, launchWidth, launchWidth / ratio));

    final theme = AppTheme.fromType(ThemeType.light);
    return Provider.value(
      value: theme,
      child: MaterialApp(
        builder: overlayManagerBuilder(),
        debugShowCheckedModeBanner: false,
        theme: theme.themeData,
        navigatorKey: AppGlobals.rootNavKey,
        home: child,
      ),
    );
  }
}

class AppGlobals {
  static GlobalKey<NavigatorState> rootNavKey = GlobalKey();
  static NavigatorState get nav => rootNavKey.currentState!;
}

class ApplicationBlocObserver extends BlocObserver {
  @override
  // ignore: unnecessary_overrides
  void onTransition(Bloc bloc, Transition transition) {
    // Log.debug("[current]: ${transition.currentState} \n\n[next]: ${transition.nextState}");
    Log.debug("${transition.nextState}");
    super.onTransition(bloc, transition);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    Log.debug(error);
    super.onError(bloc, error, stackTrace);
  }
}
