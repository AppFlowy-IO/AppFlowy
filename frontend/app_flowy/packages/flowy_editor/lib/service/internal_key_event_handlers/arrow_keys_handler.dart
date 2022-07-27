import 'package:flowy_editor/service/keyboard_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

FlowyKeyEventHandler arrowKeysHandler = (editorState, event) {
  if (event.logicalKey != LogicalKeyboardKey.arrowUp &&
      event.logicalKey != LogicalKeyboardKey.arrowDown &&
      event.logicalKey != LogicalKeyboardKey.arrowLeft &&
      event.logicalKey != LogicalKeyboardKey.arrowRight) {
    return KeyEventResult.ignored;
  }

  return KeyEventResult.ignored;
};
