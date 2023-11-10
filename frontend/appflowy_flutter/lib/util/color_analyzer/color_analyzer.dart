import 'dart:math';
import 'package:flutter/material.dart';

class ColorAnalyzer {
  static const double RGB_SCALE = 255.0;
  static const double LUMINANCE_THRESHOLD = 0.03928;
  static const double ADJUSTMENT_FACTOR = 12.92;
  static const double SCALE_NORM = 1.055;
  static const List<double> LUMINANCE_COEFFICIENTS = [0.2126, 0.7152, 0.0722];

  double calculateLuminance(Color color) {
    List<double> rgb =
        [color.red, color.green, color.blue].map((c) => c / RGB_SCALE).toList();

    for (int i = 0; i < 3; i++) {
      rgb[i] = rgb[i] <= LUMINANCE_THRESHOLD
          ? rgb[i] / ADJUSTMENT_FACTOR
          : pow((rgb[i] + (SCALE_NORM - 1)) / SCALE_NORM, 2.4).toDouble();
    }

    return rgb[0] * LUMINANCE_COEFFICIENTS[0] +
        rgb[1] * LUMINANCE_COEFFICIENTS[1] +
        rgb[2] * LUMINANCE_COEFFICIENTS[2];
  }

  double calculateContrast(Color color1, Color color2) {
    double luminance1 = calculateLuminance(color1);
    double luminance2 = calculateLuminance(color2);

    if (luminance1 < luminance2) {
      double temp = luminance1;
      luminance1 = luminance2;
      luminance2 = temp;
    }

    return (luminance1 + 0.05) / (luminance2 + 0.05);
  }

  Color getAppropriateTextColor(
      Color backgroundColor, Color primaryTextColor, Color altTextColor) {
    double contrastRatio = calculateContrast(backgroundColor, primaryTextColor);

    return contrastRatio < 1.36 ? altTextColor : primaryTextColor;
  }
}
