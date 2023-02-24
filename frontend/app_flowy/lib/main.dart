import 'package:appflowy_backend/log.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import 'startup/launch_configuration.dart';
import 'startup/startup.dart';
import 'user/presentation/splash_screen.dart';
import 'window/window.dart';

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

  // Handle platform errors not caught by Flutter.
  // Reduces the likelihood of the app crashing, and logs the error.
  PlatformDispatcher.instance.onError = (error, stack) {
    Log.error('Uncaught platform error', error, stack);
    return true;
  };

  await EasyLocalization.ensureInitialized();
  await hotKeyManager.unregisterAll();

  await AppWindow.initialize();

  await FlowyRunner.run(FlowyApp());
}
