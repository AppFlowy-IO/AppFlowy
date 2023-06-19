import 'dart:io';

import 'package:appflowy/workspace/application/home/home_setting_bloc.dart';
import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:provider/provider.dart';

class HomeHotKeys extends StatelessWidget {
  final Widget child;
  const HomeHotKeys({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final HotKey hotKey = HotKey(
      KeyCode.backslash,
      modifiers: [Platform.isMacOS ? KeyModifier.meta : KeyModifier.control],
      // Set hotkey scope (default is HotKeyScope.system)
      scope: HotKeyScope.inapp, // Set as inapp-wide hotkey.
    );
    hotKeyManager.register(
      hotKey,
      keyDownHandler: (hotKey) {
        context
            .read<HomeSettingBloc>()
            .add(const HomeSettingEvent.collapseMenu());
      },
    );
    return child;
  }
}
