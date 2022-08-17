import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

FlowyKeyEventHandler pageUpDownHandler = (editorState, event) {
  if (event.logicalKey == LogicalKeyboardKey.pageUp) {
    final scrollHeight = editorState.service.scrollService?.onePageHeight;
    final scrollService = editorState.service.scrollService;
    if (scrollHeight != null && scrollService != null) {
      scrollService.scrollTo(scrollService.dy - scrollHeight);
    }
    return KeyEventResult.handled;
  } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
    final scrollHeight = editorState.service.scrollService?.onePageHeight;
    final scrollService = editorState.service.scrollService;
    if (scrollHeight != null && scrollService != null) {
      scrollService.scrollTo(scrollService.dy + scrollHeight);
    }
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};
