import 'dart:async';

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
  final newSelection = _getSelection(editorState, selection: selection);

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

// get formatted [TextNode]
TextNode getTextNodeToBeFormatted(
  EditorState editorState, {
  Path? path,
  TextNode? textNode,
}) {
  assert(!(path != null && textNode != null));
  assert(!(path == null && textNode == null));

  TextNode result;
  if (textNode != null) {
    result = textNode;
  } else if (path != null) {
    result = editorState.document.nodeAtPath(path) as TextNode;
  } else {
    throw Exception('path and textNode cannot be null at the same time');
  }
  return result;
}

Selection _getSelection(
  EditorState editorState, {
  Selection? selection,
}) {
  final currentSelection =
      editorState.service.selectionService.currentSelection.value;
  Selection result;
  if (selection != null) {
    result = selection;
  } else if (currentSelection != null) {
    result = currentSelection;
  } else {
    throw Exception('path and textNode cannot be null at the same time');
  }
  return result;
}
