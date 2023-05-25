import 'dart:ui';

import 'package:appflowy/core/helpers/helpers.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

class InitAppWindowTask extends LaunchTask {
  const InitAppWindowTask({
    this.minimumSize = const Size(800, 600),
    this.title = 'AppFlowy',
  });

  final Size minimumSize;
  final String title;

  @override
  Future<void> initialize(LaunchContext context) async {
    // Don't initialize on mobile or web.
    if (!defaultTargetPlatform.isDesktop) {
      return;
    }

    await windowManager.ensureInitialized();

    WindowOptions windowOptions = WindowOptions(
      minimumSize: minimumSize,
      title: title,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
}
