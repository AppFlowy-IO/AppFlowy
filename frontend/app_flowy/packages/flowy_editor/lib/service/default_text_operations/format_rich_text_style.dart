import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/editor_state.dart';
import 'package:flowy_editor/operation/transaction_builder.dart';

bool formatRichTextStyle(
    EditorState editorState, Map<String, dynamic> attributes) {
  final selection = editorState.service.selectionService.currentSelection;
  final nodes = editorState.service.selectionService.currentSelectedNodes.value;
  final textNodes = nodes.whereType<TextNode>().toList();

  if (selection == null || textNodes.isEmpty) {
    return false;
  }

  final builder = TransactionBuilder(editorState);

  // 1. All nodes are text nodes.
  // 2. The first node is not TextNode.
  // 3. The last node is not TextNode.
  for (var i = 0; i < textNodes.length; i++) {
    final textNode = textNodes[i];
    if (i == 0 && textNode == nodes.first) {
      builder.formatText(
        textNode,
        selection.start.offset,
        textNode.toRawString().length - selection.start.offset,
        attributes,
      );
    } else if (i == textNodes.length - 1 && textNode == nodes.last) {
      builder.formatText(
        textNode,
        0,
        selection.end.offset,
        attributes,
      );
    } else {
      builder.formatText(
        textNode,
        0,
        textNode.toRawString().length,
        attributes,
      );
    }
  }

  builder.commit();

  return true;
}
