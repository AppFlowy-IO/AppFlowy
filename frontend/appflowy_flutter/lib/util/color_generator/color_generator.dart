import 'package:flutter/material.dart';

extension type ColorGenerator(String value) {
  Color toColor() {
    final int hash = value.codeUnits.fold(0, (int acc, int unit) => acc + unit);
    final double hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.5, 0.8).toColor();
  }
}
