import 'dart:ui';

import 'package:appflowy/core/helpers/helpers.dart';
import 'package:appflowy/window/app_window_listner.dart';
import 'package:appflowy/window/app_window_size_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Represents the main window of the app.
class AppWindow {
  /// The singleton instance of the window.
  static late AppWindow instance;

  AppWindow._() {
    instance = this;
  }

  /// Initializes the window.
  static Future<AppWindow?> initialize() async {
    // Don't initialize on mobile or web.
    if (!defaultTargetPlatform.isDesktop) {
      return null;
    }

    await windowManager.ensureInitialized();
    final windowSize = await WindowSizeManager().getSize();

    final WindowOptions windowOptions = WindowOptions(
      size: windowSize,
      minimumSize: const Size(
        WindowSizeManager.minWindowWidth,
        WindowSizeManager.minWindowHeight,
      ),
      center: true,
      title: 'AppFlowy',
    );

    AppWindowListener().start();

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    return AppWindow._();
  }
}
