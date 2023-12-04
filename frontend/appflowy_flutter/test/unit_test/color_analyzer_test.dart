import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appflowy/util/color_analyzer/color_analyzer.dart';

void main() {
  group('ColorAnalyzer Tests', () {
    test('getAppropriateTextColor returns expected color', () {
      const Color backgroundColor = Color(0xff00bcf0);
      const Color primaryTextColor = Color(0xffBBC3CD);
      const Color altTextColor = Color(0xff131720);

      final Color result = ColorAnalyzer.getAppropriateTextColor(
          backgroundColor, primaryTextColor, altTextColor);

      expect(result, altTextColor);
    });

    test('getAppropriateTextColor returns expected color', () {
      const Color backgroundColor = Color(0xff00bcf0);
      const Color primaryTextColor = Color(0xffBBC3CD);
      const Color altTextColor = Color(0xff131720);

      final Color result = ColorAnalyzer.getAppropriateTextColor(
          backgroundColor, primaryTextColor, altTextColor);

      expect(result, altTextColor);
    });

    test('getAppropriateTextColor returns expected color', () {
      final Color backgroundColor = Color(0xffbcf0ff);
      final Color primaryTextColor = Color(0xff333333);
      final Color altTextColor = Color(0xff333333);
      final Color result = ColorAnalyzer.getAppropriateTextColor(
          backgroundColor, primaryTextColor, altTextColor);

      expect(result, altTextColor);
    });
  });

  test('getAppropriateTextColor returns expected color', () {
    const Color backgroundColor = Color(0xff7E194F);
    const Color primaryTextColor = Color(0xffBBC3CD);
    const Color altTextColor = Color(0xff131720);

    final Color result = ColorAnalyzer.getAppropriateTextColor(
        backgroundColor, primaryTextColor, altTextColor);

    expect(result, primaryTextColor);
  });
}
