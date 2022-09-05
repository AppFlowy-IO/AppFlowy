import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appflowy_editor/src/service/shortcut_event/shortcut_event_handler.dart';

ShortcutEventHandler redoUndoKeysHandler = (editorState, event) {
  if (event.isMetaPressed && event.logicalKey == LogicalKeyboardKey.keyZ) {
    if (event.isShiftPressed) {
      editorState.undoManager.redo();
    } else {
      editorState.undoManager.undo();
    }
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};
