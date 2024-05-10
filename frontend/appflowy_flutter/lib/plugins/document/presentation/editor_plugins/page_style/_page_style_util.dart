import 'package:flutter/material.dart';

extension PageStyleUtil on BuildContext {
  Color get pageStyleBackgroundColor {
    final themeMode = Theme.of(this).brightness;
    return themeMode == Brightness.light
        ? const Color(0xFFF5F5F8)
        : const Color(0xFF303030);
  }

  Color get pageStyleTextColor {
    final themeMode = Theme.of(this).brightness;
    return themeMode == Brightness.light
        ? const Color(0x7F1F2225)
        : Colors.white54;
  }
}
