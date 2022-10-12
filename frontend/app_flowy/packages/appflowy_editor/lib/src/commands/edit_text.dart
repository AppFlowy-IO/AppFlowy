import 'dart:async';

import 'package:appflowy_editor/src/commands/text_command_infra.dart';
import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/core/document/path.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/core/transform/transaction.dart';
import 'package:flutter/widgets.dart';

Future<void> insertContextInText(
  EditorState editorState,
  int index,
  String content, {
  Path? path,
  TextNode? textNode,
}) async {
  final result = getTextNodeToBeFormatted(
    editorState,
    path: path,
    textNode: textNode,
  );

  final completer = Completer<void>();

  editorState.transaction.insertText(result, index, content);
  editorState.commit();

  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    completer.complete();
  });

  return completer.future;
}
