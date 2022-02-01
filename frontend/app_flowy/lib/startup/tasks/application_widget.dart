import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/user/infrastructure/repos/user_setting_repo.dart';
import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/language.dart';
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
  Future<void> initialize(LaunchContext context) async {
    final widget = context.getIt<EntryPoint>().create();
    final setting = await UserSettingReppsitory().getAppearanceSettings();
    final settingModel = AppearanceSettingModel(setting);
    final app = ApplicationWidget(
      child: widget,
      settingModel: settingModel,
    );
    BlocOverrides.runZoned(
      () {
        runApp(
          EasyLocalization(
              supportedLocales: const [Locale('en'), Locale('zh', 'CN'), Locale('it', 'IT'), Locale('fr', 'CA')],
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
          AppLanguage language = context.select<AppearanceSettingModel, AppLanguage>(
            (value) => value.language,
          );

          return MultiProvider(
            providers: [
              Provider.value(value: theme),
              Provider.value(value: language),
            ],
            builder: (context, _) {
              return MaterialApp(
                builder: overlayManagerBuilder(),
                debugShowCheckedModeBanner: false,
                theme: theme.themeData,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: localeFromLanguageName(language),
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
