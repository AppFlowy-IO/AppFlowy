import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';

/// ``` to code block
///
/// - support
///   - desktop
///   - mobile
///   - web
///
final CharacterShortcutEvent formatBacktickToCodeBlock = CharacterShortcutEvent(
  key: '``` to code block',
  character: '`',
  handler: (editorState) async => _convertBacktickToCodeBlock(
    editorState: editorState,
  ),
);

Future<bool> _convertBacktickToCodeBlock({
  required EditorState editorState,
}) async {
  final selection = editorState.selection;
  if (selection == null || !selection.isCollapsed) {
    return false;
  }

  final node = editorState.getNodeAtPath(selection.end.path);
  final delta = node?.delta;
  if (node == null || delta == null || delta.isEmpty) {
    return false;
  }

  // only active when the backtick is at the beginning of the line
  final keyword = '``';
  final plainText = delta.toPlainText();
  if (!plainText.startsWith(keyword)) {
    return false;
  }

  final transaction = editorState.transaction;
  final deltaWithoutKeyword = delta.compose(Delta()..delete(keyword.length));
  transaction.insertNodes(
    selection.end.path,
    [
      codeBlockNode(
        delta: deltaWithoutKeyword,
      ),
      if (node.children.isNotEmpty) ...node.children.map((e) => e.copyWith()),
    ],
  );
  transaction.deleteNode(node);
  transaction.afterSelection = Selection.collapsed(
    Position(path: selection.start.path),
  );
  await editorState.apply(transaction);

  return true;
}
