import 'package:flowy_editor/service/flowy_key_event_handlers/arrow_keys_handler.dart';
import 'package:flowy_editor/service/flowy_key_event_handlers/delete_nodes_handler.dart';
import 'package:flowy_editor/service/flowy_key_event_handlers/delete_single_text_node_handler.dart';
import 'package:flowy_editor/service/keyboard_service.dart';
import 'package:flowy_editor/service/selection_service.dart';

import '../editor_state.dart';
import 'package:flutter/material.dart';

class FlowyEditor extends StatefulWidget {
  const FlowyEditor({
    Key? key,
    required this.editorState,
    required this.keyEventHandler,
  }) : super(key: key);

  final EditorState editorState;
  final List<FlowyKeyEventHandler> keyEventHandler;

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
      child: FlowyKeyboard(
        key: editorState.service.keyboardServiceKey,
        handlers: [
          flowyDeleteNodesHandler,
          deleteSingleTextNodeHandler,
          arrowKeysHandler,
          ...widget.keyEventHandler,
        ],
        editorState: editorState,
        child: editorState.build(context),
      ),
    );
  }
}
