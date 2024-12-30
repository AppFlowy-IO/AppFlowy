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
        await pasteMultiLineNodes(nodes.toList());
      }
      return true;
    } catch (e) {
      Log.error(
        'Failed to paste in app json: $inAppJson, error: $e',
      );
    }
    return false;
  }
}
