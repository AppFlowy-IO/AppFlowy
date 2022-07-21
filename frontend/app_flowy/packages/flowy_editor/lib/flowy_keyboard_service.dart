import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/operation/transaction.dart';
import 'package:flowy_editor/operation/transaction_builder.dart';
import 'package:flowy_editor/render/selectable.dart';
import 'package:flutter/services.dart';

import 'editor_state.dart';
import 'package:flutter/material.dart';

abstract class FlowyKeyboardHandler {
  final EditorState editorState;

  FlowyKeyboardHandler({
    required this.editorState,
  });

  KeyEventResult onKeyDown(RawKeyEvent event);
}

class FlowyKeyboradBackSpaceHandler extends FlowyKeyboardHandler {
  FlowyKeyboradBackSpaceHandler({
    required super.editorState,
  });

  @override
  KeyEventResult onKeyDown(RawKeyEvent event) {
    final selectedNodes = editorState.selectedNodes;
    if (selectedNodes.isNotEmpty) {
      // handle delete text
      // TODO: type: cursor or selection
      if (selectedNodes.length == 1) {
        final node = selectedNodes.first;
        if (node is TextNode) {
          final selectable = node.key?.currentState as Selectable?;
          final textSelection = selectable?.getTextSelection();
          if (textSelection != null) {
            if (textSelection.isCollapsed) {
              TransactionBuilder(editorState)
                ..deleteText(node, textSelection.start - 1, 1)
                ..commit();
              // TODO: update selection??
            }
          }
        }
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
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
    debugPrint('on keyboard event $event');

    if (event is! RawKeyDownEvent) {
      return KeyEventResult.ignored;
    }

    for (final handler in widget.handlers) {
      debugPrint('handle keyboard event $event by $handler');

      KeyEventResult result = handler.onKeyDown(event);

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
