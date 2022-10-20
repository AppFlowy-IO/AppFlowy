import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/core/transform/transaction.dart';
import 'package:appflowy_editor/src/render/selection_menu/selection_menu_service.dart';
import 'package:appflowy_editor/src/extensions/node_extensions.dart';
import 'package:appflowy_editor/src/service/shortcut_event/shortcut_event_handler.dart';
import 'package:flutter/material.dart';

SelectionMenuService? _selectionMenuService;
ShortcutEventHandler slashShortcutHandler = (editorState, event) {
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
  final transaction = editorState.transaction
    ..replaceText(
      textNode,
      selection.start.offset,
      selection.end.offset - selection.start.offset,
      '/',
    );
  editorState.apply(transaction);

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _selectionMenuService =
        SelectionMenu(context: context, editorState: editorState);
    _selectionMenuService?.show();
  });

  return KeyEventResult.handled;
};
