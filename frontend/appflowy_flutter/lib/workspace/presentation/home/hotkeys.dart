import 'dart:io';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/home/home_setting_bloc.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/sidebar/rename_view/rename_view_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_setting.dart';
import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:provider/provider.dart';

typedef KeyDownHandler = void Function(HotKey hotKey);

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
    required this.child,
  });

  final Widget child;

  @override
  State<HomeHotKeys> createState() => _HomeHotKeysState();
}

class _HomeHotKeysState extends State<HomeHotKeys> {
  late final items = [
    // Collapse sidebar menu
    HotKeyItem(
      hotKey: HotKey(
        Platform.isMacOS ? KeyCode.period : KeyCode.backslash,
        modifiers: [Platform.isMacOS ? KeyModifier.meta : KeyModifier.control],
        // Set hotkey scope (default is HotKeyScope.system)
        scope: HotKeyScope.inapp, // Set as inapp-wide hotkey.
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
  Widget build(BuildContext context) {
    return widget.child;
  }

  void _registerHotKeys(BuildContext context) {
    for (final element in items) {
      element.register();
    }

    _asyncRegistration(context);
  }

  Future<void> _asyncRegistration(BuildContext context) async {
    (await openSettingsHotKey(context))?.register();
  }

  void _selectTab(BuildContext context, int change) {
    final bloc = context.read<TabsBloc>();
    bloc.add(TabsEvent.selectTab(bloc.state.currentIndex + change));
  }
}
