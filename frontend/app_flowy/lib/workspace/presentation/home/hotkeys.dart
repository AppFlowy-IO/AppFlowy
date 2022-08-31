import 'dart:io';

import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/home/home_bloc.dart';
import 'package:app_flowy/workspace/presentation/home/home_stack.dart';
import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:provider/provider.dart';

class HomeHotKeys extends StatelessWidget {
  final Widget child;
  const HomeHotKeys({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    HotKey hotKey = HotKey(
      KeyCode.backslash,
      modifiers: [Platform.isMacOS ? KeyModifier.meta : KeyModifier.control],
      // Set hotkey scope (default is HotKeyScope.system)
      scope: HotKeyScope.inapp, // Set as inapp-wide hotkey.
    );
    hotKeyManager.register(
      hotKey,
      keyDownHandler: (hotKey) {
        context.read<HomeBloc>().add(const HomeEvent.collapseMenu());
        getIt<HomeStackManager>().collapsedNotifier.value =
            !getIt<HomeStackManager>().collapsedNotifier.currentValue!;
      },
    );
    return child;
  }
}
