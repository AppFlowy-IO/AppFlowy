import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/blocks/base_component/shortcuts/block_shortcut.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/backspace_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

TextBlockShortcutHandler backspaceHandler = (context, _) {
  final editorState = Provider.of<EditorState>(context, listen: false);

  final selection = editorState.service.selectionServiceV2.selection;
  if (selection == null) {
    return KeyEventResult.ignored;
  }
  final tr = editorState.transaction;
  final nodes = editorState.getNodesInSelection(selection);

  if (nodes.length == 1 && selection.startIndex != 0) {
    assert(selection.isSingle);
    if (selection.isCollapsed) {
      tr.deleteTextV2(
        nodes.first,
        selection.startIndex - 1,
        1,
      );
    } else {
      tr.deleteTextV2(
        nodes.first,
        selection.startIndex,
        selection.length,
      );
    }

    editorState.apply(tr);
    return KeyEventResult.handled;
  }

  return backspaceEventHandler(editorState, null);
};
