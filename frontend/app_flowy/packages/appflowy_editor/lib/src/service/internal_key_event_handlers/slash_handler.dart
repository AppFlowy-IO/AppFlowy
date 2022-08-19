import 'package:appflowy_editor/src/document/node.dart';
import 'package:appflowy_editor/src/operation/transaction_builder.dart';
import 'package:appflowy_editor/src/render/selection_menu/selection_menu_service.dart';
import 'package:appflowy_editor/src/service/keyboard_service.dart';
import 'package:appflowy_editor/src/extensions/node_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

SelectionMenuService? _selectionMenuService;
AppFlowyKeyEventHandler slashShortcutHandler = (editorState, event) {
  if (event.logicalKey != LogicalKeyboardKey.slash) {
    return KeyEventResult.ignored;
  }

  final textNodes = editorState.service.selectionService.currentSelectedNodes
      .whereType<TextNode>();
  if (textNodes.length != 1) {
    return KeyEventResult.ignored;
  }

  final selection = editorState.service.selectionService.currentSelection.value;
  final textNode = textNodes.first;
  final context = textNode.context;
  final selectable = textNode.selectable;
  if (selection == null || context == null || selectable == null) {
    return KeyEventResult.ignored;
  }
  final selectionRects = editorState.service.selectionService.selectionRects;
  if (selectionRects.isEmpty) {
    return KeyEventResult.ignored;
  }
  TransactionBuilder(editorState)
    ..replaceText(textNode, selection.start.offset,
        selection.end.offset - selection.start.offset, event.character ?? '')
    ..commit();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _selectionMenuService =
        SelectionMenu(context: context, editorState: editorState);
    _selectionMenuService?.show();
  });

  return KeyEventResult.handled;
};
