import 'package:flowy_editor/operation/transaction_builder.dart';
import 'package:flutter/services.dart';

import '../editor_state.dart';
import 'package:flutter/material.dart';

typedef FlowyKeyEventHandler = KeyEventResult Function(
  EditorState editorState,
  RawKeyEvent event,
);

FlowyKeyEventHandler flowyDeleteNodesHandler = (editorState, event) {
  // Handle delete nodes.
  final nodes = editorState.selectedNodes;
  if (nodes.length <= 1) {
    return KeyEventResult.ignored;
  }

  debugPrint('delete nodes = $nodes');

  nodes
      .fold<TransactionBuilder>(
        TransactionBuilder(editorState),
        (previousValue, node) => previousValue..deleteNode(node),
      )
      .commit();
  return KeyEventResult.handled;
};

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
  final List<FlowyKeyEventHandler> handlers;

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
    debugPrint('on keyboard event $event');

    if (event is! RawKeyDownEvent) {
      return KeyEventResult.ignored;
    }

    for (final handler in widget.handlers) {
      debugPrint('handle keyboard event $event by $handler');

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
