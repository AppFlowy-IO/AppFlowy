import 'dart:ui';

import 'package:app_flowy/core/helpers/helpers.dart';
import 'package:flutter/foundation.dart';
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

    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Size(600, 400),
      title: 'AppFlowy',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    return AppWindow._();
  }
}
