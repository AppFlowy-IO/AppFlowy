import 'package:appflowy_editor/src/service/shortcut_event/shortcut_event_handler.dart';
import 'package:flutter/material.dart';

ShortcutEventHandler exitEditingModeEventHandler = (editorState, event) {
  editorState.service.selectionService.clearSelection();
  return KeyEventResult.handled;
};
