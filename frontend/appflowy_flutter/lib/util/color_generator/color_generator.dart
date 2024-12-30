import 'package:flutter/material.dart';

// the color set generated from AI
final _builtInColorSet = [
  (const Color(0xFF8A2BE2), const Color(0xFFF0E6FF)),
  (const Color(0xFF2E8B57), const Color(0xFFE0FFF0)),
  (const Color(0xFF1E90FF), const Color(0xFFE6F3FF)),
  (const Color(0xFFFF7F50), const Color(0xFFFFF0E6)),
  (const Color(0xFFFF69B4), const Color(0xFFFFE6F0)),
  (const Color(0xFF20B2AA), const Color(0xFFE0FFFF)),
  (const Color(0xFFDC143C), const Color(0xFFFFE6E6)),
  (const Color(0xFF8B4513), const Color(0xFFFFF0E6)),
];

extension type ColorGenerator(String value) {
  Color toColor() {
    final int hash = value.codeUnits.fold(0, (int acc, int unit) => acc + unit);
    final double hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.5, 0.8).toColor();
  }

  // shuffle a color from the built-in color set, for the same name, the result should be the same
  (Color, Color) randomColor() {
    final hash = value.codeUnits.fold(0, (int acc, int unit) => acc + unit);
    final index = hash % _builtInColorSet.length;
    return _builtInColorSet[index];
  }
}
