import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/infra/clipboard.dart';
import 'package:appflowy_editor/src/infra/html_converter.dart';
import 'package:appflowy_editor/src/core/document/node_iterator.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/number_list_helper.dart';
import 'package:flutter/material.dart';

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
  final selection = editorState.cursorSelection?.normalized;
  if (selection == null || selection.isCollapsed) {
    return;
  }
  if (selection.start.path.equals(selection.end.path)) {
    final nodeAtPath = editorState.document.nodeAtPath(selection.end.path)!;
    if (nodeAtPath.type == "text") {
      final textNode = nodeAtPath as TextNode;
      final htmlString = NodesToHTMLConverter(
              nodes: [textNode],
              startOffset: selection.start.offset,
              endOffset: selection.end.offset)
          .toHTMLString();
      final textString = textNode.toPlainText().substring(
            selection.startIndex,
            selection.endIndex,
          );
      Log.keyboard.debug('copy html: $htmlString');
      AppFlowyClipboard.setData(
        text: textString,
        html: htmlString,
      );
    } else {
      Log.keyboard.debug('unimplemented: copy non-text');
    }
    return;
  }

  final beginNode = editorState.document.nodeAtPath(selection.start.path)!;
  final endNode = editorState.document.nodeAtPath(selection.end.path)!;

  final nodes = NodeIterator(
    document: editorState.document,
    startNode: beginNode,
    endNode: endNode,
  ).toList();

  final html = NodesToHTMLConverter(
    nodes: nodes,
    startOffset: selection.start.offset,
    endOffset: selection.end.offset,
  ).toHTMLString();
  var text = '';
  for (final node in nodes) {
    if (node is TextNode) {
      if (node.path == selection.start.path) {
        text += node.toPlainText().substring(selection.start.offset);
      } else if (node.path == selection.end.path) {
        text += node.toPlainText().substring(0, selection.end.offset);
      } else {
        text += node.toPlainText();
      }
    }
    text += '\n';
  }
  AppFlowyClipboard.setData(
    text: text,
    html: html,
  );
}

void _pasteHTML(EditorState editorState, String html) {
  final selection = editorState.cursorSelection?.normalized;
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
    final tb = editorState.transaction;
    final startOffset = selection.start.offset;
    if (nodeAtPath.type == "text" && firstNode.type == "text") {
      final textNodeAtPath = nodeAtPath as TextNode;
      final firstTextNode = firstNode as TextNode;
      tb.updateText(
          textNodeAtPath, (Delta()..retain(startOffset)) + firstTextNode.delta);
      tb.updateNode(textNodeAtPath, firstTextNode.attributes);
      tb.afterSelection = (Selection.collapsed(Position(
          path: path, offset: startOffset + firstTextNode.delta.length)));
      editorState.apply(tb);
      return;
    }
  }

  _pasteMultipleLinesInText(editorState, path, selection.start.offset, nodes);
}

void _pasteMultipleLinesInText(
    EditorState editorState, List<int> path, int offset, List<Node> nodes) {
  final tb = editorState.transaction;

  final firstNode = nodes[0];
  final nodeAtPath = editorState.document.nodeAtPath(path)!;

  if (nodeAtPath.type == 'text' && firstNode.type == 'text') {
    int? startNumber;
    if (nodeAtPath.subtype == BuiltInAttributeKey.numberList) {
      startNumber = nodeAtPath.attributes[BuiltInAttributeKey.number] as int;
    }

    // split and merge
    final textNodeAtPath = nodeAtPath as TextNode;
    final firstTextNode = firstNode as TextNode;
    final remain = textNodeAtPath.delta.slice(offset);

    tb.updateText(
        textNodeAtPath,
        (Delta()
              ..retain(offset)
              ..delete(remain.length)) +
            firstTextNode.delta);
    tb.updateNode(textNodeAtPath, firstTextNode.attributes);

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
        tailNodes.add(TextNode(delta: remain));
      }
    } else {
      tailNodes.add(TextNode(delta: remain));
    }

    tb.afterSelection = afterSelection;
    tb.insertNodes(path, tailNodes);
    editorState.apply(tb);

    if (startNumber != null) {
      makeFollowingNodesIncremental(editorState, originalPath, afterSelection,
          beginNum: startNumber);
    }
    return;
  }

  final afterSelection =
      _computeSelectionAfterPasteMultipleNodes(editorState, nodes);

  path[path.length - 1]++;
  tb.afterSelection = afterSelection;
  tb.insertNodes(path, nodes);
  editorState.apply(tb);
}

void _handlePaste(EditorState editorState) async {
  final data = await AppFlowyClipboard.getData();

  if (editorState.cursorSelection?.isCollapsed ?? false) {
    _pastRichClipboard(editorState, data);
    return;
  }

  _deleteSelectedContent(editorState);

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _pastRichClipboard(editorState, data);
  });
}

void _pastRichClipboard(EditorState editorState, AppFlowyClipboardData data) {
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
  final transaction = editorState.transaction
    ..updateText(
        node,
        Delta()
          ..retain(beginOffset)
          ..addAll(_lineContentToDelta(line)))
    ..afterSelection = (Selection.collapsed(
        Position(path: selection.end.path, offset: beginOffset + line.length)));
  editorState.apply(transaction);
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
    delta.insert(linkContent, attributes: {"href": linkContent});
    lastUrlEndOffset = match.end;
  }

  if (lastUrlEndOffset < lineContent.length) {
    delta.insert(lineContent.substring(lastUrlEndOffset, lineContent.length));
  }

  return delta;
}

void _pasteMarkdown(EditorState editorState, String markdown) {
  final selection =
      editorState.service.selectionService.currentSelection.value?.normalized;
  if (selection == null) {
    return;
  }

  final lines = markdown.split('\n');

  if (lines.length == 1) {
    _pasteSingleLine(editorState, selection, lines[0]);
    return;
  }

  var path = selection.end.path.next;
  final node = editorState.document.nodeAtPath(selection.end.path);
  if (node is TextNode && node.toPlainText().isEmpty) {
    path = selection.end.path;
  }
  final document = markdownToDocument(markdown);
  final transaction = editorState.transaction;
  transaction.insertNodes(path, document.root.children);
  editorState.apply(transaction);
}

void _handlePastePlainText(EditorState editorState, String plainText) {
  final selection = editorState.cursorSelection?.normalized;
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
    _pasteMarkdown(editorState, plainText);
  }
}

/// 1. copy the selected content
/// 2. delete selected content
void _handleCut(EditorState editorState) {
  _handleCopy(editorState);
  _deleteSelectedContent(editorState);
}

void _deleteSelectedContent(EditorState editorState) {
  final selection = editorState.cursorSelection?.normalized;
  if (selection == null || selection.isCollapsed) {
    return;
  }
  final beginNode = editorState.document.nodeAtPath(selection.start.path)!;
  final endNode = editorState.document.nodeAtPath(selection.end.path)!;
  if (selection.start.path.equals(selection.end.path) &&
      beginNode.type == "text") {
    final textItem = beginNode as TextNode;
    final tb = editorState.transaction;
    final len = selection.end.offset - selection.start.offset;
    tb.updateText(
        textItem,
        Delta()
          ..retain(selection.start.offset)
          ..delete(len));
    tb.afterSelection = Selection.collapsed(selection.start);
    editorState.apply(tb);
    return;
  }
  final traverser = NodeIterator(
    document: editorState.document,
    startNode: beginNode,
    endNode: endNode,
  );
  final tb = editorState.transaction;
  while (traverser.moveNext()) {
    final item = traverser.current;
    if (item.type == "text" && beginNode == item) {
      final textItem = item as TextNode;
      final deleteLen = textItem.delta.length - selection.start.offset;
      tb.updateText(textItem, () {
        final delta = Delta()
          ..retain(selection.start.offset)
          ..delete(deleteLen);

        if (endNode is TextNode) {
          final remain = endNode.delta.slice(selection.end.offset);
          delta.addAll(remain);
        }

        return delta;
      }());
    } else {
      tb.deleteNode(item);
    }
  }
  tb.afterSelection = Selection.collapsed(selection.start);
  editorState.apply(tb);
}

void _setDataToClipboard({String? html, String? text}) {}

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
