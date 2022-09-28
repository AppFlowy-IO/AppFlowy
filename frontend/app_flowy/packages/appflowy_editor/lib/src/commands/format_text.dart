import 'package:appflowy_editor/src/document/attributes.dart';
import 'package:appflowy_editor/src/document/node.dart';
import 'package:appflowy_editor/src/document/path.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/operation/transaction_builder.dart';
import 'package:flutter/widgets.dart';

Future<void> updateTextNodeAttributes(
  EditorState editorState,
  Attributes attributes, {
  Path? path,
  TextNode? textNode,
}) async {
  assert(!(path != null && textNode != null));
  assert(!(path == null && textNode == null));

  TextNode formattedTextNode;
  if (textNode != null) {
    formattedTextNode = textNode;
  } else if (path != null) {
    formattedTextNode = editorState.document.nodeAtPath(path) as TextNode;
  } else {
    throw Exception('path and textNode cannot be null at the same time');
  }

  TransactionBuilder(editorState)
    ..updateNode(formattedTextNode, attributes)
    ..commit();

  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    print('AAAAAAAAAAAAAA');
    return;
  });
}
