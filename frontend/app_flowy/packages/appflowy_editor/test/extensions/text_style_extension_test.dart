import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appflowy_editor/src/extensions/text_style_extension.dart';

void main() {
  group('TextStyleExtensions::', () {
    const style = TextStyle(
      color: Colors.blue,
      backgroundColor: Colors.white,
      fontSize: 14,
      height: 100,
      wordSpacing: 2,
      fontWeight: FontWeight.w700,
    );

    const otherStyle = TextStyle(
      color: Colors.red,
      backgroundColor: Colors.black,
      fontSize: 12,
      height: 10,
      wordSpacing: 1,
    );
    test('combine', () {
      final result = style.combine(otherStyle);
      expect(result.color, Colors.red);
      expect(result.backgroundColor, Colors.black);
      expect(result.fontSize, 12);
      expect(result.height, 10);
      expect(result.wordSpacing, 1);
    });

    test('combine - return this', () {
      final result = style.combine(null);
      expect(result, style);
    });

    test('combine - return null with inherit', () {
      final styleCopy = otherStyle.copyWith(inherit: false);
      final result = style.combine(styleCopy);
      expect(result, styleCopy);
    });
  });
}
