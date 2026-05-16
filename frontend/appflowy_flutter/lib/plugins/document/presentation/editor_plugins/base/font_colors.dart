import 'package:flutter/material.dart';

class EditorFontColors {
  static final lightColors = [
    const Color(0x00FFFFFF),
    const Color(0xFFE8E0FF),
    const Color(0xFFFFE6FD),
    const Color(0xFFFFDAE6),
    const Color(0xFFFFEFE3),
    const Color(0xFFF5FFDC),
    const Color(0xFFDDFFD6),
    const Color(0xFFDEFFF1),
    const Color(0xFFE1FBFF),
    const Color(0xFFFFADAD),
    const Color(0xFFFFE088),
    const Color(0xFFA7DF4A),
    const Color(0xFFD4C0FF),
    const Color(0xFFFDB2FE),
    const Color(0xFFFFD18B),
    const Color(0xFF65E7F0),
    const Color(0xFF71E6B4),
    const Color(0xFF80F1FF),
  ];

  static final darkColors = [
    const Color(0x00FFFFFF),
    const Color(0xFF8B80AD),
    const Color(0xFF987195),
    const Color(0xFF906D78),
    const Color(0xFFA68B77),
    const Color(0xFF88936D),
    const Color(0xFF72936B),
    const Color(0xFF6B9483),
    const Color(0xFF658B90),
    const Color(0xFF95405A),
    const Color(0xFFA6784D),
    const Color(0xFF6E9234),
    const Color(0xFF6455A2),
    const Color(0xFF924F83),
    const Color(0xFFA48F34),
    const Color(0xFF29A3AC),
    const Color(0xFF2E9F84),
    const Color(0xFF405EA6),
  ];

  // if the input color doesn't exist in the list, return the input color itself.
  static Color? fromBuiltInColors(BuildContext context, Color? color) {
    if (color == null) {
      return null;
    }

    final brightness = Theme.of(context).brightness;

    // if the dark mode color using light mode, return it's corresponding light color. Same for light mode.
    if (brightness == Brightness.light) {
      if (darkColors.contains(color)) {
        return lightColors[darkColors.indexOf(color)];
      }
    } else {
      if (lightColors.contains(color)) {
        return darkColors[lightColors.indexOf(color)];
      }
    }
    return color;
  }
}
