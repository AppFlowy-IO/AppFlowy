import 'package:flutter/services.dart';

import 'editor_state.dart';
import 'package:flutter/material.dart';

abstract class FlowyKeyboardHandler {
  final EditorState editorState;
  final RawKeyEvent rawKeyEvent;

  FlowyKeyboardHandler({
    required this.editorState,
    required this.rawKeyEvent,
  });

  KeyEventResult onKeyDown();
}

/// Process keyboard events
class FlowyKeyboardWidget extends StatefulWidget {
  const FlowyKeyboardWidget({
    Key? key,
    required this.handlers,
    required this.editorState,
    required this.child,
  }) : super(key: key);

  final EditorState editorState;
  final Widget child;
  final List<FlowyKeyboardHandler> handlers;

  @override
  State<FlowyKeyboardWidget> createState() => _FlowyKeyboardWidgetState();
}

class _FlowyKeyboardWidgetState extends State<FlowyKeyboardWidget> {
  final FocusNode focusNode = FocusNode(debugLabel: 'flowy_keyboard_service');

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      autofocus: true,
      onKey: _onKey,
      child: widget.child,
    );
  }

  KeyEventResult _onKey(FocusNode node, RawKeyEvent event) {
    if (event is! RawKeyDownEvent) {
      return KeyEventResult.ignored;
    }

    for (final handler in widget.handlers) {
      debugPrint('handle keyboard event $event by $handler');

      KeyEventResult result = handler.onKeyDown();

      switch (result) {
        case KeyEventResult.handled:
          return KeyEventResult.handled;
        case KeyEventResult.skipRemainingHandlers:
          return KeyEventResult.skipRemainingHandlers;
        case KeyEventResult.ignored:
          break;
      }
    }

    return KeyEventResult.ignored;
  }
}
