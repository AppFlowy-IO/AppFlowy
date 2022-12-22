import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

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

  WidgetsFlutterBinding.ensureInitialized();
  await hotKeyManager.unregisterAll();

  await FlowyRunner.run(FlowyApp());
}
