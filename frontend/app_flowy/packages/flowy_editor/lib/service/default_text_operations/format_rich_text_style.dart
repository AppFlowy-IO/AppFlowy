import 'package:flowy_editor/document/attributes.dart';
import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/editor_state.dart';
import 'package:flowy_editor/extensions/text_node_extensions.dart';
import 'package:flowy_editor/operation/transaction_builder.dart';
import 'package:flowy_editor/render/rich_text/rich_text_style.dart';

void formatHeading(EditorState editorState, String heading) {
  formatTextNodes(editorState, {
    StyleKey.subtype: StyleKey.heading,
    StyleKey.heading: heading,
  });
}

void formatQuote(EditorState editorState) {
  formatTextNodes(editorState, {
    StyleKey.subtype: StyleKey.quote,
  });
}

void formatCheckbox(EditorState editorState) {
  formatTextNodes(editorState, {
    StyleKey.subtype: StyleKey.checkbox,
    StyleKey.checkbox: false,
  });
}

void formatBulletedList(EditorState editorState) {
  formatTextNodes(editorState, {
    StyleKey.subtype: StyleKey.bulletedList,
  });
}

bool formatTextNodes(EditorState editorState, Attributes attributes) {
  final nodes = editorState.service.selectionService.currentSelectedNodes.value;
  final textNodes = nodes.whereType<TextNode>().toList();

  if (textNodes.isEmpty) {
    return false;
  }

  final builder = TransactionBuilder(editorState);

  for (final textNode in textNodes) {
    builder.updateNode(
      textNode,
      Attributes.fromIterable(
        StyleKey.globalStyleKeys,
        value: (_) => null,
      )..addAll(attributes),
    );
  }

  builder.commit();
  return true;
}

bool formatBold(EditorState editorState) {
  return formatRichTextPartialStyle(editorState, StyleKey.bold);
}

bool formatItalic(EditorState editorState) {
  return formatRichTextPartialStyle(editorState, StyleKey.italic);
}

bool formatUnderline(EditorState editorState) {
  return formatRichTextPartialStyle(editorState, StyleKey.underline);
}

bool formatStrikethrough(EditorState editorState) {
  return formatRichTextPartialStyle(editorState, StyleKey.strikethrough);
}

bool formatRichTextPartialStyle(EditorState editorState, String styleKey) {
  final selection = editorState.service.selectionService.currentSelection;
  final nodes = editorState.service.selectionService.currentSelectedNodes.value;
  final textNodes = nodes.whereType<TextNode>().toList(growable: false);

  if (selection == null || textNodes.isEmpty) {
    return false;
  }

  bool value = !textNodes.allSatisfyInSelection(styleKey, selection);
  Attributes attributes = {
    styleKey: value,
  };
  if (styleKey == StyleKey.underline && value) {
    attributes[StyleKey.strikethrough] = null;
  } else if (styleKey == StyleKey.strikethrough && value) {
    attributes[StyleKey.underline] = null;
  }

  return formatRichTextStyle(editorState, attributes);
}

bool formatRichTextStyle(EditorState editorState, Attributes attributes) {
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
  if (nodes.length == textNodes.length && textNodes.length == 1) {
    builder.formatText(
      textNodes.first,
      selection.start.offset,
      selection.end.offset - selection.start.offset,
      attributes,
    );
  } else {
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
  }

  builder.commit();

  return true;
}
