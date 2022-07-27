import 'package:flowy_editor/render/selection/floating_shortcut_widget.dart';
import 'package:flowy_editor/service/input_service.dart';
import 'package:flowy_editor/service/internal_key_event_handlers/enter_in_edge_of_text_node_handler.dart';
import 'package:flowy_editor/service/shortcut_service.dart';
import 'package:flowy_editor/service/internal_key_event_handlers/arrow_keys_handler.dart';
import 'package:flowy_editor/service/internal_key_event_handlers/delete_nodes_handler.dart';
import 'package:flowy_editor/service/internal_key_event_handlers/delete_single_text_node_handler.dart';
import 'package:flowy_editor/service/internal_key_event_handlers/shortcut_handler.dart';
import 'package:flowy_editor/service/keyboard_service.dart';
import 'package:flowy_editor/service/selection_service.dart';
import 'package:flowy_editor/editor_state.dart';

import 'package:flutter/material.dart';

class FlowyEditor extends StatefulWidget {
  const FlowyEditor({
    Key? key,
    required this.editorState,
    required this.keyEventHandlers,
    required this.shortcuts,
  }) : super(key: key);

  final EditorState editorState;
  final List<FlowyKeyEventHandler> keyEventHandlers;

  /// Shortcusts
  final FloatingShortcuts shortcuts;

  @override
  State<FlowyEditor> createState() => _FlowyEditorState();
}

class _FlowyEditorState extends State<FlowyEditor> {
  EditorState get editorState => widget.editorState;

  @override
  Widget build(BuildContext context) {
    return FlowySelection(
      key: editorState.service.selectionServiceKey,
      editorState: editorState,
      child: FlowyInput(
        key: editorState.service.inputServiceKey,
        editorState: editorState,
        child: FlowyKeyboard(
          key: editorState.service.keyboardServiceKey,
          handlers: [
            slashShortcutHandler,
            flowyDeleteNodesHandler,
            deleteSingleTextNodeHandler,
            arrowKeysHandler,
            enterInEdgeOfTextNodeHandler,
            ...widget.keyEventHandlers,
          ],
          editorState: editorState,
          child: FloatingShortcut(
            key: editorState.service.floatingShortcutServiceKey,
            size: const Size(200, 150), // TODO: support customize size.
            editorState: editorState,
            floatingShortcuts: widget.shortcuts,
            child: editorState.build(context),
          ),
        ),
      ),
    );
  }
}
