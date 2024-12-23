import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter_test/flutter_test.dart';

import 'simple_table_test_helper.dart';

void main() {
  group('Simple table content operation:', () {
    void setupDependencyInjection() {
      getIt.registerSingleton<ClipboardService>(ClipboardService());
    }

    setUpAll(() {
      Log.shared.disableLog = true;

      setupDependencyInjection();
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
      await editorState.clearContentAtRowIndex(
        tableNode: tableNode,
        rowIndex: 0,
      );
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
      await editorState.clearContentAtRowIndex(
        tableNode: tableNode,
        rowIndex: 2,
      );
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
      await editorState.clearContentAtColumnIndex(
        tableNode: tableNode,
        columnIndex: 0,
      );
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
      await editorState.clearContentAtColumnIndex(
        tableNode: tableNode,
        columnIndex: 3,
      );
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

    test('copy row 1-2', () async {
      const rowCount = 2;
      const columnCount = 3;

      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: rowCount,
        columnCount: columnCount,
        contentBuilder: (rowIndex, columnIndex) =>
            'row $rowIndex, column $columnIndex',
      );

      for (var rowIndex = 0; rowIndex < rowCount; rowIndex++) {
        final data = await editorState.copyRow(
          tableNode: tableNode,
          rowIndex: rowIndex,
        );
        expect(data, isNotNull);
        expect(
          data?.plainText,
          'row $rowIndex, column 0\nrow $rowIndex, column 1\nrow $rowIndex, column 2',
        );
      }
    });

    test('copy column 1-2', () async {
      const rowCount = 2;
      const columnCount = 3;

      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: rowCount,
        columnCount: columnCount,
        contentBuilder: (rowIndex, columnIndex) =>
            'row $rowIndex, column $columnIndex',
      );

      for (var columnIndex = 0; columnIndex < columnCount; columnIndex++) {
        final data = await editorState.copyColumn(
          tableNode: tableNode,
          columnIndex: columnIndex,
        );
        expect(data, isNotNull);
        expect(
          data?.plainText,
          'row 0, column $columnIndex\nrow 1, column $columnIndex',
        );
      }
    });

    test('cut row 1-2', () async {
      const rowCount = 2;
      const columnCount = 3;

      final (editorState, tableNode) = createEditorStateAndTable(
        rowCount: rowCount,
        columnCount: columnCount,
        contentBuilder: (rowIndex, columnIndex) =>
            'row $rowIndex, column $columnIndex',
      );

      for (var rowIndex = 0; rowIndex < rowCount; rowIndex++) {
        final data = await editorState.copyRow(
          tableNode: tableNode,
          rowIndex: rowIndex,
          clearContent: true,
        );
        expect(data, isNotNull);
        expect(
          data?.plainText,
          'row $rowIndex, column 0\nrow $rowIndex, column 1\nrow $rowIndex, column 2',
        );
      }

      for (var rowIndex = 0; rowIndex < rowCount; rowIndex++) {
        for (var columnIndex = 0; columnIndex < columnCount; columnIndex++) {
          expect(
            tableNode
                .getTableCellNode(rowIndex: rowIndex, columnIndex: columnIndex)
                ?.children
                .first
                .delta
                ?.toPlainText(),
            '',
          );
        }
      }
    });
  });
}
