import 'package:flutter/services.dart';

class TestRawKeyEvent extends RawKeyDownEvent {
  const TestRawKeyEvent({required super.data});
}

class TestRawKeyEventData extends RawKeyEventData {
  const TestRawKeyEventData({
    required this.logicalKey,
    this.isControlPressed = false,
    this.isShiftPressed = false,
    this.isAltPressed = false,
    this.isMetaPressed = false,
  });

  @override
  final bool isControlPressed;

  @override
  final bool isShiftPressed;

  @override
  final bool isAltPressed;

  @override
  final bool isMetaPressed;

  @override
  final LogicalKeyboardKey logicalKey;

  @override
  PhysicalKeyboardKey get physicalKey => logicalKey.toPhysicalKey;

  @override
  KeyboardSide? getModifierSide(ModifierKey key) {
    throw UnimplementedError();
  }

  @override
  bool isModifierPressed(ModifierKey key,
      {KeyboardSide side = KeyboardSide.any}) {
    throw UnimplementedError();
  }

  @override
  String get keyLabel => throw UnimplementedError();

  RawKeyEvent get toKeyEvent {
    return TestRawKeyEvent(data: this);
  }
}

extension on LogicalKeyboardKey {
  PhysicalKeyboardKey get toPhysicalKey {
    if (this == LogicalKeyboardKey.enter) {
      return PhysicalKeyboardKey.enter;
    }
    if (this == LogicalKeyboardKey.backspace) {
      return PhysicalKeyboardKey.backspace;
    }
    if (this == LogicalKeyboardKey.delete) {
      return PhysicalKeyboardKey.delete;
    }
    throw UnimplementedError();
  }
}
