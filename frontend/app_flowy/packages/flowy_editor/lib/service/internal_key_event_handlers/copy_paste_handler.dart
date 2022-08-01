import 'package:flowy_editor/service/keyboard_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

FlowyKeyEventHandler copyPasteKeysHandler = (editorState, event) {
  if (event.isMetaPressed && event.logicalKey == LogicalKeyboardKey.keyC) {
    debugPrint("copy");
    return KeyEventResult.handled;
  }
  if (event.isMetaPressed && event.logicalKey == LogicalKeyboardKey.keyV) {
    debugPrint("paste");
    return KeyEventResult.handled;
  }
  if (event.isMetaPressed && event.logicalKey == LogicalKeyboardKey.keyX) {
    debugPrint("cut");
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};
