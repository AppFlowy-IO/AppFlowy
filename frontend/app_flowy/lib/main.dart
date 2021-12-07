import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/user/presentation/splash_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class FlowyApp implements EntryPoint {
  @override
  Widget create() {
    return const SplashScreen();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  System.run(FlowyApp());
}
