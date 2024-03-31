import 'dart:math' as math;

import 'package:flutter/material.dart';

extension ColorExtension on Color {
  /// return a hex string in 0xff000000 format
  String toHexString() {
    return '0x${value.toRadixString(16).padLeft(8, '0')}';
  }

  /// return a random color
  static Color random({double opacity = 1.0}) {
    return Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
        .withOpacity(opacity);
  }
}
