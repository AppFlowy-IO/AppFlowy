import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/welcome/presentation/splash_screen.dart';
import 'package:flutter/material.dart';

class FlowyAppFactory implements AppFactory {
  @override
  Widget create() {
    return const SplashScreen();
  }
}

void main() {
  Application.run(FlowyAppFactory());
}
