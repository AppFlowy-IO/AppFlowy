import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart' as flutter_test;

class FlowyTestKeyboard {
  static Future<void> simulateKeyDownEvent(
    List<LogicalKeyboardKey> keys, {
    required flutter_test.WidgetTester tester,
    bool withKeyUp = false,
  }) async {
    for (final LogicalKeyboardKey key in keys) {
      await flutter_test.simulateKeyDownEvent(key);
      await tester.pumpAndSettle();
    }

    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    if (withKeyUp) {
      for (final LogicalKeyboardKey key in keys) {
        await flutter_test.simulateKeyUpEvent(key);
        await tester.pumpAndSettle();
      }
    }
  }
}
