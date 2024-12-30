import 'package:appflowy/generated/locale_keys.g.dart';
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
      await tester.insertTableInDocument();

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
      await tester.insertTableInDocument();
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
      await tester.insertTableInDocument();

      // add a new row
      final row = find.byWidgetPredicate((w) {
        return w is SimpleTableRowBlockWidget && w.node.rowIndex == 1;
      });
      await tester.hoverOnWidget(
        row,
        onHover: () async {
          final addRowButton = find.byType(SimpleTableAddRowButton).first;
          await tester.tap(addRowButton);
        },
      );
      await tester.pumpAndSettle();

      // add a new column
      final column = find.byWidgetPredicate((w) {
        return w is SimpleTableCellBlockWidget && w.node.columnIndex == 1;
      }).first;
      await tester.hoverOnWidget(
        column,
        onHover: () async {
          final addColumnButton = find.byType(SimpleTableAddColumnButton).first;
          await tester.tap(addColumnButton);
        },
      );
      await tester.pumpAndSettle();

      // add a new row and a new column
      final row2 = find.byWidgetPredicate((w) {
        return w is SimpleTableCellBlockWidget &&
            w.node.rowIndex == 2 &&
            w.node.columnIndex == 2;
      }).first;
      await tester.hoverOnWidget(
        row2,
        onHover: () async {
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
      await tester.clickMoreActionItemInTableMenu(
        type: SimpleTableMoreActionType.row,
        index: tableNode.rowLength - 1,
        action: SimpleTableMoreAction.delete,
      );
      await tester.pumpAndSettle();
      expect(tableNode.rowLength, 3);
      expect(tableNode.columnLength, 4);

      // delete the last column
      await tester.clickMoreActionItemInTableMenu(
        type: SimpleTableMoreActionType.column,
        index: tableNode.columnLength - 1,
        action: SimpleTableMoreAction.delete,
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
      await tester.insertTableInDocument();

      // enable the header row
      await tester.clickMoreActionItemInTableMenu(
        type: SimpleTableMoreActionType.row,
        index: 0,
        action: SimpleTableMoreAction.enableHeaderRow,
      );
      await tester.pumpAndSettle();
      // enable the header column
      await tester.clickMoreActionItemInTableMenu(
        type: SimpleTableMoreActionType.column,
        index: 0,
        action: SimpleTableMoreAction.enableHeaderColumn,
      );
      await tester.pumpAndSettle();

      final tableNode =
          tester.editor.getCurrentEditorState().document.nodeAtPath([0])!;

      expect(tableNode.isHeaderColumnEnabled, isTrue);
      expect(tableNode.isHeaderRowEnabled, isTrue);

      // disable the header row
      await tester.clickMoreActionItemInTableMenu(
        type: SimpleTableMoreActionType.row,
        index: 0,
        action: SimpleTableMoreAction.enableHeaderRow,
      );
      await tester.pumpAndSettle();
      expect(tableNode.isHeaderColumnEnabled, isTrue);
      expect(tableNode.isHeaderRowEnabled, isFalse);

      // disable the header column
      await tester.clickMoreActionItemInTableMenu(
        type: SimpleTableMoreActionType.column,
        index: 0,
        action: SimpleTableMoreAction.enableHeaderColumn,
      );
      await tester.pumpAndSettle();
      expect(tableNode.isHeaderColumnEnabled, isFalse);
      expect(tableNode.isHeaderRowEnabled, isFalse);
    });

    testWidgets('duplicate a column / row', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createNewPageWithNameUnderParent(
        name: 'simple_table_test',
      );

      await tester.editor.tapLineOfEditorAt(0);
      await tester.insertTableInDocument();

      // duplicate the row
      await tester.clickMoreActionItemInTableMenu(
        type: SimpleTableMoreActionType.row,
        index: 0,
        action: SimpleTableMoreAction.duplicate,
      );
      await tester.pumpAndSettle();

      // duplicate the column
      await tester.clickMoreActionItemInTableMenu(
        type: SimpleTableMoreActionType.column,
        index: 0,
        action: SimpleTableMoreAction.duplicate,
      );
      await tester.pumpAndSettle();

      final tableNode =
          tester.editor.getCurrentEditorState().document.nodeAtPath([0])!;
      expect(tableNode.columnLength, 3);
      expect(tableNode.rowLength, 3);
    });

    testWidgets('insert left / insert right', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createNewPageWithNameUnderParent(
        name: 'simple_table_test',
      );

      await tester.editor.tapLineOfEditorAt(0);
      await tester.insertTableInDocument();

      // insert left
      await tester.clickMoreActionItemInTableMenu(
        type: SimpleTableMoreActionType.column,
        index: 0,
        action: SimpleTableMoreAction.insertLeft,
      );
      await tester.pumpAndSettle();

      // insert right
      await tester.clickMoreActionItemInTableMenu(
        type: SimpleTableMoreActionType.column,
        index: 0,
        action: SimpleTableMoreAction.insertRight,
      );
      await tester.pumpAndSettle();

      final tableNode =
          tester.editor.getCurrentEditorState().document.nodeAtPath([0])!;
      expect(tableNode.columnLength, 4);
      expect(tableNode.rowLength, 2);
    });

    testWidgets('insert above / insert below', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createNewPageWithNameUnderParent(
        name: 'simple_table_test',
      );

      await tester.editor.tapLineOfEditorAt(0);
      await tester.insertTableInDocument();

      // insert above
      await tester.clickMoreActionItemInTableMenu(
        type: SimpleTableMoreActionType.row,
        index: 0,
        action: SimpleTableMoreAction.insertAbove,
      );
      await tester.pumpAndSettle();

      // insert below
      await tester.clickMoreActionItemInTableMenu(
        type: SimpleTableMoreActionType.row,
        index: 0,
        action: SimpleTableMoreAction.insertBelow,
      );
      await tester.pumpAndSettle();

      final tableNode =
          tester.editor.getCurrentEditorState().document.nodeAtPath([0])!;
      expect(tableNode.rowLength, 4);
      expect(tableNode.columnLength, 2);
    });
  });

  testWidgets('set column width to page width (1)', (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();
    await tester.createNewPageWithNameUnderParent(
      name: 'simple_table_test',
    );

    await tester.editor.tapLineOfEditorAt(0);
    await tester.insertTableInDocument();

    final tableNode = tester.editor.getNodeAtPath([0]);
    final beforeWidth = tableNode.width;

    // set the column width to page width
    await tester.clickMoreActionItemInTableMenu(
      type: SimpleTableMoreActionType.column,
      index: 0,
      action: SimpleTableMoreAction.setToPageWidth,
    );
    await tester.pumpAndSettle();

    final afterWidth = tableNode.width;
    expect(afterWidth, greaterThan(beforeWidth));
  });

  testWidgets('set column width to page width (2)', (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();
    await tester.createNewPageWithNameUnderParent(
      name: 'simple_table_test',
    );

    await tester.editor.tapLineOfEditorAt(0);
    await tester.insertTableInDocument();

    final tableNode = tester.editor.getNodeAtPath([0]);
    final beforeWidth = tableNode.width;

    // set the column width to page width
    await tester.clickMoreActionItemInTableMenu(
      type: SimpleTableMoreActionType.row,
      index: 0,
      action: SimpleTableMoreAction.setToPageWidth,
    );
    await tester.pumpAndSettle();

    final afterWidth = tableNode.width;
    expect(afterWidth, greaterThan(beforeWidth));
  });

  testWidgets('distribute columns evenly (1)', (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();
    await tester.createNewPageWithNameUnderParent(
      name: 'simple_table_test',
    );

    await tester.editor.tapLineOfEditorAt(0);
    await tester.insertTableInDocument();

    final tableNode = tester.editor.getNodeAtPath([0]);
    final beforeWidth = tableNode.width;

    // set the column width to page width
    await tester.clickMoreActionItemInTableMenu(
      type: SimpleTableMoreActionType.row,
      index: 0,
      action: SimpleTableMoreAction.distributeColumnsEvenly,
    );
    await tester.pumpAndSettle();

    final afterWidth = tableNode.width;
    expect(afterWidth, equals(beforeWidth));

    final distributeColumnWidthsEvenly =
        tableNode.attributes[SimpleTableBlockKeys.distributeColumnWidthsEvenly];
    expect(distributeColumnWidthsEvenly, isTrue);
  });

  testWidgets('distribute columns evenly (2)', (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();
    await tester.createNewPageWithNameUnderParent(
      name: 'simple_table_test',
    );

    await tester.editor.tapLineOfEditorAt(0);
    await tester.insertTableInDocument();

    final tableNode = tester.editor.getNodeAtPath([0]);
    final beforeWidth = tableNode.width;

    // set the column width to page width
    await tester.clickMoreActionItemInTableMenu(
      type: SimpleTableMoreActionType.column,
      index: 0,
      action: SimpleTableMoreAction.distributeColumnsEvenly,
    );
    await tester.pumpAndSettle();

    final afterWidth = tableNode.width;
    expect(afterWidth, equals(beforeWidth));

    final distributeColumnWidthsEvenly =
        tableNode.attributes[SimpleTableBlockKeys.distributeColumnWidthsEvenly];
    expect(distributeColumnWidthsEvenly, isTrue);
  });

  testWidgets('using option menu to set column width', (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();
    await tester.createNewPageWithNameUnderParent(
      name: 'simple_table_test',
    );

    await tester.editor.tapLineOfEditorAt(0);
    await tester.insertTableInDocument();
    await tester.editor.hoverAndClickOptionMenuButton([0]);

    final editorState = tester.editor.getCurrentEditorState();
    final beforeWidth = editorState.document.nodeAtPath([0])!.width;

    await tester.tapButton(
      find.text(
        LocaleKeys.document_plugins_simpleTable_moreActions_setToPageWidth.tr(),
      ),
    );
    await tester.pumpAndSettle();

    final afterWidth = editorState.document.nodeAtPath([0])!.width;
    expect(afterWidth, greaterThan(beforeWidth));

    await tester.editor.hoverAndClickOptionMenuButton([0]);
    await tester.tapButton(
      find.text(
        LocaleKeys
            .document_plugins_simpleTable_moreActions_distributeColumnsWidth
            .tr(),
      ),
    );
    await tester.pumpAndSettle();

    final afterWidth2 = editorState.document.nodeAtPath([0])!.width;
    expect(afterWidth2, equals(afterWidth));
  });

  testWidgets('insert a table and use select all the delete it',
      (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();
    await tester.createNewPageWithNameUnderParent(
      name: 'simple_table_test',
    );

    await tester.editor.tapLineOfEditorAt(0);
    await tester.insertTableInDocument();

    await tester.editor.tapLineOfEditorAt(1);
    await tester.ime.insertText('Hello World');

    // select all
    await tester.simulateKeyEvent(
      LogicalKeyboardKey.keyA,
      isMetaPressed: UniversalPlatform.isMacOS,
      isControlPressed: !UniversalPlatform.isMacOS,
    );

    await tester.simulateKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();

    final editorState = tester.editor.getCurrentEditorState();
    // only one paragraph left
    expect(editorState.document.root.children.length, 1);
    final paragraphNode = editorState.document.nodeAtPath([0])!;
    expect(paragraphNode.delta, isNull);
  });

  testWidgets('use tab or shift+tab to navigate in table', (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();
    await tester.createNewPageWithNameUnderParent(
      name: 'simple_table_test',
    );

    await tester.editor.tapLineOfEditorAt(0);
    await tester.insertTableInDocument();

    await tester.simulateKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    final editorState = tester.editor.getCurrentEditorState();
    final selection = editorState.selection;
    expect(selection, isNotNull);
    expect(selection!.start.path, [0, 0, 1, 0]);
    expect(selection.end.path, [0, 0, 1, 0]);

    await tester.simulateKeyEvent(
      LogicalKeyboardKey.tab,
      isShiftPressed: true,
    );
    await tester.pumpAndSettle();

    final selection2 = editorState.selection;
    expect(selection2, isNotNull);
    expect(selection2!.start.path, [0, 0, 0, 0]);
    expect(selection2.end.path, [0, 0, 0, 0]);
  });

  testWidgets('shift+enter to insert a new line in table', (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();
    await tester.createNewPageWithNameUnderParent(
      name: 'simple_table_test',
    );

    await tester.editor.tapLineOfEditorAt(0);
    await tester.insertTableInDocument();

    await tester.simulateKeyEvent(
      LogicalKeyboardKey.enter,
      isShiftPressed: true,
    );
    await tester.pumpAndSettle();

    final editorState = tester.editor.getCurrentEditorState();
    final node = editorState.document.nodeAtPath([0, 0, 0])!;
    expect(node.children.length, 1);
  });

  testWidgets('using option menu to set table align', (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();
    await tester.createNewPageWithNameUnderParent(
      name: 'simple_table_test',
    );

    await tester.editor.tapLineOfEditorAt(0);
    await tester.insertTableInDocument();
    await tester.editor.hoverAndClickOptionMenuButton([0]);

    final editorState = tester.editor.getCurrentEditorState();
    final beforeAlign = editorState.document.nodeAtPath([0])!.tableAlign;
    expect(beforeAlign, TableAlign.left);

    await tester.tapButton(
      find.text(
        LocaleKeys.document_plugins_simpleTable_moreActions_align.tr(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapButton(
      find.text(
        LocaleKeys.document_plugins_optionAction_center.tr(),
      ),
    );
    await tester.pumpAndSettle();

    final afterAlign = editorState.document.nodeAtPath([0])!.tableAlign;
    expect(afterAlign, TableAlign.center);

    await tester.editor.hoverAndClickOptionMenuButton([0]);
    await tester.tapButton(
      find.text(
        LocaleKeys.document_plugins_simpleTable_moreActions_align.tr(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapButton(
      find.text(
        LocaleKeys.document_plugins_optionAction_right.tr(),
      ),
    );
    await tester.pumpAndSettle();

    final afterAlign2 = editorState.document.nodeAtPath([0])!.tableAlign;
    expect(afterAlign2, TableAlign.right);

    await tester.editor.hoverAndClickOptionMenuButton([0]);
    await tester.tapButton(
      find.text(
        LocaleKeys.document_plugins_simpleTable_moreActions_align.tr(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapButton(
      find.text(
        LocaleKeys.document_plugins_optionAction_left.tr(),
      ),
    );
    await tester.pumpAndSettle();

    final afterAlign3 = editorState.document.nodeAtPath([0])!.tableAlign;
    expect(afterAlign3, TableAlign.left);
  });

  testWidgets('using option menu to set table align', (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();
    await tester.createNewPageWithNameUnderParent(
      name: 'simple_table_test',
    );

    await tester.editor.tapLineOfEditorAt(0);
    await tester.insertTableInDocument();
    await tester.editor.hoverAndClickOptionMenuButton([0]);

    final editorState = tester.editor.getCurrentEditorState();
    final beforeAlign = editorState.document.nodeAtPath([0])!.tableAlign;
    expect(beforeAlign, TableAlign.left);

    await tester.tapButton(
      find.text(
        LocaleKeys.document_plugins_simpleTable_moreActions_align.tr(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapButton(
      find.text(
        LocaleKeys.document_plugins_optionAction_center.tr(),
      ),
    );
    await tester.pumpAndSettle();

    final afterAlign = editorState.document.nodeAtPath([0])!.tableAlign;
    expect(afterAlign, TableAlign.center);

    await tester.editor.hoverAndClickOptionMenuButton([0]);
    await tester.tapButton(
      find.text(
        LocaleKeys.document_plugins_simpleTable_moreActions_align.tr(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapButton(
      find.text(
        LocaleKeys.document_plugins_optionAction_right.tr(),
      ),
    );
    await tester.pumpAndSettle();

    final afterAlign2 = editorState.document.nodeAtPath([0])!.tableAlign;
    expect(afterAlign2, TableAlign.right);

    await tester.editor.hoverAndClickOptionMenuButton([0]);
    await tester.tapButton(
      find.text(
        LocaleKeys.document_plugins_simpleTable_moreActions_align.tr(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapButton(
      find.text(
        LocaleKeys.document_plugins_optionAction_left.tr(),
      ),
    );
    await tester.pumpAndSettle();

    final afterAlign3 = editorState.document.nodeAtPath([0])!.tableAlign;
    expect(afterAlign3, TableAlign.left);
  });

  testWidgets('support slash menu in table', (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();
    await tester.createNewPageWithNameUnderParent(
      name: 'simple_table_test',
    );

    final editorState = tester.editor.getCurrentEditorState();

    await tester.editor.tapLineOfEditorAt(0);
    await tester.insertTableInDocument();

    final path = [0, 0, 0, 0];
    final selection = Selection.collapsed(Position(path: path));
    editorState.selection = selection;
    await tester.editor.showSlashMenu();
    await tester.pumpAndSettle();

    final paragraphItem = find.byWidgetPredicate((w) {
      return w is SelectionMenuItemWidget &&
          w.item.name == LocaleKeys.document_slashMenu_name_text.tr();
    });
    expect(paragraphItem, findsOneWidget);

    await tester.tap(paragraphItem);
    await tester.pumpAndSettle();

    final paragraphNode = editorState.document.nodeAtPath(path)!;
    expect(paragraphNode.type, equals(ParagraphBlockKeys.type));
  });
}

extension on WidgetTester {
  /// Insert a table in the document
  Future<void> insertTableInDocument() async {
    // open the actions menu and insert the outline block
    await editor.showSlashMenu();
    await editor.tapSlashMenuItemWithName(
      LocaleKeys.document_slashMenu_name_table.tr(),
    );
    await pumpAndSettle();
  }

  Future<void> clickMoreActionItemInTableMenu({
    required SimpleTableMoreActionType type,
    required int index,
    required SimpleTableMoreAction action,
  }) async {
    if (type == SimpleTableMoreActionType.row) {
      final row = find.byWidgetPredicate((w) {
        return w is SimpleTableRowBlockWidget && w.node.rowIndex == index;
      });
      await hoverOnWidget(
        row,
        onHover: () async {
          final moreActionButton = find.byWidgetPredicate((w) {
            return w is SimpleTableMoreActionMenu &&
                w.type == SimpleTableMoreActionType.row &&
                w.index == index;
          });
          await tapButton(moreActionButton);
          await tapButton(find.text(action.name));
        },
      );
      await pumpAndSettle();
    } else if (type == SimpleTableMoreActionType.column) {
      final column = find.byWidgetPredicate((w) {
        return w is SimpleTableCellBlockWidget && w.node.columnIndex == index;
      }).first;
      await hoverOnWidget(
        column,
        onHover: () async {
          final moreActionButton = find.byWidgetPredicate((w) {
            return w is SimpleTableMoreActionMenu &&
                w.type == SimpleTableMoreActionType.column &&
                w.index == index;
          });
          await tapButton(moreActionButton);
          await tapButton(find.text(action.name));
        },
      );
      await pumpAndSettle();
    }

    await tapAt(Offset.zero);
  }
}
