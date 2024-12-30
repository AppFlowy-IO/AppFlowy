import 'dart:io';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/app_window_size_manager.dart';
import 'package:appflowy/workspace/application/home/home_setting_bloc.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/sidebar/rename_view/rename_view_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/shared/sidebar_setting.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:provider/provider.dart';
import 'package:scaled_app/scaled_app.dart';

typedef KeyDownHandler = void Function(HotKey hotKey);

ValueNotifier<int> switchToTheNextSpace = ValueNotifier(0);
ValueNotifier<int> createNewPageNotifier = ValueNotifier(0);

@visibleForTesting
final zoomInKeyCodes = [KeyCode.equal, KeyCode.numpadAdd, KeyCode.add];
@visibleForTesting
final zoomOutKeyCodes = [KeyCode.minus, KeyCode.numpadSubtract];
@visibleForTesting
final resetZoomKeyCodes = [KeyCode.digit0, KeyCode.numpad0];

// Use a global value to store the zoom level and update it in the hotkeys.
@visibleForTesting
double appflowyScaleFactor = 1.0;

/// Helper class that utilizes the global [HotKeyManager] to easily
/// add a [HotKey] with different handlers.
///
/// Makes registration of a [HotKey] simple and easy to read, and makes
/// sure the [KeyDownHandler], and other handlers, are grouped with the
/// relevant [HotKey].
///
class HotKeyItem {
  HotKeyItem({
    required this.hotKey,
    this.keyDownHandler,
  });

  final HotKey hotKey;
  final KeyDownHandler? keyDownHandler;

  void register() =>
      hotKeyManager.register(hotKey, keyDownHandler: keyDownHandler);
}

class HomeHotKeys extends StatefulWidget {
  const HomeHotKeys({
    super.key,
    required this.userProfile,
    required this.child,
  });

  final UserProfilePB userProfile;
  final Widget child;

  @override
  State<HomeHotKeys> createState() => _HomeHotKeysState();
}

class _HomeHotKeysState extends State<HomeHotKeys> {
  final windowSizeManager = WindowSizeManager();

  late final items = [
    // Collapse sidebar menu (using slash)
    HotKeyItem(
      hotKey: HotKey(
        KeyCode.backslash,
        modifiers: [Platform.isMacOS ? KeyModifier.meta : KeyModifier.control],
        scope: HotKeyScope.inapp,
      ),
      keyDownHandler: (_) => context
          .read<HomeSettingBloc>()
          .add(const HomeSettingEvent.collapseMenu()),
    ),

    // Collapse sidebar menu (using .)
    HotKeyItem(
      hotKey: HotKey(
        KeyCode.period,
        modifiers: [Platform.isMacOS ? KeyModifier.meta : KeyModifier.control],
        scope: HotKeyScope.inapp,
      ),
      keyDownHandler: (_) => context
          .read<HomeSettingBloc>()
          .add(const HomeSettingEvent.collapseMenu()),
    ),

    // Toggle theme mode light/dark
    HotKeyItem(
      hotKey: HotKey(
        KeyCode.keyL,
        modifiers: [
          Platform.isMacOS ? KeyModifier.meta : KeyModifier.control,
          KeyModifier.shift,
        ],
        scope: HotKeyScope.inapp,
      ),
      keyDownHandler: (_) =>
          context.read<AppearanceSettingsCubit>().toggleThemeMode(),
    ),

    // Close current tab
    HotKeyItem(
      hotKey: HotKey(
        KeyCode.keyW,
        modifiers: [Platform.isMacOS ? KeyModifier.meta : KeyModifier.control],
        scope: HotKeyScope.inapp,
      ),
      keyDownHandler: (_) =>
          context.read<TabsBloc>().add(const TabsEvent.closeCurrentTab()),
    ),

    // Go to previous tab
    HotKeyItem(
      hotKey: HotKey(
        KeyCode.pageUp,
        modifiers: [Platform.isMacOS ? KeyModifier.meta : KeyModifier.control],
        scope: HotKeyScope.inapp,
      ),
      keyDownHandler: (_) => _selectTab(context, -1),
    ),

    // Go to next tab
    HotKeyItem(
      hotKey: HotKey(
        KeyCode.pageDown,
        modifiers: [Platform.isMacOS ? KeyModifier.meta : KeyModifier.control],
        scope: HotKeyScope.inapp,
      ),
      keyDownHandler: (_) => _selectTab(context, 1),
    ),

    // Rename current view
    HotKeyItem(
      hotKey: HotKey(
        KeyCode.f2,
        scope: HotKeyScope.inapp,
      ),
      keyDownHandler: (_) =>
          getIt<RenameViewBloc>().add(const RenameViewEvent.open()),
    ),

    // Scale up/down the app
    // In some keyboards, the system returns equal as + keycode, while others may return add as + keycode, so add them both as zoom in key.
    ...zoomInKeyCodes.map(
      (keycode) => HotKeyItem(
        hotKey: HotKey(
          keycode,
          modifiers: [
            Platform.isMacOS ? KeyModifier.meta : KeyModifier.control,
          ],
          scope: HotKeyScope.inapp,
        ),
        keyDownHandler: (_) => _scaleWithStep(0.1),
      ),
    ),

    ...zoomOutKeyCodes.map(
      (keycode) => HotKeyItem(
        hotKey: HotKey(
          keycode,
          modifiers: [
            Platform.isMacOS ? KeyModifier.meta : KeyModifier.control,
          ],
          scope: HotKeyScope.inapp,
        ),
        keyDownHandler: (_) => _scaleWithStep(-0.1),
      ),
    ),

    // Reset app scaling
    ...resetZoomKeyCodes.map(
      (keycode) => HotKeyItem(
        hotKey: HotKey(
          keycode,
          modifiers: [
            Platform.isMacOS ? KeyModifier.meta : KeyModifier.control,
          ],
          scope: HotKeyScope.inapp,
        ),
        keyDownHandler: (_) => _scale(1),
      ),
    ),

    // Switch to the next space
    HotKeyItem(
      hotKey: HotKey(
        KeyCode.keyO,
        modifiers: [Platform.isMacOS ? KeyModifier.meta : KeyModifier.control],
        scope: HotKeyScope.inapp,
      ),
      keyDownHandler: (_) => switchToTheNextSpace.value++,
    ),

    // Create a new page
    HotKeyItem(
      hotKey: HotKey(
        KeyCode.keyN,
        modifiers: [Platform.isMacOS ? KeyModifier.meta : KeyModifier.control],
        scope: HotKeyScope.inapp,
      ),
      keyDownHandler: (_) => createNewPageNotifier.value++,
    ),

    // Open settings dialog
    openSettingsHotKey(context, widget.userProfile),
  ];

  @override
  void initState() {
    super.initState();
    _registerHotKeys(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registerHotKeys(context);
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _registerHotKeys(BuildContext context) {
    for (final element in items) {
      element.register();
    }
  }

  void _selectTab(BuildContext context, int change) {
    final bloc = context.read<TabsBloc>();
    bloc.add(TabsEvent.selectTab(bloc.state.currentIndex + change));
  }

  Future<void> _scaleWithStep(double step) async {
    final currentScaleFactor = await windowSizeManager.getScaleFactor();
    final textScale = (currentScaleFactor + step).clamp(
      WindowSizeManager.minScaleFactor,
      WindowSizeManager.maxScaleFactor,
    );

    Log.info('scale the app from $currentScaleFactor to $textScale');

    await _scale(textScale);
  }

  Future<void> _scale(double scaleFactor) async {
    if (FlowyRunner.currentMode == IntegrationMode.integrationTest) {
      // The integration test will fail if we check the scale factor in the test.
      // #0      ScaledWidgetsFlutterBinding.Eval ()
      // #1      ScaledWidgetsFlutterBinding.instance (package:scaled_app/scaled_app.dart:66:62)
      appflowyScaleFactor = scaleFactor;
    } else {
      ScaledWidgetsFlutterBinding.instance.scaleFactor = (_) => scaleFactor;
    }

    await windowSizeManager.setScaleFactor(scaleFactor);
  }
}
