import 'dart:math';
import 'package:flutter/material.dart';

class ColorAnalyzer {
  static const double rgbScale = 255.0;
  static const double luminanceThreshold = 0.03928;
  static const double adjustmentFactor = 12.92;
  static const double scaleNorm = 1.055;
  static const double contrastThreshold = 1.36;
  static const List<double> luminanceCoefficients = [0.2126, 0.7152, 0.0722];

  static double calculateLuminance(Color color) {
    final List<double> rgb =
        [color.red, color.green, color.blue].map((c) => c / rgbScale).toList();

    for (int i = 0; i < 3; i++) {
      rgb[i] = rgb[i] <= luminanceThreshold
          ? rgb[i] / adjustmentFactor
          : pow((rgb[i] + (scaleNorm - 1)) / scaleNorm, 2.4).toDouble();
    }

    return rgb[0] * luminanceCoefficients[0] +
        rgb[1] * luminanceCoefficients[1] +
        rgb[2] * luminanceCoefficients[2];
  }

  static double calculateContrast(Color color1, Color color2) {
    double luminance1 = calculateLuminance(color1);
    double luminance2 = calculateLuminance(color2);

    if (luminance1 < luminance2) {
      final double temp = luminance1;
      luminance1 = luminance2;
      luminance2 = temp;
    }

    return (luminance1 + 0.05) / (luminance2 + 0.05);
  }

  static Color getAppropriateTextColor(
    Color backgroundColor,
    Color primaryTextColor,
    Color altTextColor,
  ) {
    final double contrastRatio =
        calculateContrast(backgroundColor, primaryTextColor);

    return contrastRatio < contrastThreshold ? altTextColor : primaryTextColor;
  }
}
