import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/_shared_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../shared/util.dart';

const String heading1 = "Heading 1";
const String heading2 = "Heading 2";
const String heading3 = "Heading 3";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('simple table block test:', () {
    testWidgets('insert a simple table block', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createNewPageWithNameUnderParent(
        name: 'simple_table_test',
      );

      await tester.editor.tapLineOfEditorAt(0);
      await insertTableInDocument(tester);

      // validate the table is inserted
      expect(find.byType(SimpleTableBlockWidget), findsOneWidget);

      final editorState = tester.editor.getCurrentEditorState();
      expect(
        editorState.selection,
        // table -> row -> cell -> paragraph
        Selection.collapsed(Position(path: [0, 0, 0, 0])),
      );

      final firstCell = find.byType(SimpleTableCellBlockWidget).first;
      expect(
        tester
            .state<SimpleTableCellBlockWidgetState>(firstCell)
            .isEditingCellNotifier
            .value,
        isTrue,
      );
    });

    testWidgets('select all in table cell', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createNewPageWithNameUnderParent(
        name: 'simple_table_test',
      );

      const cell1Content = 'Cell 1';

      await tester.editor.tapLineOfEditorAt(0);
      await tester.ime.insertText('New Table');
      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.editor.tapLineOfEditorAt(1);
      await insertTableInDocument(tester);
      await tester.ime.insertText(cell1Content);
      await tester.pumpAndSettle();
      // Select all in the cell
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyA,
        isControlPressed: !UniversalPlatform.isMacOS,
        isMetaPressed: UniversalPlatform.isMacOS,
      );

      expect(
        tester.editor.getCurrentEditorState().selection,
        Selection(
          start: Position(path: [1, 0, 0, 0]),
          end: Position(path: [1, 0, 0, 0], offset: cell1Content.length),
        ),
      );

      // Press select all again, the selection should be the entire document
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyA,
        isControlPressed: !UniversalPlatform.isMacOS,
        isMetaPressed: UniversalPlatform.isMacOS,
      );

      expect(
        tester.editor.getCurrentEditorState().selection,
        Selection(
          start: Position(path: [0]),
          end: Position(path: [1, 1, 1, 0]),
        ),
      );
    });

    testWidgets('''
1. hover on the table
  1.1 click the add row button
  1.2 click the add column button
  1.3 click the add row and column button
2. validate the table is updated
3. delete the last column
4. delete the last row
5. validate the table is updated
''', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createNewPageWithNameUnderParent(
        name: 'simple_table_test',
      );

      await tester.editor.tapLineOfEditorAt(0);
      await insertTableInDocument(tester);

      // hover on the table
      final tableBlock = find.byType(SimpleTableBlockWidget).first;
      await tester.hoverOnWidget(
        tableBlock,
        onHover: () async {
          // click the add row button
          final addRowButton = find.byType(SimpleTableAddRowButton).first;
          await tester.tap(addRowButton);

          // click the add column button
          final addColumnButton = find.byType(SimpleTableAddColumnButton).first;
          await tester.tap(addColumnButton);

          // click the add row and column button
          final addRowAndColumnButton =
              find.byType(SimpleTableAddColumnAndRowButton).first;
          await tester.tap(addRowAndColumnButton);
        },
      );
      await tester.pumpAndSettle();

      final tableNode =
          tester.editor.getCurrentEditorState().document.nodeAtPath([0])!;
      expect(tableNode.columnLength, 4);
      expect(tableNode.rowLength, 4);

      // delete the last row
      final lastRow = find.byWidgetPredicate((w) {
        return w is SimpleTableRowBlockWidget &&
            w.node.rowIndex == tableNode.rowLength - 1;
      });
      await tester.hoverOnWidget(
        lastRow,
        onHover: () async {
          // click the more action button
          final moreActionButton = find.byWidgetPredicate((w) {
            return w is SimpleTableMoreActionMenu &&
                w.type == SimpleTableMoreActionType.row &&
                w.index == tableNode.rowLength - 1;
          });
          await tester.tapButton(moreActionButton);
          await tester.tapButton(find.text(SimpleTableMoreAction.delete.name));
        },
      );
      await tester.pumpAndSettle();

      expect(tableNode.rowLength, 3);
      expect(tableNode.columnLength, 4);

      // delete the last column
      final lastColumn = find.byWidgetPredicate((w) {
        return w is SimpleTableCellBlockWidget &&
            w.node.columnIndex == tableNode.columnLength - 1;
      }).first;
      await tester.hoverOnWidget(
        lastColumn,
        onHover: () async {
          final moreActionButton = find.byWidgetPredicate((w) {
            return w is SimpleTableMoreActionMenu &&
                w.type == SimpleTableMoreActionType.column &&
                w.index == tableNode.columnLength - 1;
          });
          await tester.tapButton(moreActionButton);
          await tester.tapButton(find.text(SimpleTableMoreAction.delete.name));
        },
      );
      await tester.pumpAndSettle();

      expect(tableNode.columnLength, 3);
      expect(tableNode.rowLength, 3);
    });

    testWidgets('enable header column and header row', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createNewPageWithNameUnderParent(
        name: 'simple_table_test',
      );

      await tester.editor.tapLineOfEditorAt(0);
      await insertTableInDocument(tester);

      // hover on the first row
      final firstRow = find.byWidgetPredicate((w) {
        return w is SimpleTableRowBlockWidget && w.node.rowIndex == 0;
      });
      await tester.hoverOnWidget(
        firstRow,
        onHover: () async {
          final moreActionButton = find.byWidgetPredicate((w) {
            return w is SimpleTableMoreActionMenu &&
                w.type == SimpleTableMoreActionType.row &&
                w.index == 0;
          });
          await tester.tapButton(moreActionButton);
          await tester.tapButton(
            find.text(SimpleTableMoreAction.enableHeaderRow.name),
          );
        },
      );
      await tester.pumpAndSettle();
      // cancel the popup
      await tester.tapAt(Offset.zero);

      // hover on the first column
      final firstColumn = find.byWidgetPredicate((w) {
        return w is SimpleTableCellBlockWidget && w.node.columnIndex == 0;
      }).first;
      await tester.hoverOnWidget(
        firstColumn,
        onHover: () async {
          final moreActionButton = find.byWidgetPredicate((w) {
            return w is SimpleTableMoreActionMenu &&
                w.type == SimpleTableMoreActionType.column &&
                w.index == 0;
          });
          await tester.tapButton(moreActionButton);
          await tester.tapButton(
            find.text(SimpleTableMoreAction.enableHeaderColumn.name),
          );
        },
      );
      await tester.pumpAndSettle();

      final tableNode =
          tester.editor.getCurrentEditorState().document.nodeAtPath([0])!;

      expect(tableNode.isHeaderColumnEnabled, isTrue);
      expect(tableNode.isHeaderRowEnabled, isTrue);
    });
  });
}

/// Insert a table in the document
Future<void> insertTableInDocument(WidgetTester tester) async {
  // open the actions menu and insert the outline block
  await tester.editor.showSlashMenu();
  await tester.editor.tapSlashMenuItemWithName(
    LocaleKeys.document_slashMenu_name_table.tr(),
  );
  await tester.pumpAndSettle();
}
