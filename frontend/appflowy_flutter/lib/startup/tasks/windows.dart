import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/core/helpers/helpers.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/app_window_size_manager.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:scaled_app/scaled_app.dart';
import 'package:window_manager/window_manager.dart';

class InitAppWindowTask extends LaunchTask with WindowListener {
  InitAppWindowTask({
    this.title = 'AppFlowy',
  });

  final String title;

  final windowSizeManager = WindowSizeManager();

  @override
  Future<void> initialize(LaunchContext context) async {
    // Don't initialize on mobile or web.
    if (!defaultTargetPlatform.isDesktop || context.env.isIntegrationTest) {
      return;
    }

    await windowManager.ensureInitialized();
    windowManager.addListener(this);

    final windowSize = await windowSizeManager.getSize();
    final windowOptions = WindowOptions(
      size: windowSize,
      minimumSize: const Size(
        WindowSizeManager.minWindowWidth,
        WindowSizeManager.minWindowHeight,
      ),
      maximumSize: const Size(
        WindowSizeManager.maxWindowWidth,
        WindowSizeManager.maxWindowHeight,
      ),
      title: title,
    );

    final position = await windowSizeManager.getPosition();

    if (PlatformExtension.isWindows) {
      doWhenWindowReady(() {
        appWindow.minSize = windowOptions.minimumSize;
        appWindow.maxSize = windowOptions.maximumSize;
        appWindow.size = windowSize;

        if (position != null) {
          appWindow.position = position;
        }

        appWindow.show();
      });
    } else {
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();

        if (position != null) {
          await windowManager.setPosition(position);
        }
      });
    }

    unawaited(
      windowSizeManager.getScaleFactor().then(
            (v) => ScaledWidgetsFlutterBinding.instance.scaleFactor = (_) => v,
          ),
    );
  }

  @override
  Future<void> onWindowResize() async {
    super.onWindowResize();

    final currentWindowSize = await windowManager.getSize();
    return windowSizeManager.setSize(currentWindowSize);
  }

  @override
  void onWindowMaximize() async {
    super.onWindowMaximize();

    final currentWindowSize = await windowManager.getSize();
    return windowSizeManager.setSize(currentWindowSize);
  }

  @override
  void onWindowMoved() async {
    super.onWindowMoved();

    final position = await windowManager.getPosition();
    return windowSizeManager.setPosition(position);
  }

  @override
  Future<void> dispose() async {}
}
