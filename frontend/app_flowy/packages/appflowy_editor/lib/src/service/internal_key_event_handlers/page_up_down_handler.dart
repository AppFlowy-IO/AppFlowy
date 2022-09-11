import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appflowy_editor/src/service/shortcut_event/shortcut_event_handler.dart';

ShortcutEventHandler pageUpHandler = (editorState, _) {
  final scrollHeight = editorState.service.scrollService?.onePageHeight;
  final scrollService = editorState.service.scrollService;
  if (scrollHeight != null && scrollService != null) {
    scrollService.scrollTo(scrollService.dy - scrollHeight);
  }
  return KeyEventResult.handled;
};

ShortcutEventHandler pageDownHandler = (editorState, _) {
  final scrollHeight = editorState.service.scrollService?.onePageHeight;
  final scrollService = editorState.service.scrollService;
  if (scrollHeight != null && scrollService != null) {
    scrollService.scrollTo(scrollService.dy + scrollHeight);
  }
  return KeyEventResult.handled;
};
