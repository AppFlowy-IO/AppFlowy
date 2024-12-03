import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter_test/flutter_test.dart';

import 'simple_table_test_helper.dart';

void main() {
  group('Simple table content operation:', () {
    setUpAll(() {
      Log.shared.disableLog = true;
    });

    tearDownAll(() {
      Log.shared.disableLog = false;
    });

    test('clear content at row 1', () async {
      const defaultContent = 'default content';
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 2,
        columnCount: 3,
        defaultContent: defaultContent,
      );
      await editorState.clearContentAtRowIndex(tableNode, 0);
      for (var i = 0; i < tableNode.rowLength; i++) {
        for (var j = 0; j < tableNode.columnLength; j++) {
          expect(
            tableNode
                .getTableCellNode(rowIndex: i, columnIndex: j)
                ?.children
                .first
                .delta
                ?.toPlainText(),
            i == 0 ? '' : defaultContent,
          );
        }
      }
    });

    test('clear content at row 3', () async {
      const defaultContent = 'default content';
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 3,
        columnCount: 4,
        defaultContent: defaultContent,
      );
      await editorState.clearContentAtRowIndex(tableNode, 2);
      for (var i = 0; i < tableNode.rowLength; i++) {
        for (var j = 0; j < tableNode.columnLength; j++) {
          expect(
            tableNode
                .getTableCellNode(rowIndex: i, columnIndex: j)
                ?.children
                .first
                .delta
                ?.toPlainText(),
            i == 2 ? '' : defaultContent,
          );
        }
      }
    });

    test('clear content at column 1', () async {
      const defaultContent = 'default content';
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 2,
        columnCount: 3,
        defaultContent: defaultContent,
      );
      await editorState.clearContentAtColumnIndex(tableNode, 0);
      for (var i = 0; i < tableNode.rowLength; i++) {
        for (var j = 0; j < tableNode.columnLength; j++) {
          expect(
            tableNode
                .getTableCellNode(rowIndex: i, columnIndex: j)
                ?.children
                .first
                .delta
                ?.toPlainText(),
            j == 0 ? '' : defaultContent,
          );
        }
      }
    });

    test('clear content at column 4', () async {
      const defaultContent = 'default content';
      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: 3,
        columnCount: 4,
        defaultContent: defaultContent,
      );
      await editorState.clearContentAtColumnIndex(tableNode, 3);
      for (var i = 0; i < tableNode.rowLength; i++) {
        for (var j = 0; j < tableNode.columnLength; j++) {
          expect(
            tableNode
                .getTableCellNode(rowIndex: i, columnIndex: j)
                ?.children
                .first
                .delta
                ?.toPlainText(),
            j == 3 ? '' : defaultContent,
          );
        }
      }
    });
  });
}
