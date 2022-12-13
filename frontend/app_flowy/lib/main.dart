import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import 'startup/startup.dart';
import 'user/presentation/splash_screen.dart';

class FlowyApp implements EntryPoint {
  @override
  Widget create(List<String> args) {
    var autoRegister = false;
    if (args.isNotEmpty) {
      autoRegister = true;
    }
    return SplashScreen(
      autoRegister: autoRegister,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  WidgetsFlutterBinding.ensureInitialized();
  await hotKeyManager.unregisterAll();

  await FlowyRunner.run(FlowyApp());
}
