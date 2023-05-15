import 'dart:ui';

import 'package:appflowy/util/color_picker/color_picker_service.dart';

class ColorPicker implements ColorPickerService {
  @override
  Color generateRandomNameColor(String name) {
    final hash = name.hashCode;
    final h = _normalizeHash(hash, 0, 360);
    final s = _normalizeHash(hash, 50, 75);
    final l = _normalizeHash(hash, 25, 60);
    final color = _hslToColor([h, s, l]);
    return color;
  }

  Color _hslToColor(List<int> hsl) {
    final h = hsl[0] / 360.0;
    final s = hsl[1] / 100.0;
    final l = hsl[2] / 100.0;
    late final double r, g, b;

    if (s == 0) {
      r = g = b = l;
    } else {
      final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
      final p = 2 * l - q;
      r = _hueToRGB(p, q, h + 1 / 3);
      g = _hueToRGB(p, q, h);
      b = _hueToRGB(p, q, h - 1 / 3);
    }

    final red = (r * 255).round();
    final green = (g * 255).round();
    final blue = (b * 255).round();
    return Color.fromARGB(255, red, green, blue);
  }

  double _hueToRGB(double p, double q, double t) {
    if (t < 0) t += 1;
    if (t > 1) t -= 1;
    if (t < 1 / 6) return p + (q - p) * 6 * t;
    if (t < 1 / 2) return q;
    if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
    return p;
  }

  int _normalizeHash(int hash, int min, int max) {
    return (hash % (max - min)) + min;
  }
}
