import 'dart:ui';

import 'package:appflowy/core/helpers/helpers.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/app_window_size_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class InitAppWindowTask extends LaunchTask with WindowListener {
  const InitAppWindowTask({
    this.minimumSize = const Size(800, 600),
    this.title = 'AppFlowy',
  });

  final Size minimumSize;
  final String title;

  @override
  Future<void> initialize(LaunchContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Don't initialize on mobile or web.
    if (!defaultTargetPlatform.isDesktop) {
      return;
    }

    await windowManager.ensureInitialized();
    windowManager.addListener(this);

    Size windowSize = await WindowSizeManager().getSize();
    if (context.env.isIntegrationTest()) {
      windowSize = const Size(1600, 1200);
    }

    final windowOptions = WindowOptions(
      size: windowSize,
      minimumSize: const Size(
        WindowSizeManager.minWindowWidth,
        WindowSizeManager.minWindowHeight,
      ),
      title: title,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    if (prefs.getBool('maximized') == true) {
      windowManager.maximize();
    } else if (prefs.getBool('maximized') == false) {
      print("");
    } else if (prefs.getBool('maximized') == null) {
      print("");
    }
  }

  @override
  Future<void> onWindowResize() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final currentWindowSize = await windowManager.getSize();
    if (windowManager.isMaximized() == true) {
      await prefs.setBool('maximized', true);
    } else {
      await prefs.setBool('maximized', false);
    }
    WindowSizeManager().saveSize(currentWindowSize);
  }
}
