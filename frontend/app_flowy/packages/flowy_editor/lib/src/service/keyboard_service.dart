import 'package:flowy_editor/flowy_editor.dart';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';

/// [FlowyKeyboardService] is responsible for processing shortcut keys,
///   like command, shift, control keys.
///
/// Usually, this service can be obtained by the following code.
/// ```dart
/// final keyboardService = editorState.service.keyboardService;
///
/// /** Simulates shortcut key input*/
/// keyboardService?.onKey(...);
///
/// /** Enables or disables this service */
/// keyboardService?.enable();
/// keyboardService?.disable();
/// ```
///
abstract class FlowyKeyboardService {
  /// Processes shortcut key input.
  KeyEventResult onKey(RawKeyEvent event);

  /// Enables shortcuts service.
  void enable();

  /// Disables shortcuts service.
  ///
  /// In some cases, if your custom component needs to monitor
  ///   keyboard events separately,
  ///   you can disable the keyboard service of flowy_editor.
  /// But you need to call the `enable` function to restore after exiting
  ///   your custom component, otherwise the keyboard service will fails.
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

  @override
  KeyEventResult onKey(RawKeyEvent event) {
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

  void _onFocusChange(bool value) {
    debugPrint('[KeyBoard Service] focus change $value');
  }

  KeyEventResult _onKey(FocusNode node, RawKeyEvent event) {
    if (!isFocus) {
      return KeyEventResult.ignored;
    }

    return onKey(event);
  }
}
