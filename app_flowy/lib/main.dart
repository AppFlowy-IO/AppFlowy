import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/welcome/presentation/splash_screen.dart';
import 'package:flutter/material.dart';

class FlowyApp implements EntryPoint {
  @override
  Widget create() {
    return const SplashScreen();
  }
}

void main() {
  System.run(FlowyApp());
}
