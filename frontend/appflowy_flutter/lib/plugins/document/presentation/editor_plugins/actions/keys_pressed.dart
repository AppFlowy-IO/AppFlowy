import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeysPressed extends StatefulWidget {
  final Widget child;

  const KeysPressed({
    super.key,
    required this.child,
  });

  @override
  State<KeysPressed> createState() => _KeysPressedState();
}

class _KeysPressedState extends State<KeysPressed> {
  final _focusNode = FocusNode();

  bool _isAltPressed = false;

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event is KeyRepeatEvent) {
          return;
        }

        // TODO(Xazin): Improve to allow for any key we need to track
        if (LogicalKeyboardKey.altLeft == event.logicalKey) {
          final isPressed = event is KeyDownEvent;

          if (isPressed != _isAltPressed) {
            setState(() => _isAltPressed = isPressed);
          }
        }
      },
      child: KeysPressedManager(
        isAltPressed: _isAltPressed,
        child: widget.child,
      ),
    );
  }
}

class KeysPressedManager extends InheritedWidget {
  final bool isAltPressed;

  const KeysPressedManager({
    super.key,
    this.isAltPressed = false,
    required super.child,
  });

  static KeysPressedManager? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KeysPressedManager>();

  @override
  bool updateShouldNotify(covariant KeysPressedManager oldWidget) {
    return isAltPressed != oldWidget.isAltPressed;
  }
}
