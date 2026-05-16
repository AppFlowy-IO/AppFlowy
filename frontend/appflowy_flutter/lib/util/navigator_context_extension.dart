import 'package:flutter/material.dart';

extension NavigatorContext on BuildContext {
  void popToHome() {
    Navigator.of(this).popUntil((route) {
      if (route.settings.name == '/') {
        return true;
      }
      return false;
    });
  }
}
