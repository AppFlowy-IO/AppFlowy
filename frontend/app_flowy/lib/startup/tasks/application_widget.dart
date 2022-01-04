import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/presentation/theme/theme_model.dart';
import 'package:easy_localization/easy_localization.dart';
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
    BlocOverrides.runZoned(
      () {
        runApp(
          EasyLocalization(
              supportedLocales: const [Locale('en'), Locale('zh_CN'), Locale('it_IT')],
              path: 'assets/translations',
              fallbackLocale: const Locale('en'),
              child: app),
        );
      },
      blocObserver: ApplicationBlocObserver(),
    );

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
  Widget build(BuildContext context) => ChangeNotifierProvider(
      create: (context) => ThemeModel(),
      builder: (context, _) {
        const ratio = 1.73;
        const minWidth = 800.0;
        setWindowMinSize(const Size(minWidth, minWidth / ratio));

        ThemeType themeType = context.select<ThemeModel, ThemeType>((value) => value.theme);
        AppTheme theme = AppTheme.fromType(themeType);

        return Provider.value(
          value: theme,
          child: MaterialApp(
            builder: overlayManagerBuilder(),
            debugShowCheckedModeBanner: false,
            theme: theme.themeData,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            navigatorKey: AppGlobals.rootNavKey,
            home: child,
          ),
        );
      });
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
    //Log.debug("${transition.nextState}");
    super.onTransition(bloc, transition);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    Log.debug(error);
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    Log.debug("$event");
    super.onEvent(bloc, event);
  }
}
