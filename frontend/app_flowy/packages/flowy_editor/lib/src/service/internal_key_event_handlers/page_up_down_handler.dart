import 'package:flowy_editor/flowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

double? getEditorHeight(EditorState editorState) {
  final renderObj =
      editorState.service.scrollServiceKey.currentContext?.findRenderObject();
  if (renderObj is RenderBox) {
    return renderObj.size.height;
  }
  return null;
}

FlowyKeyEventHandler pageUpDownHandler = (editorState, event) {
  if (event.logicalKey == LogicalKeyboardKey.pageUp) {
    final scrollHeight = getEditorHeight(editorState);
    final scrollService = editorState.service.scrollService;
    if (scrollHeight != null && scrollService != null) {
      scrollService.scrollTo(scrollService.dy - scrollHeight);
    }
    return KeyEventResult.handled;
  } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
    final scrollHeight = getEditorHeight(editorState);
    final scrollService = editorState.service.scrollService;
    if (scrollHeight != null && scrollService != null) {
      scrollService.scrollTo(scrollService.dy + scrollHeight);
    }
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};
