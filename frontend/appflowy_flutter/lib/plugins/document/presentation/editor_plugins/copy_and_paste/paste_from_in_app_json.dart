import 'dart:convert';

import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

extension PasteFromInAppJson on EditorState {
  Future<bool> pasteInAppJson(String inAppJson) async {
    try {
      final nodes = Document.fromJson(jsonDecode(inAppJson)).root.children;
      if (nodes.isEmpty) {
        Log.info('pasteInAppJson: nodes is empty');
        return false;
      }
      if (nodes.length == 1) {
        Log.info('pasteInAppJson: single line node');
        await pasteSingleLineNode(nodes.first);
      } else {
        Log.info('pasteInAppJson: multi line nodes');
        final startWithNonDeltaBlock = nodes.first.delta == null;
        if (startWithNonDeltaBlock) {
          await _pasteNodesAfterCurrentLine(nodes);
        } else {
          await pasteMultiLineNodes(nodes.toList());
        }
      }
      return true;
    } catch (e) {
      Log.error(
        'Failed to paste in app json: $inAppJson, error: $e',
      );
    }
    return false;
  }

  // if the pasted nodes start with the non-delta block(s),
  //  insert them after the current line
  Future<void> _pasteNodesAfterCurrentLine(List<Node> nodes) async {
    final selection = await deleteSelectionIfNeeded();
    if (selection == null) {
      return;
    }

    final node = getNodeAtPath(selection.start.path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return;
    }

    final transaction = this.transaction;
    transaction.insertNodes(node.path.next, nodes);
    await apply(transaction);
  }
}
