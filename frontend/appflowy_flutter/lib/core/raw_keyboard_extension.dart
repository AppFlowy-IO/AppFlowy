import 'package:flutter/services.dart';

extension RawKeyboardExtension on RawKeyboard {
  bool get isAltPressed => keysPressed.any(
        (key) => [
          LogicalKeyboardKey.alt,
          LogicalKeyboardKey.altLeft,
          LogicalKeyboardKey.altRight,
        ].contains(key),
      );
}
