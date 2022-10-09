import 'dart:async';

import 'package:appflowy_editor/src/commands/text_command_infra.dart';
import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/document/path.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/operation/transaction_builder.dart';
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

  TransactionBuilder(editorState)
    ..insertText(result, index, content)
    ..commit();

  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    completer.complete();
  });

  return completer.future;
}
