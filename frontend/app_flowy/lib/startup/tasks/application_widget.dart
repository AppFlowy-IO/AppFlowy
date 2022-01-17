import 'package:flutter/material.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:window_size/window_size.dart';
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;

import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_log/flowy_log.dart';

import '../../common/theme/theme.dart';
import 'package:app_flowy/startup/launcher.dart';
import 'package:app_flowy/startup/startup.dart';

class AppGlobals {
  static GlobalKey<NavigatorState> rootNavKey = GlobalKey();
  static NavigatorState get nav => rootNavKey.currentState!;
}

class AppWidgetTask extends LaunchTask {
  @override
  LaunchTaskType get type => LaunchTaskType.appLauncher;

  @override
  Future<void> initialize(LaunchContext context) async {
    WidgetsFlutterBinding.ensureInitialized();

    final widget = context.getIt<EntryPoint>().create();
    final app = _ApplicationWidget(child: widget);
    final storage = await HydratedStorage.build(storageDirectory: await getTemporaryDirectory());

    HydratedBlocOverrides.runZoned(
      () {
        runApp(
          EasyLocalization(
              supportedLocales: const [Locale('en'), Locale('zh_CN'), Locale('it_IT')],
              path: 'assets/translations',
              fallbackLocale: const Locale('en'),
              child: app),
        );
      },
      storage: storage,
      blocObserver: _ApplicationBlocObserver(),
    );

    return Future(() => {});
  }
}

class _ApplicationWidget extends StatelessWidget {
  final Widget child;
  const _ApplicationWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ThemeCubit>(
      create: (_) => ThemeCubit(),
      child: BlocBuilder<ThemeCubit, ThemeState>(builder: (context, state) {
        const ratio = 1.73;
        const minWidth = 800.0;
        setWindowMinSize(const Size(minWidth, minWidth / ratio));

        return MaterialApp(
          builder: overlayManagerBuilder(),
          debugShowCheckedModeBanner: false,
          theme: state.themeData,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          navigatorKey: AppGlobals.rootNavKey,
          home: child,
        );
      }),
    );
  }
}

class _ApplicationBlocObserver extends BlocObserver {
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
