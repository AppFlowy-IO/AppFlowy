import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/user/application/user_settings_service.dart';
import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_size/window_size.dart';
import 'package:bloc/bloc.dart';
import 'package:flowy_sdk/log.dart';

class InitAppWidgetTask extends LaunchTask {
  @override
  LaunchTaskType get type => LaunchTaskType.appLauncher;

  @override
  Future<void> initialize(LaunchContext context) async {
    final widget = context.getIt<EntryPoint>().create();
    final setting = await UserSettingsService().getAppearanceSettings();
    final settingModel = AppearanceSettingModel(setting);
    final app = ApplicationWidget(
      child: widget,
      settingModel: settingModel,
    );
    BlocOverrides.runZoned(
      () {
        runApp(
          EasyLocalization(
            supportedLocales: const [
              // In alphabetical order
              Locale('ca', 'ES'),
              Locale('de', 'DE'),
              Locale('en'),
              Locale('es', 'VE'),
              Locale('fr', 'FR'),
              Locale('fr', 'CA'),
              Locale('hu', 'HU'),
              Locale('it', 'IT'),
              Locale('pt', 'BR'),
              Locale('ru', 'RU'),
              Locale('tr', 'TR'),
              Locale('zh', 'CN'),
            ],
            path: 'assets/translations',
            fallbackLocale: const Locale('en'),
            saveLocale: false,
            child: app,
          ),
        );
      },
      blocObserver: ApplicationBlocObserver(),
    );

    return Future(() => {});
  }
}

class ApplicationWidget extends StatelessWidget {
  final Widget child;
  final AppearanceSettingModel settingModel;

  const ApplicationWidget({
    Key? key,
    required this.child,
    required this.settingModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
        value: settingModel,
        builder: (context, _) {
          const ratio = 1.73;
          const minWidth = 600.0;
          setWindowMinSize(const Size(minWidth, minWidth / ratio));
          settingModel.readLocaleWhenAppLaunch(context);
          AppTheme theme = context.select<AppearanceSettingModel, AppTheme>(
            (value) => value.theme,
          );
          Locale locale = context.select<AppearanceSettingModel, Locale>(
            (value) => value.locale,
          );

          return MultiProvider(
            providers: [
              Provider.value(value: theme),
              Provider.value(value: locale),
            ],
            builder: (context, _) {
              return MaterialApp(
                builder: overlayManagerBuilder(),
                debugShowCheckedModeBanner: false,
                theme: theme.themeData,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: locale,
                navigatorKey: AppGlobals.rootNavKey,
                home: child,
              );
            },
          );
        },
      );
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
    // Log.debug("${transition.nextState}");
    super.onTransition(bloc, transition);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    Log.debug(error);
    super.onError(bloc, error, stackTrace);
  }

  // @override
  // void onEvent(Bloc bloc, Object? event) {
  //   Log.debug("$event");
  //   super.onEvent(bloc, event);
  // }
}
