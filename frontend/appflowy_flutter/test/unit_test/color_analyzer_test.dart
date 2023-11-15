import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appflowy/util/color_analyzer/color_analyzer.dart';

void main() {
  group('ColorAnalyzer Tests', () {
    test('getAppropriateTextColor returns expected color', () {
      const Color backgroundColor = Color(0xff00bcf0);
      const Color primaryTextColor = Color(0xffBBC3CD);
      const Color altTextColor = Color(0xff131720);
      const Color expectedColor = altTextColor;

      final Color result = ColorAnalyzer.getAppropriateTextColor(
          backgroundColor, primaryTextColor, altTextColor);

      expect(result, expectedColor);
    });

    test('getAppropriateTextColor returns expected color', () {
      const Color backgroundColor = Color(0xff00bcf0);
      const Color primaryTextColor = Color(0xffBBC3CD);
      const Color altTextColor = Color(0xff131720);
      const Color expectedColor = altTextColor;

      final Color result = ColorAnalyzer.getAppropriateTextColor(
          backgroundColor, primaryTextColor, altTextColor);

      expect(result, expectedColor);
    });

    test('getAppropriateTextColor returns expected color', () {
      // Define test colors
      final Color backgroundColor =
          Color(0xffbcf0ff); // Replace with actual color
      final Color primaryTextColor = Color(0xff333333); // Example color
      final Color altTextColor = Color(0xff333333); // Example alternative color
      final Color expectedColor = altTextColor; // Replace with expected result

      final Color result = ColorAnalyzer.getAppropriateTextColor(
          backgroundColor, primaryTextColor, altTextColor);

      expect(result, expectedColor);
    });
  });
}
