import 'package:flutter/material.dart';

class ColorGenerator {
  static Color generateColorFromString(String string) {
    final int hash =
        string.codeUnits.fold(0, (int acc, int unit) => acc + unit);
    final double hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.5, 0.8).toColor();
  }
}
