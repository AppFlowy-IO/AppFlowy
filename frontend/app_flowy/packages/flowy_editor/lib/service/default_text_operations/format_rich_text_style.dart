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
  if (textNodes.length == nodes.length) {
    if (textNodes.length == 1) {
      builder.formatText(
        textNodes.first,
        selection.start.offset,
        selection.end.offset - selection.start.offset,
        attributes,
      );
    } else {
      for (var i = 0; i < textNodes.length; i++) {
        final node = textNodes[i];
        if (i == 0) {
          builder.formatText(
            node,
            selection.start.offset,
            node.toRawString().length - selection.start.offset,
            attributes,
          );
        } else if (i == textNodes.length - 1) {
          builder.formatText(
            node,
            0,
            selection.end.offset,
            attributes,
          );
        } else {
          builder.formatText(
            node,
            0,
            node.toRawString().length,
            attributes,
          );
        }
      }
    }
  } else {
    for (var i = 0; i < textNodes.length; i++) {
      final node = textNodes[i];
      if (i == 0 && node == nodes.first) {
        builder.formatText(
          node,
          selection.start.offset,
          node.toRawString().length - selection.start.offset,
          attributes,
        );
      } else if (i == textNodes.length - 1 && node == nodes.last) {
        builder.formatText(
          node,
          0,
          selection.end.offset,
          attributes,
        );
      } else {
        builder.formatText(
          node,
          0,
          node.toRawString().length,
          attributes,
        );
      }
    }
  }

  builder.commit();

  return true;
}
