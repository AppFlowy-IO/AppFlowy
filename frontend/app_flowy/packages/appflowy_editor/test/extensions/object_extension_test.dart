import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appflowy_editor/src/extensions/object_extensions.dart';

void main() {
  group('FlowyObjectExtensions::', () {
    test('unwrapOrNull', () {
      final result = const TextSpan().unwrapOrNull<HitTestTarget>();
      assert(result is TextSpan);
    });

    test('unwrapOrNull - return null', () {
      final result = const TextSpan().unwrapOrNull<ServerSocket>();
      expect(result, null);
    });
  });
}
