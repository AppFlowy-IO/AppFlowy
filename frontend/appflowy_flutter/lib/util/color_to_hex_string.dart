import 'dart:math' as math;

import 'package:flutter/material.dart';

extension ColorExtension on Color {
  /// return a hex string in 0xff000000 format
  String toHexString() {
    final alpha = (a * 255).toInt().toRadixString(16).padLeft(2, '0');
    final red = (r * 255).toInt().toRadixString(16).padLeft(2, '0');
    final green = (g * 255).toInt().toRadixString(16).padLeft(2, '0');
    final blue = (b * 255).toInt().toRadixString(16).padLeft(2, '0');

    return '0x$alpha$red$green$blue'.toLowerCase();
  }

  /// return a random color
  static Color random({double opacity = 1.0}) {
    return Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
        .withValues(alpha: opacity);
  }
}
