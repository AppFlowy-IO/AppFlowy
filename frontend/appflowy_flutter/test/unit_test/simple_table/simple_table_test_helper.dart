import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
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

Future<void> updateTableColumnAttributes(
  EditorState editorState,
  Node tableNode, {
  required int columnIndex,
  TableAlign? align,
  String? color,
  double? width,
}) async {
  final cell = tableNode.getTableCellNode(
    rowIndex: 0,
    columnIndex: columnIndex,
  )!;

  if (align != null) {
    await editorState.updateColumnAlign(
      tableCellNode: cell,
      align: align,
    );
  }

  if (color != null) {
    await editorState.updateColumnBackgroundColor(
      tableCellNode: cell,
      color: color,
    );
  }

  if (width != null) {
    await editorState.updateColumnWidth(
      tableCellNode: cell,
      width: width,
    );
  }
}

Future<void> updateTableRowAttributes(
  EditorState editorState,
  Node tableNode, {
  required int rowIndex,
  TableAlign? align,
  String? color,
}) async {
  final cell = tableNode.getTableCellNode(
    rowIndex: rowIndex,
    columnIndex: 0,
  )!;

  if (align != null) {
    await editorState.updateRowAlign(
      tableCellNode: cell,
      align: align,
    );
  }

  if (color != null) {
    await editorState.updateRowBackgroundColor(
      tableCellNode: cell,
      color: color,
    );
  }
}
