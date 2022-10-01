import 'dart:async';

import 'package:appflowy_editor/src/commands/text_command_infra.dart';
import 'package:appflowy_editor/src/document/attributes.dart';
import 'package:appflowy_editor/src/document/node.dart';
import 'package:appflowy_editor/src/document/path.dart';
import 'package:appflowy_editor/src/document/selection.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/operation/transaction_builder.dart';
import 'package:flutter/widgets.dart';

Future<void> updateTextNodeAttributes(
  EditorState editorState,
  Attributes attributes, {
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
    ..updateNode(result, attributes)
    ..commit();

  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    completer.complete();
  });

  return completer.future;
}

Future<void> updateTextNodeDeltaAttributes(
  EditorState editorState,
  Selection? selection,
  Attributes attributes, {
  Path? path,
  TextNode? textNode,
}) {
  final result = getTextNodeToBeFormatted(
    editorState,
    path: path,
    textNode: textNode,
  );
  final newSelection = getSelection(editorState, selection: selection);

  final completer = Completer<void>();

  TransactionBuilder(editorState)
    ..formatText(
      result,
      newSelection.startIndex,
      newSelection.length,
      attributes,
    )
    ..commit();

  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    completer.complete();
  });

  return completer.future;
}
