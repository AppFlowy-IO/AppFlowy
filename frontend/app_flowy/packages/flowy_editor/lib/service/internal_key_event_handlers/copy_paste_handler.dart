import 'package:html/dom.dart' as html;
import 'package:flowy_editor/flowy_editor.dart';
import 'package:flowy_editor/service/keyboard_service.dart';
import 'package:flowy_editor/infra/html_converter.dart';
import 'package:flowy_editor/document/node_iterator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rich_clipboard/rich_clipboard.dart';

class _HTMLNormalizer {
  final List<html.Node> nodes;
  html.Element? _pendingList;

  _HTMLNormalizer(this.nodes);

  List<html.Node> normalize() {
    final result = <html.Node>[];

    for (final item in nodes) {
      if (item is Text) {
        result.add(item);
        continue;
      }

      if (item is html.Element) {
        if (item.localName == "li") {
          if (_pendingList != null) {
            _pendingList!.append(item);
          } else {
            final ulItem = html.Element.tag("ul");
            ulItem.append(item);

            _pendingList = ulItem;
          }
        } else {
          _pushList(result);
          result.add(item);
        }
      }
    }

    return result;
  }

  _pushList(List<html.Node> result) {
    if (_pendingList == null) {
      return;
    }
    result.add(_pendingList!);
    _pendingList = null;
  }
}

_handleCopy(EditorState editorState) async {
  final selection = editorState.cursorSelection;
  if (selection == null || selection.isCollapsed) {
    return;
  }
  if (pathEquals(selection.start.path, selection.end.path)) {
    final nodeAtPath = editorState.document.nodeAtPath(selection.end.path)!;
    if (nodeAtPath.type == "text") {
      final textNode = nodeAtPath as TextNode;
      final htmlString = stringify(textNodeToHtml(textNode));
      debugPrint('copy html: $htmlString');
      RichClipboard.setData(RichClipboardData(html: htmlString));
    } else {
      debugPrint("unimplemented: copy non-text");
    }
    return;
  }

  final beginNode = editorState.document.nodeAtPath(selection.start.path)!;
  final endNode = editorState.document.nodeAtPath(selection.end.path)!;
  final traverser = NodeIterator(editorState.document, beginNode, endNode);

  final nodes = <html.Node>[];
  while (traverser.moveNext()) {
    final node = traverser.current;
    if (node.type == "text") {
      final textNode = node as TextNode;
      if (node == beginNode) {
        nodes.add(textNodeToHtml(textNode));
      } else if (node == endNode) {
        nodes.add(textNodeToHtml(textNode, end: selection.end.offset));
      } else {
        nodes.add(textNodeToHtml(textNode));
      }
    }
    // TODO: handle image and other blocks
  }

  final copyString = _HTMLNormalizer(nodes).normalize().fold<String>(
      "", ((previousValue, element) => previousValue + stringify(element)));
  debugPrint('copy html: $copyString');
  RichClipboard.setData(RichClipboardData(html: copyString));
}

_pasteHTML(EditorState editorState, String html) {
  final selection = editorState.cursorSelection;
  if (selection == null) {
    return;
  }

  final path = [...selection.end.path];
  if (path.isEmpty) {
    return;
  }

  debugPrint('paste html: $html');
  final converter = HTMLConverter(html);
  final nodes = converter.toNodes();

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
          () => Delta().retain(startOffset).concat(firstTextNode.delta));
      tb.setAfterSelection(Selection.collapsed(Position(
          path: path, offset: startOffset + firstTextNode.delta.length)));
      tb.commit();
      return;
    }
  }

  _pasteMultipleLinesInText(editorState, path, selection.start.offset, nodes);
}

_pasteMultipleLinesInText(
    EditorState editorState, List<int> path, int offset, List<Node> nodes) {
  final tb = TransactionBuilder(editorState);

  final firstNode = nodes[0];
  final nodeAtPath = editorState.document.nodeAtPath(path)!;

  if (nodeAtPath.type == "text" && firstNode.type == "text") {
    // split and merge
    final textNodeAtPath = nodeAtPath as TextNode;
    final firstTextNode = firstNode as TextNode;
    final remain = textNodeAtPath.delta.slice(offset);

    tb.textEdit(
        textNodeAtPath,
        () => Delta()
            .retain(offset)
            .delete(remain.length)
            .concat(firstTextNode.delta));

    final tailNodes = nodes.sublist(1);
    path[path.length - 1]++;
    if (tailNodes.isNotEmpty) {
      if (tailNodes.last.type == "text") {
        final tailTextNode = tailNodes.last as TextNode;
        tailTextNode.delta = tailTextNode.delta.concat(remain);
      } else if (remain.length > 0) {
        tailNodes.add(TextNode(type: "text", delta: remain));
      }
    } else {
      tailNodes.add(TextNode(type: "text", delta: remain));
    }

    tb.insertNodes(path, tailNodes);
    tb.commit();
    return;
  }

  path[path.length - 1]++;
  tb.insertNodes(path, nodes);
  tb.commit();
}

_handlePaste(EditorState editorState) async {
  final data = await RichClipboard.getData();
  if (data.html != null) {
    _pasteHTML(editorState, data.html!);
    return;
  }
  if (data.text != null) {
    _handlePastePlainText(editorState, data.text!);
    return;
  }
}

_handlePastePlainText(EditorState editorState, String plainText) {
  final selection = editorState.cursorSelection;
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
    final node =
        editorState.document.nodeAtPath(selection.end.path)! as TextNode;
    final beginOffset = selection.end.offset;
    TransactionBuilder(editorState)
      ..textEdit(node, () => Delta().retain(beginOffset).insert(lines[0]))
      ..setAfterSelection(Selection.collapsed(Position(
          path: selection.end.path, offset: beginOffset + lines[0].length)))
      ..commit();
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
    var index = 0;
    final tb = TransactionBuilder(editorState);
    final nodes = remains.map((e) {
      if (index++ == remains.length - 1) {
        return TextNode(
            type: "text",
            delta: Delta().insert(e).addAll(insertedLineSuffix.operations));
      }
      return TextNode(type: "text", delta: Delta().insert(e));
    }).toList();
    // insert first line
    tb.textEdit(
        node,
        () => Delta()
            .retain(beginOffset)
            .insert(firstLine)
            .delete(node.delta.length - beginOffset));
    // insert remains
    tb.insertNodes(path, nodes);
    tb.commit();

    // fixme: don't set the cursor manually
    editorState.updateCursorSelection(Selection.collapsed(
        Position(path: nodes.last.path, offset: lines.last.length)));
  }
}

/// 1. copy the selected content
/// 2. delete selected content
_handleCut(EditorState editorState) {
  debugPrint('cut');
  final selection = editorState.cursorSelection;
  if (selection == null) {
    return;
  }

  if (selection.isCollapsed) {
    return;
  }

  _handleCopy(editorState);
  _deleteSelectedContent(editorState);
}

_deleteSelectedContent(EditorState editorState) {
  final selection = editorState.cursorSelection;
  if (selection == null) {
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
        textItem, () => Delta().retain(selection.start.offset).delete(len));
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
        final delta = Delta();
        delta.retain(selection.start.offset).delete(deleteLen);

        if (endNode is TextNode) {
          final remain = endNode.delta.slice(selection.end.offset);
          delta.addAll(remain.operations);
        }

        return delta;
      });
      tb.setAfterSelection(Selection.collapsed(selection.start));
    } else {
      tb.deleteNode(item);
    }
  }
  tb.commit();
}

FlowyKeyEventHandler copyPasteKeysHandler = (editorState, event) {
  if (event.isMetaPressed && event.logicalKey == LogicalKeyboardKey.keyC) {
    _handleCopy(editorState);
    return KeyEventResult.handled;
  }
  if (event.isMetaPressed && event.logicalKey == LogicalKeyboardKey.keyV) {
    _handlePaste(editorState);
    return KeyEventResult.handled;
  }
  if (event.isMetaPressed && event.logicalKey == LogicalKeyboardKey.keyX) {
    _handleCut(editorState);
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};
