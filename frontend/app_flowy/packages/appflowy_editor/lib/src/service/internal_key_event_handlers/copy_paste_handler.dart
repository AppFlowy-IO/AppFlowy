import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/infra/html_converter.dart';
import 'package:appflowy_editor/src/document/node_iterator.dart';
import 'package:appflowy_editor/src/document/built_in_attribute_keys.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/number_list_helper.dart';
import 'package:flutter/material.dart';
import 'package:rich_clipboard/rich_clipboard.dart';

int _textLengthOfNode(Node node) {
  if (node is TextNode) {
    return node.delta.length;
  }

  return 0;
}

Selection _computeSelectionAfterPasteMultipleNodes(
    EditorState editorState, List<Node> nodes) {
  final currentSelection = editorState.cursorSelection!;
  final currentCursor = currentSelection.start;
  final currentPath = [...currentCursor.path];
  currentPath[currentPath.length - 1] += nodes.length;
  int lenOfLastNode = _textLengthOfNode(nodes.last);
  return Selection.collapsed(
      Position(path: currentPath, offset: lenOfLastNode));
}

void _handleCopy(EditorState editorState) async {
  final selection = editorState.cursorSelection?.normalize;
  if (selection == null || selection.isCollapsed) {
    return;
  }
  if (pathEquals(selection.start.path, selection.end.path)) {
    final nodeAtPath = editorState.document.nodeAtPath(selection.end.path)!;
    if (nodeAtPath.type == "text") {
      final textNode = nodeAtPath as TextNode;
      final htmlString = NodesToHTMLConverter(
              nodes: [textNode],
              startOffset: selection.start.offset,
              endOffset: selection.end.offset)
          .toHTMLString();
      Log.keyboard.debug('copy html: $htmlString');
      RichClipboard.setData(RichClipboardData(html: htmlString));
    } else {
      Log.keyboard.debug('unimplemented: copy non-text');
    }
    return;
  }

  final beginNode = editorState.document.nodeAtPath(selection.start.path)!;
  final endNode = editorState.document.nodeAtPath(selection.end.path)!;

  final nodes = NodeIterator(editorState.document, beginNode, endNode).toList();

  final copyString = NodesToHTMLConverter(
          nodes: nodes,
          startOffset: selection.start.offset,
          endOffset: selection.end.offset)
      .toHTMLString();
  Log.keyboard.debug('copy html: $copyString');
  RichClipboard.setData(RichClipboardData(html: copyString));
}

void _pasteHTML(EditorState editorState, String html) {
  final selection = editorState.cursorSelection?.normalize;
  if (selection == null) {
    return;
  }

  assert(selection.isCollapsed);

  final path = [...selection.end.path];
  if (path.isEmpty) {
    return;
  }

  Log.keyboard.debug('paste html: $html');
  final nodes = HTMLToNodesConverter(html).toNodes();

  if (nodes.isEmpty) {
    return;
  } else if (nodes.length == 1) {
    final firstNode = nodes[0];
    final nodeAtPath = editorState.document.nodeAtPath(path)!;
    final tb = TransactionBuilder(editorState);
    final startOffset = selection.start.offset;
    if (nodeAtPath.type == "text" && firstNode.type == "text") {
      final textNodeAtPath = nodeAtPath as TextNode;
      final firstTextNode = firstNode as TextNode;
      tb.textEdit(textNodeAtPath,
          () => (Delta()..retain(startOffset)) + firstTextNode.delta);
      tb.setAfterSelection(Selection.collapsed(Position(
          path: path, offset: startOffset + firstTextNode.delta.length)));
      tb.commit();
      return;
    }
  }

  _pasteMultipleLinesInText(editorState, path, selection.start.offset, nodes);
}

void _pasteMultipleLinesInText(
    EditorState editorState, List<int> path, int offset, List<Node> nodes) {
  final tb = TransactionBuilder(editorState);

  final firstNode = nodes[0];
  final nodeAtPath = editorState.document.nodeAtPath(path)!;

  if (nodeAtPath.type == "text" && firstNode.type == "text") {
    int? startNumber;
    if (nodeAtPath.subtype == BuiltInAttributeKey.numberList) {
      startNumber = nodeAtPath.attributes[BuiltInAttributeKey.number] as int;
    }

    // split and merge
    final textNodeAtPath = nodeAtPath as TextNode;
    final firstTextNode = firstNode as TextNode;
    final remain = textNodeAtPath.delta.slice(offset);

    tb.textEdit(
        textNodeAtPath,
        () =>
            (Delta()
              ..retain(offset)
              ..delete(remain.length)) +
            firstTextNode.delta);

    final tailNodes = nodes.sublist(1);
    final originalPath = [...path];
    path[path.length - 1]++;

    final afterSelection =
        _computeSelectionAfterPasteMultipleNodes(editorState, tailNodes);

    if (tailNodes.isNotEmpty) {
      if (tailNodes.last.type == "text") {
        final tailTextNode = tailNodes.last as TextNode;
        tailTextNode.delta = tailTextNode.delta + remain;
      } else if (remain.isNotEmpty) {
        tailNodes.add(TextNode(type: "text", delta: remain));
      }
    } else {
      tailNodes.add(TextNode(type: "text", delta: remain));
    }

    tb.setAfterSelection(afterSelection);
    tb.insertNodes(path, tailNodes);
    tb.commit();

    if (startNumber != null) {
      makeFollowingNodesIncremental(editorState, originalPath, afterSelection,
          beginNum: startNumber);
    }
    return;
  }

  final afterSelection =
      _computeSelectionAfterPasteMultipleNodes(editorState, nodes);

  path[path.length - 1]++;
  tb.setAfterSelection(afterSelection);
  tb.insertNodes(path, nodes);
  tb.commit();
}

void _handlePaste(EditorState editorState) async {
  final data = await RichClipboard.getData();

  if (editorState.cursorSelection?.isCollapsed ?? false) {
    _pastRichClipboard(editorState, data);
    return;
  }

  _deleteSelectedContent(editorState);

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _pastRichClipboard(editorState, data);
  });
}

void _pastRichClipboard(EditorState editorState, RichClipboardData data) {
  if (data.html != null) {
    _pasteHTML(editorState, data.html!);
    return;
  }
  if (data.text != null) {
    _handlePastePlainText(editorState, data.text!);
    return;
  }
}

void _pasteSingleLine(
    EditorState editorState, Selection selection, String line) {
  final node = editorState.document.nodeAtPath(selection.end.path)! as TextNode;
  final beginOffset = selection.end.offset;
  TransactionBuilder(editorState)
    ..textEdit(
        node,
        () => Delta()
          ..retain(beginOffset)
          ..addAll(_lineContentToDelta(line)))
    ..setAfterSelection(Selection.collapsed(
        Position(path: selection.end.path, offset: beginOffset + line.length)))
    ..commit();
}

/// parse url from the line text
/// reference: https://stackoverflow.com/questions/59444837/flutter-dart-regex-to-extract-urls-from-a-string
Delta _lineContentToDelta(String lineContent) {
  final exp = RegExp(r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+');
  final Iterable<RegExpMatch> matches = exp.allMatches(lineContent);

  final delta = Delta();

  var lastUrlEndOffset = 0;

  for (final match in matches) {
    if (lastUrlEndOffset < match.start) {
      delta.insert(lineContent.substring(lastUrlEndOffset, match.start));
    }
    final linkContent = lineContent.substring(match.start, match.end);
    delta.insert(linkContent, {"href": linkContent});
    lastUrlEndOffset = match.end;
  }

  if (lastUrlEndOffset < lineContent.length) {
    delta.insert(lineContent.substring(lastUrlEndOffset, lineContent.length));
  }

  return delta;
}

void _handlePastePlainText(EditorState editorState, String plainText) {
  final selection = editorState.cursorSelection?.normalize;
  if (selection == null) {
    return;
  }

  final lines = plainText
      .split("\n")
      .map((e) => e.replaceAll(RegExp(r'\r'), ""))
      .toList();

  if (lines.isEmpty) {
    return;
  } else if (lines.length == 1) {
    // single line
    _pasteSingleLine(editorState, selection, lines.first);
  } else {
    final firstLine = lines[0];
    final beginOffset = selection.end.offset;
    final remains = lines.sublist(1);

    final path = [...selection.end.path];
    if (path.isEmpty) {
      return;
    }

    final node =
        editorState.document.nodeAtPath(selection.end.path)! as TextNode;
    final insertedLineSuffix = node.delta.slice(beginOffset);

    path[path.length - 1]++;
    final tb = TransactionBuilder(editorState);
    final List<TextNode> nodes = remains
        .map((e) => TextNode(type: "text", delta: _lineContentToDelta(e)))
        .toList();

    final afterSelection =
        _computeSelectionAfterPasteMultipleNodes(editorState, nodes);

    // append remain text to the last line
    if (nodes.isNotEmpty) {
      final last = nodes.last;
      nodes[nodes.length - 1] =
          TextNode(type: "text", delta: last.delta..addAll(insertedLineSuffix));
    }

    // insert first line
    tb.textEdit(
        node,
        () => Delta()
          ..retain(beginOffset)
          ..insert(firstLine)
          ..delete(node.delta.length - beginOffset));
    // insert remains
    tb.insertNodes(path, nodes);
    tb.setAfterSelection(afterSelection);
    tb.commit();
  }
}

/// 1. copy the selected content
/// 2. delete selected content
void _handleCut(EditorState editorState) {
  _handleCopy(editorState);
  _deleteSelectedContent(editorState);
}

void _deleteSelectedContent(EditorState editorState) {
  final selection = editorState.cursorSelection?.normalize;
  if (selection == null || selection.isCollapsed) {
    return;
  }
  final beginNode = editorState.document.nodeAtPath(selection.start.path)!;
  final endNode = editorState.document.nodeAtPath(selection.end.path)!;
  if (pathEquals(selection.start.path, selection.end.path) &&
      beginNode.type == "text") {
    final textItem = beginNode as TextNode;
    final tb = TransactionBuilder(editorState);
    final len = selection.end.offset - selection.start.offset;
    tb.textEdit(
        textItem,
        () => Delta()
          ..retain(selection.start.offset)
          ..delete(len));
    tb.setAfterSelection(Selection.collapsed(selection.start));
    tb.commit();
    return;
  }
  final traverser = NodeIterator(editorState.document, beginNode, endNode);

  final tb = TransactionBuilder(editorState);
  while (traverser.moveNext()) {
    final item = traverser.current;
    if (item.type == "text" && beginNode == item) {
      final textItem = item as TextNode;
      final deleteLen = textItem.delta.length - selection.start.offset;
      tb.textEdit(textItem, () {
        final delta = Delta()
          ..retain(selection.start.offset)
          ..delete(deleteLen);

        if (endNode is TextNode) {
          final remain = endNode.delta.slice(selection.end.offset);
          delta.addAll(remain);
        }

        return delta;
      });
    } else {
      tb.deleteNode(item);
    }
  }
  tb.setAfterSelection(Selection.collapsed(selection.start));
  tb.commit();
}

ShortcutEventHandler copyEventHandler = (editorState, event) {
  _handleCopy(editorState);
  return KeyEventResult.handled;
};

ShortcutEventHandler pasteEventHandler = (editorState, event) {
  _handlePaste(editorState);
  return KeyEventResult.handled;
};

ShortcutEventHandler cutEventHandler = (editorState, event) {
  _handleCut(editorState);
  return KeyEventResult.handled;
};
