import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flowy_editor/editor_state.dart';
import 'package:flowy_editor/service/default_key_event_handlers.dart';

mixin FlowyKeyboardService<T extends StatefulWidget> on State<T> {
  void enable();
  void disable();
}

typedef FlowyKeyEventHandler = KeyEventResult Function(
  EditorState editorState,
  RawKeyEvent event,
);

/// Process keyboard events
class FlowyKeyboard extends StatefulWidget {
  FlowyKeyboard({
    Key? key,
    List<FlowyKeyEventHandler> handlers = const [],
    required this.editorState,
    required this.child,
  }) : super(key: key) {
    this.handlers.addAll(handlers);
  }

  final EditorState editorState;
  final Widget child;
  final List<FlowyKeyEventHandler> handlers = defaultKeyEventHandlers;

  @override
  State<FlowyKeyboard> createState() => _FlowyKeyboardState();
}

class _FlowyKeyboardState extends State<FlowyKeyboard>
    with FlowyKeyboardService {
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
