import 'dart:ui';

class ColorGenerator {
  Color generateColorFromString(String string) {
    final hash = string.hashCode;
    final int r = (hash & 0xFF0000) >> 16;
    final int g = (hash & 0x00FF00) >> 8;
    final int b = hash & 0x0000FF;
    return Color.fromRGBO(r, g, b, 0.5);
  }
}
