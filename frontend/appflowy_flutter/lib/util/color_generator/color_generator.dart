import 'dart:ui';

class ColorGenerator {
  Color generateColorFromString(String string) {
    final hash = string.hashCode;
    int r = (hash & 0xFF0000) >> 16;
    int g = (hash & 0x00FF00) >> 8;
    int b = hash & 0x0000FF;
    return Color.fromRGBO(r, g, b, 0.5);
  }
}
