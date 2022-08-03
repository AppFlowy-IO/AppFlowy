import 'package:flowy_editor/service/keyboard_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// type '/' to trigger shortcut widget
FlowyKeyEventHandler slashShortcutHandler = (editorState, event) {
  if (event.logicalKey != LogicalKeyboardKey.slash) {
    return KeyEventResult.ignored;
  }

  return KeyEventResult.ignored;
};
