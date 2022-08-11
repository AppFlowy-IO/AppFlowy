import 'package:flowy_editor/src/document/attributes.dart';
import 'package:flowy_editor/src/document/node.dart';
import 'package:flowy_editor/src/document/position.dart';
import 'package:flowy_editor/src/document/selection.dart';
import 'package:flowy_editor/src/editor_state.dart';
import 'package:flowy_editor/src/extensions/text_node_extensions.dart';
import 'package:flowy_editor/src/extensions/path_extensions.dart';
import 'package:flowy_editor/src/operation/transaction_builder.dart';
import 'package:flowy_editor/src/render/rich_text/rich_text_style.dart';

void insertHeadingAfterSelection(EditorState editorState, String heading) {
  insertTextNodeAfterSelection(editorState, {
    StyleKey.subtype: StyleKey.heading,
    StyleKey.heading: heading,
  });
}

void insertQuoteAfterSelection(EditorState editorState) {
  insertTextNodeAfterSelection(editorState, {
    StyleKey.subtype: StyleKey.quote,
  });
}

void insertCheckboxAfterSelection(EditorState editorState) {
  insertTextNodeAfterSelection(editorState, {
    StyleKey.subtype: StyleKey.checkbox,
    StyleKey.checkbox: false,
  });
}

void insertBulletedListAfterSelection(EditorState editorState) {
  insertTextNodeAfterSelection(editorState, {
    StyleKey.subtype: StyleKey.bulletedList,
  });
}

bool insertTextNodeAfterSelection(
    EditorState editorState, Attributes attributes) {
  final selection = editorState.service.selectionService.currentSelection.value;
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  if (selection == null || nodes.isEmpty) {
    return false;
  }

  final node = nodes.first;
  if (node is TextNode && node.delta.length == 0) {
    formatTextNodes(editorState, attributes);
  } else {
    final next = selection.end.path.next;
    final builder = TransactionBuilder(editorState);
    builder
      ..insertNode(
        next,
        TextNode.empty(attributes: attributes),
      )
      ..afterSelection = Selection.collapsed(
        Position(path: next, offset: 0),
      )
      ..commit();
  }

  return true;
}

void formatText(EditorState editorState) {
  formatTextNodes(editorState, {});
}

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
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final textNodes = nodes.whereType<TextNode>().toList();

  if (textNodes.isEmpty) {
    return false;
  }

  final builder = TransactionBuilder(editorState);

  for (final textNode in textNodes) {
    builder
      ..updateNode(
        textNode,
        Attributes.fromIterable(
          StyleKey.globalStyleKeys,
          value: (_) => null,
        )..addAll(attributes),
      )
      ..afterSelection = Selection.collapsed(
        Position(
          path: textNode.path,
          offset: textNode.toRawString().length,
        ),
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
  final selection = editorState.service.selectionService.currentSelection.value;
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final textNodes = nodes.whereType<TextNode>().toList(growable: false);

  if (selection == null || textNodes.isEmpty) {
    return false;
  }

  bool value = !textNodes.allSatisfyInSelection(styleKey, selection);
  Attributes attributes = {
    styleKey: value,
  };

  return formatRichTextStyle(editorState, attributes);
}

bool formatRichTextStyle(EditorState editorState, Attributes attributes) {
  final selection = editorState.service.selectionService.currentSelection.value;
  final nodes = editorState.service.selectionService.currentSelectedNodes;
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
