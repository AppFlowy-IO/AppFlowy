import 'package:appflowy_editor/src/extensions/color_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ColorExtension::', () {
    const white = Color(0XFFFFFFFF);
    const black = Color(0XFF000000);
    const blue = Color(0XFF000FFF);
    const blueRgba = 'rgba(0, 15, 255, 255)';
    test('ToRgbaString', () {
      expect(blue.toRgbaString(), 'rgba(0, 15, 255, 255)');
      expect(white.toRgbaString(), 'rgba(255, 255, 255, 255)');
      expect(black.toRgbaString(), 'rgba(0, 0, 0, 255)');
    });

    test('tryFromRgbaString', () {
      final color = ColorExtension.tryFromRgbaString(blueRgba);
      expect(color, const Color.fromARGB(255, 0, 15, 255));
    });

    test('tryFromRgbaString - wrong rgba format return null', () {
      const wrongRgba = 'abc(1,2,3,4)';
      final color = ColorExtension.tryFromRgbaString(wrongRgba);
      expect(color, null);
    });

    test('tryFromRgbaString - wrong length return null', () {
      const wrongRgba = 'rgba(0, 15, 255)';
      final color = ColorExtension.tryFromRgbaString(wrongRgba);
      expect(color, null);
    });

    test('tryFromRgbaString - wrong values return null', () {
      const wrongRgba = 'rgba(-12, 999, 1234, 619)';
      final color = ColorExtension.tryFromRgbaString(wrongRgba);
      expect(color, null);
    });
  });
}
