import 'package:flowy_editor/flowy_editor.dart';
import 'package:flowy_editor/service/keyboard_service.dart';
import 'package:flowy_editor/infra/html_converter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rich_clipboard/rich_clipboard.dart';

_handleCopy() async {
  debugPrint('copy');
}

_pasteHTML(EditorState editorState, String html) {
  final converter = HTMLConverter(html);
  final nodes = converter.toNodes();
  final selection = editorState.cursorSelection;
  if (selection == null) {
    return;
  }

  final path = [...selection.end.path];
  if (path.isEmpty) {
    return;
  }
  path[path.length - 1]++;

  final tb = TransactionBuilder(editorState);
  tb.insertNodes(path, nodes);
  tb.commit();
}

_handlePaste(EditorState editorState) async {
  final data = await RichClipboard.getData();
  if (data.html != null) {
    _pasteHTML(editorState, data.html!);
    return;
  }
  debugPrint('paste ${data.text ?? ''}');
}

_handleCut() {
  debugPrint('cut');
}

FlowyKeyEventHandler copyPasteKeysHandler = (editorState, event) {
  if (event.isMetaPressed && event.logicalKey == LogicalKeyboardKey.keyC) {
    _handleCopy();
    return KeyEventResult.handled;
  }
  if (event.isMetaPressed && event.logicalKey == LogicalKeyboardKey.keyV) {
    _handlePaste(editorState);
    return KeyEventResult.handled;
  }
  if (event.isMetaPressed && event.logicalKey == LogicalKeyboardKey.keyX) {
    _handleCut();
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};
