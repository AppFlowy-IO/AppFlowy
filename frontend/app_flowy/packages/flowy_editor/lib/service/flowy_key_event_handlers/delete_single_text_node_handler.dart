import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/editor_state.dart';
import 'package:flowy_editor/operation/transaction_builder.dart';
import 'package:flowy_editor/render/selection/selectable.dart';
import 'package:flowy_editor/service/keyboard_service.dart';
import 'package:flowy_editor/extensions/object_extensions.dart';
import 'package:flowy_editor/service/selection_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// TODO: need to be refactored, just a example code.
FlowyKeyEventHandler deleteSingleTextNodeHandler = (editorState, event) {
  if (event.logicalKey != LogicalKeyboardKey.backspace) {
    return KeyEventResult.ignored;
  }

  final selectionNodes = editorState.selectedNodes;
  if (selectionNodes.length == 1 && selectionNodes.first is TextNode) {
    final node = selectionNodes.first.unwrapOrNull<TextNode>();
    final selectable = node?.key?.currentState?.unwrapOrNull<Selectable>();
    if (selectable != null) {
      final textSelection = selectable.getTextSelection();
      if (textSelection != null) {
        if (textSelection.isCollapsed) {
          /// Three cases:
          /// Delete the zero character,
          ///   1. if there is still text node in front of it, then merge them.
          ///   2. if not, just ignore
          /// Delete the non-zero character,
          ///   3. delete the single character.
          if (textSelection.baseOffset == 0) {
            if (node?.previous != null && node?.previous is TextNode) {
              final previous = node!.previous! as TextNode;
              final newTextSelection = TextSelection.collapsed(
                  offset: previous.toRawString().length);
              final selectionService =
                  selectionServiceKey.currentState as FlowySelectionService;
              final previousSelectable =
                  previous.key?.currentState?.unwrapOrNull<Selectable>();
              final newOfset = previousSelectable
                  ?.getOffsetByTextSelection(newTextSelection);
              if (newOfset != null) {
                selectionService.updateCursor(newOfset);
              }
              // merge
              TransactionBuilder(editorState)
                ..deleteNode(node)
                ..insertText(
                    previous, previous.toRawString().length, node.toRawString())
                ..commit();
              return KeyEventResult.handled;
            } else {
              return KeyEventResult.ignored;
            }
          } else {
            TransactionBuilder(editorState)
              ..deleteText(node!, textSelection.baseOffset - 1, 1)
              ..commit();
            final newTextSelection =
                TextSelection.collapsed(offset: textSelection.baseOffset - 1);
            final selectionService =
                selectionServiceKey.currentState as FlowySelectionService;
            final newOfset =
                selectable.getOffsetByTextSelection(newTextSelection);
            selectionService.updateCursor(newOfset);
            return KeyEventResult.handled;
          }
        }
      }
    }
  }
  return KeyEventResult.ignored;
};
