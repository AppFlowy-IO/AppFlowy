import 'package:flowy_editor/flowy_editor.dart';
import 'package:flowy_editor/service/keyboard_service.dart';
import 'package:flowy_editor/extensions/object_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// type '/' to trigger shortcut widget
FlowyKeyEventHandler slashShortcutHandler = (editorState, event) {
  if (event.logicalKey != LogicalKeyboardKey.slash) {
    return KeyEventResult.ignored;
  }

  final selectedNodes = editorState.selectedNodes;
  if (selectedNodes.length != 1) {
    return KeyEventResult.ignored;
  }

  final textNode = selectedNodes.first.unwrapOrNull<TextNode>();
  final selectable = textNode?.key?.currentState?.unwrapOrNull<Selectable>();
  final textSelection = selectable?.getCurrentTextSelection();
  // if (textNode != null && selectable != null && textSelection != null) {
  //   final offset = selectable.getOffsetByTextSelection(textSelection);
  //   final rect = selectable.getCursorRect(offset);
  //   editorState.service.floatingToolbarService
  //       .showInOffset(rect.topLeft, textNode.layerLink);
  //   return KeyEventResult.handled;
  // }

  return KeyEventResult.ignored;
};
