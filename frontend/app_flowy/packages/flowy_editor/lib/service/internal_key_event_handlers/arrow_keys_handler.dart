import 'package:flowy_editor/extensions/object_extensions.dart';
import 'package:flowy_editor/flowy_editor.dart';
import 'package:flowy_editor/service/keyboard_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

FlowyKeyEventHandler arrowKeysHandler = (editorState, event) {
  if (event.logicalKey != LogicalKeyboardKey.arrowUp &&
      event.logicalKey != LogicalKeyboardKey.arrowDown &&
      event.logicalKey != LogicalKeyboardKey.arrowLeft &&
      event.logicalKey != LogicalKeyboardKey.arrowRight) {
    return KeyEventResult.ignored;
  }

  // TODO: Up and Down

  // Left and Right
  final selectedNodes = editorState.selectedNodes;
  if (selectedNodes.length != 1) {
    return KeyEventResult.ignored;
  }

  final node = selectedNodes.first.unwrapOrNull<TextNode>();
  final selectable = node?.key?.currentState?.unwrapOrNull<Selectable>();
  Offset? offset;
  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
    offset = selectable?.getBackwardOffset();
  } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
    offset = selectable?.getForwardOffset();
  }
  final selectionService = editorState.service.selectionService;
  if (offset != null) {
    selectionService.updateCursor(offset);
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};
