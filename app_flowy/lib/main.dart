import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/welcome/presentation/welcome_screen.dart';
import 'package:flutter/material.dart';

class FlowyAppFactory implements AppFactory {
  @override
  Widget create() {
    return const WelcomeScreen();
  }
}

void main() {
  App.run(FlowyAppFactory());
}
