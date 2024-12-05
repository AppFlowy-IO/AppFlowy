import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_block_component.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

(EditorState editorState, Node tableNode) createEditorStateAndTable({
  required int rowCount,
  required int columnCount,
  String? defaultContent,
  String Function(int rowIndex, int columnIndex)? contentBuilder,
}) {
  final document = Document.blank()
    ..insert(
      [0],
      [
        createSimpleTableBlockNode(
          columnCount: columnCount,
          rowCount: rowCount,
          defaultContent: defaultContent,
          contentBuilder: contentBuilder,
        ),
      ],
    );
  final editorState = EditorState(document: document);
  return (editorState, document.nodeAtPath([0])!);
}
