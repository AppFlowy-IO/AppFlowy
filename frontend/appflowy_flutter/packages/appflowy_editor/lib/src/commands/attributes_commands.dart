import 'package:appflowy_editor/src/commands/command_extension.dart';
import 'package:appflowy_editor/src/core/document/attributes.dart';
import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/core/document/path.dart';
import 'package:appflowy_editor/src/editor_state.dart';

extension TextCommands on EditorState {
  Future<void> updateNodeAttributes(
    Attributes attributes, {
    Path? path,
    Node? node,
  }) {
    return futureCommand(() {
      final n = getNode(path: path, node: node);
      apply(
        transaction..updateNode(n, attributes),
      );
    });
  }
}
