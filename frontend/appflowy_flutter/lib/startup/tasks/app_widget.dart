import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/user_settings_service.dart';
import 'package:appflowy/workspace/application/notifications/notification_action.dart';
import 'package:appflowy/workspace/application/notifications/notification_action_bloc.dart';
import 'package:appflowy/workspace/application/notifications/notification_service.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/notifications/notification_settings_cubit.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'prelude.dart';

class InitAppWidgetTask extends LaunchTask {
  const InitAppWidgetTask();

  @override
  LaunchTaskType get type => LaunchTaskType.appLauncher;

  @override
  Future<void> initialize(LaunchContext context) async {
    WidgetsFlutterBinding.ensureInitialized();

    await NotificationService.initialize();

    final widget = context.getIt<EntryPoint>().create(context.config);
    final appearanceSetting =
        await UserSettingsBackendService().getAppearanceSetting();
    final dateTimeSettings =
        await UserSettingsBackendService().getDateTimeSettings();

    // If the passed-in context is not the same as the context of the
    // application widget, the application widget will be rebuilt.
    final app = ApplicationWidget(
      key: ValueKey(context),
      appearanceSetting: appearanceSetting,
      dateTimeSettings: dateTimeSettings,
      appTheme: await appTheme(appearanceSetting.theme),
      child: widget,
    );

    Bloc.observer = ApplicationBlocObserver();
    runApp(
      EasyLocalization(
        supportedLocales: const [
          // In alphabetical order
          Locale('am', 'ET'),
          Locale('ar', 'SA'),
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
          Locale('sv', 'SE'),
          Locale('th', 'TH'),
          Locale('tr', 'TR'),
          Locale('uk', 'UA'),
          Locale('ur'),
          Locale('vi', 'VN'),
          Locale('zh', 'CN'),
          Locale('zh', 'TW'),
          Locale('fa'),
          Locale('hin'),
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        useFallbackTranslations: true,
        saveLocale: false,
        child: app,
      ),
    );

    return;
  }

  @override
  Future<void> dispose() async {}
}

class ApplicationWidget extends StatefulWidget {
  const ApplicationWidget({
    super.key,
    required this.child,
    required this.appTheme,
    required this.appearanceSetting,
    required this.dateTimeSettings,
  });

  final Widget child;
  final AppTheme appTheme;
  final AppearanceSettingsPB appearanceSetting;
  final DateTimeSettingsPB dateTimeSettings;

  @override
  State<ApplicationWidget> createState() => _ApplicationWidgetState();
}

class _ApplicationWidgetState extends State<ApplicationWidget> {
  late final GoRouter routerConfig;

  @override
  void initState() {
    super.initState();

    // avoid rebuild routerConfig when the appTheme is changed.
    routerConfig = generateRouter(widget.child);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppearanceSettingsCubit>(
          create: (_) => AppearanceSettingsCubit(
            widget.appearanceSetting,
            widget.dateTimeSettings,
            widget.appTheme,
          )..readLocaleWhenAppLaunch(context),
        ),
        BlocProvider<NotificationSettingsCubit>(
          create: (_) => NotificationSettingsCubit(),
        ),
        BlocProvider<DocumentAppearanceCubit>(
          create: (_) => DocumentAppearanceCubit()..fetch(),
        ),
        BlocProvider.value(value: getIt<NotificationActionBloc>()),
      ],
      child: BlocListener<NotificationActionBloc, NotificationActionState>(
        listener: (context, state) {
          if (state.action?.type == ActionType.openView) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final view =
                  state.action!.arguments?[ActionArgumentKeys.view.name];
              if (view != null) {
                AppGlobals.rootNavKey.currentContext?.pushView(view);

                final nodePath = state.action!
                    .arguments?[ActionArgumentKeys.nodePath.name] as int?;

                if (nodePath != null) {
                  context.read<NotificationActionBloc>().add(
                        NotificationActionEvent.performAction(
                          action: state.action!
                              .copyWith(type: ActionType.jumpToBlock),
                        ),
                      );
                }
              }
            });
          }
        },
        child: BlocBuilder<AppearanceSettingsCubit, AppearanceSettingsState>(
          builder: (context, state) => MaterialApp.router(
            builder: (context, child) => MediaQuery(
              // use the 1.0 as the textScaleFactor to avoid the text size
              //  affected by the system setting.
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1),
              ),
              child: overlayManagerBuilder()(context, child),
            ),
            debugShowCheckedModeBanner: false,
            theme: state.lightTheme,
            darkTheme: state.darkTheme,
            themeMode: state.themeMode,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: state.locale,
            routerConfig: routerConfig,
          ),
        ),
      ),
    );
  }
}

class AppGlobals {
  // static GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey();
  static GlobalKey<NavigatorState> rootNavKey = GlobalKey();
  static NavigatorState get nav => rootNavKey.currentState!;
}

class ApplicationBlocObserver extends BlocObserver {
  @override
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

Future<AppTheme> appTheme(String themeName) async {
  if (themeName.isEmpty) {
    return AppTheme.fallback;
  } else {
    try {
      return await AppTheme.fromName(themeName);
    } catch (e) {
      return AppTheme.fallback;
    }
  }
}
