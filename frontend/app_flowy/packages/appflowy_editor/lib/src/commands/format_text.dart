import 'dart:async';

import 'package:appflowy_editor/src/commands/text_command_infra.dart';
import 'package:appflowy_editor/src/core/document/attributes.dart';
import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/core/document/path.dart';
import 'package:appflowy_editor/src/core/location/selection.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/core/transform/transaction.dart';
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

  editorState.transaction.updateNode(result, attributes);
  editorState.commit();

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
  editorState.transaction.formatText(
    result,
    newSelection.startIndex,
    newSelection.length,
    attributes,
  );
  editorState.commit();

  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    completer.complete();
  });

  return completer.future;
}
