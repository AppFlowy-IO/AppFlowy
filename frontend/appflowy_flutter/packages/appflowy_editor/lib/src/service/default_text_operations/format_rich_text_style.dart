import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/extensions/text_node_extensions.dart';

void insertHeadingAfterSelection(EditorState editorState, String heading) {
  insertTextNodeAfterSelection(editorState, {
    BuiltInAttributeKey.subtype: BuiltInAttributeKey.heading,
    BuiltInAttributeKey.heading: heading,
  });
}

void insertQuoteAfterSelection(EditorState editorState) {
  insertTextNodeAfterSelection(editorState, {
    BuiltInAttributeKey.subtype: BuiltInAttributeKey.quote,
  });
}

void insertCheckboxAfterSelection(EditorState editorState) {
  insertTextNodeAfterSelection(editorState, {
    BuiltInAttributeKey.subtype: BuiltInAttributeKey.checkbox,
    BuiltInAttributeKey.checkbox: false,
  });
}

void insertBulletedListAfterSelection(EditorState editorState) {
  insertTextNodeAfterSelection(editorState, {
    BuiltInAttributeKey.subtype: BuiltInAttributeKey.bulletedList,
  });
}

void insertNumberedListAfterSelection(EditorState editorState) {
  insertTextNodeAfterSelection(editorState, {
    BuiltInAttributeKey.subtype: BuiltInAttributeKey.numberList,
    BuiltInAttributeKey.number: 1,
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
  if (node is TextNode && node.delta.isEmpty) {
    formatTextNodes(editorState, attributes);
  } else {
    final next = selection.end.path.next;
    final transaction = editorState.transaction
      ..insertNode(
        next,
        TextNode.empty(attributes: attributes),
      )
      ..afterSelection = Selection.collapsed(
        Position(path: next, offset: 0),
      );
    editorState.apply(transaction);
  }

  return true;
}

void formatText(EditorState editorState) {
  formatTextNodes(editorState, {});
}

void formatHeading(EditorState editorState, String heading) {
  formatTextNodes(editorState, {
    BuiltInAttributeKey.subtype: BuiltInAttributeKey.heading,
    BuiltInAttributeKey.heading: heading,
  });
}

void formatQuote(EditorState editorState) {
  formatTextNodes(editorState, {
    BuiltInAttributeKey.subtype: BuiltInAttributeKey.quote,
  });
}

void formatCheckbox(EditorState editorState, bool check) {
  formatTextNodes(editorState, {
    BuiltInAttributeKey.subtype: BuiltInAttributeKey.checkbox,
    BuiltInAttributeKey.checkbox: check,
  });
}

void formatBulletedList(EditorState editorState) {
  formatTextNodes(editorState, {
    BuiltInAttributeKey.subtype: BuiltInAttributeKey.bulletedList,
  });
}

/// Format the current selection with the given attributes.
///
/// If the selected nodes are not text nodes, this method will do nothing.
/// If the selected text nodes already contain the style in attributes, this method will remove the existing style.
bool formatTextNodes(EditorState editorState, Attributes attributes) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final textNodes = nodes.whereType<TextNode>().toList();

  if (textNodes.isEmpty) {
    return false;
  }

  final transaction = editorState.transaction;

  for (final textNode in textNodes) {
    var newAttributes = {...textNode.attributes};
    for (final globalStyleKey in BuiltInAttributeKey.globalStyleKeys) {
      if (newAttributes.keys.contains(globalStyleKey)) {
        newAttributes[globalStyleKey] = null;
      }
    }

    // if an attribute already exists in the node, it should be removed instead
    for (final entry in attributes.entries) {
      if (textNode.attributes.containsKey(entry.key) &&
          textNode.attributes[entry.key] == entry.value) {
        // attribute is not added to the node new attributes
      } else {
        newAttributes.addEntries([entry]);
      }
    }
    transaction
      ..updateNode(
        textNode,
        newAttributes,
      )
      ..afterSelection = Selection.collapsed(
        Position(
          path: textNode.path,
          offset: textNode.toPlainText().length,
        ),
      );
  }

  editorState.apply(transaction);
  return true;
}

bool formatBold(EditorState editorState) {
  return formatRichTextPartialStyle(editorState, BuiltInAttributeKey.bold);
}

bool formatItalic(EditorState editorState) {
  return formatRichTextPartialStyle(editorState, BuiltInAttributeKey.italic);
}

bool formatUnderline(EditorState editorState) {
  return formatRichTextPartialStyle(editorState, BuiltInAttributeKey.underline);
}

bool formatStrikethrough(EditorState editorState) {
  return formatRichTextPartialStyle(
      editorState, BuiltInAttributeKey.strikethrough);
}

bool formatEmbedCode(EditorState editorState) {
  return formatRichTextPartialStyle(editorState, BuiltInAttributeKey.code);
}

bool formatHighlight(EditorState editorState, String colorHex) {
  bool value = _allSatisfyInSelection(
    editorState,
    BuiltInAttributeKey.backgroundColor,
    colorHex,
  );
  return formatRichTextPartialStyle(
    editorState,
    BuiltInAttributeKey.backgroundColor,
    customValue: value ? '0x00000000' : colorHex,
  );
}

bool formatHighlightColor(EditorState editorState, String colorHex) {
  return formatRichTextPartialStyle(
    editorState,
    BuiltInAttributeKey.backgroundColor,
    customValue: colorHex,
  );
}

bool formatFontColor(EditorState editorState, String colorHex) {
  return formatRichTextPartialStyle(
    editorState,
    BuiltInAttributeKey.color,
    customValue: colorHex,
  );
}

bool formatRichTextPartialStyle(EditorState editorState, String styleKey,
    {Object? customValue}) {
  Attributes attributes = {
    styleKey: customValue ??
        !_allSatisfyInSelection(
          editorState,
          styleKey,
          customValue ?? true,
        ),
  };

  return formatRichTextStyle(editorState, attributes);
}

bool _allSatisfyInSelection(
  EditorState editorState,
  String styleKey,
  dynamic matchValue,
) {
  final selection = editorState.service.selectionService.currentSelection.value;
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final textNodes = nodes.whereType<TextNode>().toList(growable: false);

  if (selection == null || textNodes.isEmpty) {
    return false;
  }

  return textNodes.allSatisfyInSelection(selection, styleKey, (value) {
    return value == matchValue;
  });
}

bool formatRichTextStyle(EditorState editorState, Attributes attributes) {
  var selection = editorState.service.selectionService.currentSelection.value;
  var nodes = editorState.service.selectionService.currentSelectedNodes;

  if (selection == null) {
    return false;
  }

  nodes = selection.isBackward ? nodes : nodes.reversed.toList(growable: false);
  selection = selection.isBackward ? selection : selection.reversed;

  var textNodes = nodes.whereType<TextNode>().toList();
  if (textNodes.isEmpty) {
    return false;
  }

  final transaction = editorState.transaction;

  // 1. All nodes are text nodes.
  // 2. The first node is not TextNode.
  // 3. The last node is not TextNode.
  if (nodes.length == textNodes.length && textNodes.length == 1) {
    transaction.formatText(
      textNodes.first,
      selection.start.offset,
      selection.end.offset - selection.start.offset,
      attributes,
    );
  } else {
    for (var i = 0; i < textNodes.length; i++) {
      final textNode = textNodes[i];
      var index = 0;
      var length = textNode.toPlainText().length;
      if (i == 0 && textNode == nodes.first) {
        index = selection.start.offset;
        length = textNode.toPlainText().length - selection.start.offset;
      } else if (i == textNodes.length - 1 && textNode == nodes.last) {
        length = selection.end.offset;
      }
      transaction.formatText(
        textNode,
        index,
        length,
        attributes,
      );
    }
  }

  editorState.apply(transaction);

  return true;
}
