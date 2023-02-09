import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'startup/launch_configuration.dart';
import 'startup/startup.dart';
import 'user/presentation/splash_screen.dart';

class FlowyApp implements EntryPoint {
  @override
  Widget create(LaunchConfiguration config) {
    return SplashScreen(
      autoRegister: config.autoRegistrationSupported,
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized();
  await hotKeyManager.unregisterAll();
  await windowManager.ensureInitialized();

  await setWindowOptions();

  await FlowyRunner.run(FlowyApp());
}

Future<void> setWindowOptions() async {
  WindowOptions windowOptions = const WindowOptions(
    minimumSize: Size(600, 400),
  );
  return windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}
