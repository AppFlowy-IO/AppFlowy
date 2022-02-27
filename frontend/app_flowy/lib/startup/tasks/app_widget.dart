import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/user/infrastructure/repos/user_setting_repo.dart';
import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:window_size/window_size.dart';
import 'package:flowy_sdk/log.dart';

import 'package:flowy_sdk/protobuf/flowy-user-data-model/user_setting.pb.dart';

class InitAppWidgetTask extends LaunchTask {
  @override
  LaunchTaskType get type => LaunchTaskType.appLauncher;

  @override
  Future<void> initialize(LaunchContext context) async {
    final app = ApplicationWidget(
      child: context.getIt<EntryPoint>().create(),
      settings: await UserSettingReppsitory().getAppearanceSettings(),
    );

    BlocOverrides.runZoned(
      () {
        runApp(
          EasyLocalization(
            supportedLocales: const [
              // In alphabetical order
              Locale('de', 'DE'),
              Locale('en'),
              Locale('es', 'VE'),
              Locale('fr', 'FR'),
              Locale('fr', 'CA'),
              Locale('it', 'IT'),
              Locale('ru', 'RU'),
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
  final AppearanceSettings settings;

  const ApplicationWidget({
    Key? key,
    required this.child,
    required this.settings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const ratio = 1.73;
    const minWidth = 600.0;
    setWindowMinSize(const Size(minWidth, minWidth / ratio));

    return BlocProvider(
      create: (BuildContext context) {
        final cubit = AppearanceSettingsCubit(settings);
        cubit.loadLocale(context);
        return cubit;
      },
      child: BlocBuilder<AppearanceSettingsCubit, AppearanceSettingsState>(
        builder: (context, state) {
          return MaterialApp(
            builder: overlayManagerBuilder(),
            debugShowCheckedModeBanner: false,
            theme: state.theme.themeData,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: state.locale,
            navigatorKey: AppGlobals.rootNavKey,
            home: child,
          );
        },
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
