import 'package:flowy_editor/src/service/keyboard_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

FlowyKeyEventHandler redoUndoKeysHandler = (editorState, event) {
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
