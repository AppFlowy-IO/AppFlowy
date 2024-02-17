import 'dart:convert';

import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/editor_state_paste_node_extension.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;

extension PasteFromInAppJson on EditorState {
  Future<bool> pasteInAppJson(String inAppJson) async {
    try {
      final nodes = Document.fromJson(jsonDecode(inAppJson)).root.children;
      if (nodes.isEmpty) {
        return false;
      }
      if (nodes.length == 1) {
        await pasteSingleLineNode(nodes.first);
      } else {
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
