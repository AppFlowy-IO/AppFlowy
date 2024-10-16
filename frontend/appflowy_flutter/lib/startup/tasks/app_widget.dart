import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/shared/clipboard_state.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/user_settings_service.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy/workspace/application/notification/notification_service.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/notifications/notification_settings_cubit.dart';
import 'package:appflowy/workspace/application/sidebar/rename_view/rename_view_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/command_palette/command_palette.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:universal_platform/universal_platform.dart';

import 'prelude.dart';

class InitAppWidgetTask extends LaunchTask {
  const InitAppWidgetTask();

  @override
  LaunchTaskType get type => LaunchTaskType.appLauncher;

  @override
  Future<void> initialize(LaunchContext context) async {
    WidgetsFlutterBinding.ensureInitialized();

    await NotificationService.initialize();

    await loadIconGroups();

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
          Locale('cs', 'CZ'),
          Locale('ckb', 'KU'),
          Locale('de', 'DE'),
          Locale('en'),
          Locale('es', 'VE'),
          Locale('eu', 'ES'),
          Locale('el', 'GR'),
          Locale('fr', 'FR'),
          Locale('fr', 'CA'),
          Locale('he'),
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

  final _commandPaletteNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    // Avoid rebuild routerConfig when the appTheme is changed.
    routerConfig = generateRouter(widget.child);
  }

  @override
  void dispose() {
    _commandPaletteNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        if (FeatureFlag.search.isOn)
          BlocProvider<CommandPaletteBloc>(create: (_) => CommandPaletteBloc()),
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
        BlocProvider.value(value: getIt<RenameViewBloc>()),
        BlocProvider.value(value: getIt<ActionNavigationBloc>()),
      ],
      child: BlocListener<ActionNavigationBloc, ActionNavigationState>(
        listenWhen: (_, curr) => curr.action != null,
        listener: (context, state) {
          final action = state.action;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (action?.type == ActionType.openView &&
                UniversalPlatform.isDesktop) {
              final view = action!.arguments?[ActionArgumentKeys.view];
              final nodePath = action.arguments?[ActionArgumentKeys.nodePath];
              if (view != null) {
                getIt<TabsBloc>().openPlugin(
                  view.plugin(),
                  arguments: {PluginArgumentKeys.selection: nodePath},
                );
              }
            } else if (action?.type == ActionType.openRow &&
                UniversalPlatform.isMobile) {
              final view = action!.arguments?[ActionArgumentKeys.view];
              if (view != null) {
                final view = action.arguments?[ActionArgumentKeys.view];
                final rowId = action.arguments?[ActionArgumentKeys.rowId];
                AppGlobals.rootNavKey.currentContext?.pushView(
                  view,
                  arguments: {
                    PluginArgumentKeys.rowId: rowId,
                  },
                );
              }
            }
          });
        },
        child: BlocBuilder<AppearanceSettingsCubit, AppearanceSettingsState>(
          builder: (context, state) {
            _setSystemOverlayStyle(state);
            return Provider(
              create: (_) => ClipboardState(),
              child: ToastificationWrapper(
                child: MaterialApp.router(
                  builder: (context, child) => MediaQuery(
                    // use the 1.0 as the textScaleFactor to avoid the text size
                    //  affected by the system setting.
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(state.textScaleFactor),
                    ),
                    child: overlayManagerBuilder(
                      context,
                      !UniversalPlatform.isMobile && FeatureFlag.search.isOn
                          ? CommandPalette(
                              notifier: _commandPaletteNotifier,
                              child: child,
                            )
                          : child,
                    ),
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
            );
          },
        ),
      ),
    );
  }

  void _setSystemOverlayStyle(AppearanceSettingsState state) {
    if (Platform.isAndroid) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: [],
      );
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
        ),
      );
    }
  }
}

class AppGlobals {
  static GlobalKey<NavigatorState> rootNavKey = GlobalKey();
  static NavigatorState get nav => rootNavKey.currentState!;
  static BuildContext get context => rootNavKey.currentContext!;
}

class ApplicationBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    Log.debug(error);
    super.onError(bloc, error, stackTrace);
  }
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
