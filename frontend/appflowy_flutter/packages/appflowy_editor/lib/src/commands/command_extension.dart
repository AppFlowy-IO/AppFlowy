import 'dart:async';

import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/core/document/path.dart';
import 'package:appflowy_editor/src/core/location/selection.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:flutter/widgets.dart';

extension CommandExtension on EditorState {
  Future<void> futureCommand(void Function() fn) async {
    final completer = Completer<void>();
    fn();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      completer.complete();
    });
    return completer.future;
  }

  Node getNode({
    Path? path,
    Node? node,
  }) {
    if (node != null) {
      return node;
    } else if (path != null) {
      return document.nodeAtPath(path)!;
    }
    throw Exception('path and node cannot be null at the same time');
  }

  TextNode getTextNode({
    Path? path,
    TextNode? textNode,
  }) {
    if (textNode != null) {
      return textNode;
    } else if (path != null) {
      return document.nodeAtPath(path)! as TextNode;
    }
    throw Exception('path and node cannot be null at the same time');
  }

  Selection getSelection(
    Selection? selection,
  ) {
    final currentSelection = service.selectionService.currentSelection.value;
    if (selection != null) {
      return selection;
    } else if (currentSelection != null) {
      return currentSelection;
    }
    throw Exception('path and textNode cannot be null at the same time');
  }

  List<String> getTextInSelection(
    List<TextNode> textNodes,
    Selection selection,
  ) {
    List<String> res = [];
    if (selection.isSingle) {
      final plainText = textNodes.first.toPlainText();
      res.add(plainText.substring(selection.startIndex, selection.endIndex));
    } else if (!selection.isCollapsed) {
      for (var i = 0; i < textNodes.length; i++) {
        final plainText = textNodes[i].toPlainText();
        if (i == 0) {
          res.add(
            plainText.substring(
              selection.startIndex,
              plainText.length,
            ),
          );
        } else if (i == textNodes.length - 1) {
          res.add(plainText.substring(0, selection.endIndex));
        } else {
          res.add(plainText);
        }
      }
    }
    return res;
  }
}
