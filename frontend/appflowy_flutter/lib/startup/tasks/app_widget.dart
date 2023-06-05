import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../user/application/user_settings_service.dart';
import '../../workspace/application/appearance.dart';
import '../startup.dart';

class InitAppWidgetTask extends LaunchTask {
  @override
  LaunchTaskType get type => LaunchTaskType.appLauncher;

  @override
  Future<void> initialize(final LaunchContext context) async {
    final widget = context.getIt<EntryPoint>().create(context.config);
    final appearanceSetting =
        await UserSettingsBackendService().getAppearanceSetting();
    final app = ApplicationWidget(
      appearanceSetting: appearanceSetting,
      child: widget,
    );
    Bloc.observer = ApplicationBlocObserver();
    runApp(
      EasyLocalization(
        supportedLocales: const [
          // In alphabetical order
          Locale('ar', 'AR'),
          Locale('ca', 'ES'),
          Locale('de', 'DE'),
          Locale('en'),
          Locale('es', 'VE'),
          Locale('eu', 'ES'),
          Locale('fr', 'FR'),
          Locale('fr', 'CA'),
          Locale('hu', 'HU'),
          Locale('id', 'ID'),
          Locale('it', 'IT'),
          Locale('ja', 'JP'),
          Locale('ko', 'KR'),
          Locale('pl', 'PL'),
          Locale('pt', 'BR'),
          Locale('ru', 'RU'),
          Locale('sv'),
          Locale('tr', 'TR'),
          Locale('zh', 'CN'),
          Locale('zh', 'TW'),
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        useFallbackTranslations: true,
        saveLocale: false,
        child: app,
      ),
    );

    return Future(() => {});
  }
}

class ApplicationWidget extends StatelessWidget {
  final Widget child;
  final AppearanceSettingsPB appearanceSetting;

  const ApplicationWidget({
    final Key? key,
    required this.child,
    required this.appearanceSetting,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    final cubit = AppearanceSettingsCubit(appearanceSetting)
      ..readLocaleWhenAppLaunch(context);

    return BlocProvider(
      create: (final context) => cubit,
      child: BlocBuilder<AppearanceSettingsCubit, AppearanceSettingsState>(
        builder: (final context, final state) => MaterialApp(
          builder: overlayManagerBuilder(),
          debugShowCheckedModeBanner: false,
          theme: state.lightTheme,
          darkTheme: state.darkTheme,
          themeMode: state.themeMode,
          localizationsDelegates: context.localizationDelegates +
              [AppFlowyEditorLocalizations.delegate],
          supportedLocales: context.supportedLocales,
          locale: state.locale,
          navigatorKey: AppGlobals.rootNavKey,
          home: child,
        ),
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
  void onTransition(final Bloc bloc, final Transition transition) {
    // Log.debug("[current]: ${transition.currentState} \n\n[next]: ${transition.nextState}");
    // Log.debug("${transition.nextState}");
    super.onTransition(bloc, transition);
  }

  @override
  void onError(final BlocBase bloc, final Object error, final StackTrace stackTrace) {
    Log.debug(error);
    super.onError(bloc, error, stackTrace);
  }

  // @override
  // void onEvent(Bloc bloc, Object? event) {
  //   Log.debug("$event");
  //   super.onEvent(bloc, event);
  // }
}
