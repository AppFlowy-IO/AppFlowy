import 'package:flowy_editor/flowy_editor.dart';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';

abstract class FlowyKeyboardService {
  void enable();
  void disable();
}

typedef FlowyKeyEventHandler = KeyEventResult Function(
  EditorState editorState,
  RawKeyEvent event,
);

/// Process keyboard events
class FlowyKeyboard extends StatefulWidget {
  const FlowyKeyboard({
    Key? key,
    required this.handlers,
    required this.editorState,
    required this.child,
  }) : super(key: key);

  final EditorState editorState;
  final Widget child;
  final List<FlowyKeyEventHandler> handlers;

  @override
  State<FlowyKeyboard> createState() => _FlowyKeyboardState();
}

class _FlowyKeyboardState extends State<FlowyKeyboard>
    implements FlowyKeyboardService {
  final FocusNode _focusNode = FocusNode(debugLabel: 'flowy_keyboard_service');

  bool isFocus = true;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKey: _onKey,
      onFocusChange: _onFocusChange,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();

    super.dispose();
  }

  @override
  void enable() {
    isFocus = true;
    _focusNode.requestFocus();
  }

  @override
  void disable() {
    isFocus = false;
    _focusNode.unfocus();
  }

  void _onFocusChange(bool value) {
    debugPrint('[KeyBoard Service] focus change $value');
  }

  KeyEventResult _onKey(FocusNode node, RawKeyEvent event) {
    if (!isFocus) {
      return KeyEventResult.ignored;
    }

    debugPrint('on keyboard event $event');

    if (event is! RawKeyDownEvent) {
      return KeyEventResult.ignored;
    }

    for (final handler in widget.handlers) {
      // debugPrint('handle keyboard event $event by $handler');

      KeyEventResult result = handler(widget.editorState, event);

      switch (result) {
        case KeyEventResult.handled:
          return KeyEventResult.handled;
        case KeyEventResult.skipRemainingHandlers:
          return KeyEventResult.skipRemainingHandlers;
        case KeyEventResult.ignored:
          continue;
      }
    }

    return KeyEventResult.ignored;
  }
}
