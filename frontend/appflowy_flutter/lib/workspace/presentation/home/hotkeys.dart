import 'dart:io';
import 'package:appflowy/workspace/application/panes/panes_bloc/panes_bloc.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/home/home_setting_bloc.dart';
import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:provider/provider.dart';

typedef KeyDownHandler = void Function(HotKey hotKey);
typedef KeyUpHandler = void Function(HotKey hotKey);

/// Helper class that utilizes the global [HotKeyManager] to easily
/// add a [HotKey] with different handlers.
///
/// Makes registration of a [HotKey] simple and easy to read, and makes
/// sure the [KeyDownHandler], and other handlers, are grouped with the
/// relevant [HotKey].
///
class HotKeyItem {
  final HotKey hotKey;
  final KeyDownHandler? keyDownHandler;
  final KeyUpHandler? keyUpHandler;

  HotKeyItem({
    required this.hotKey,
    this.keyDownHandler,
    this.keyUpHandler,
  });

  void register() => hotKeyManager.register(
        hotKey,
        keyDownHandler: keyDownHandler,
        keyUpHandler: keyUpHandler,
      );
}

class HomeHotKeys extends StatelessWidget {
  final Widget child;
  const HomeHotKeys({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Collapse sidebar menu
    HotKeyItem(
      hotKey: HotKey(
        KeyCode.backslash,
        modifiers: [Platform.isMacOS ? KeyModifier.meta : KeyModifier.control],
        // Set hotkey scope (default is HotKeyScope.system)
        scope: HotKeyScope.inapp, // Set as inapp-wide hotkey.
      ),
      keyDownHandler: (_) => context
          .read<HomeSettingBloc>()
          .add(const HomeSettingEvent.collapseMenu()),
    ).register();

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
    ).register();

    // Close current tab
    HotKeyItem(
      hotKey: HotKey(
        KeyCode.keyW,
        modifiers: [Platform.isMacOS ? KeyModifier.meta : KeyModifier.control],
        scope: HotKeyScope.inapp,
      ),
      keyDownHandler: (_) =>
          context.read<PanesBloc>().add(const CloseCurrentTab()),
    ).register();

    // Go to previous tab
    HotKeyItem(
      hotKey: HotKey(
        KeyCode.pageUp,
        modifiers: [Platform.isMacOS ? KeyModifier.meta : KeyModifier.control],
        scope: HotKeyScope.inapp,
      ),
      keyDownHandler: (_) => _selectTab(context, -1),
    ).register();

    // Go to next tab
    HotKeyItem(
      hotKey: HotKey(
        KeyCode.pageDown,
        modifiers: [Platform.isMacOS ? KeyModifier.meta : KeyModifier.control],
        scope: HotKeyScope.inapp,
      ),
      keyDownHandler: (_) => _selectTab(context, 1),
    ).register();

    // Enable pane drag
    HotKeyItem(
      hotKey: HotKey(
        KeyCode.controlLeft,
        modifiers: [Platform.isMacOS ? KeyModifier.meta : KeyModifier.control],
        scope: HotKeyScope.inapp,
      ),
      keyDownHandler: (_) => _setDragStatus(context, true),
      keyUpHandler: (_) => _setDragStatus(context, false),
    ).register();

    return child;
  }

  void _selectTab(BuildContext context, int change) {
    final bloc = context.read<PanesBloc>();
    bloc.add(
      SelectTab(index: bloc.state.activePane.tabs.currentIndex + change),
    );
  }

  void _setDragStatus(BuildContext context, bool status) {
    final bloc = context.read<PanesBloc>();
    bloc.add(SetDragStatus(status: status));
  }
}
