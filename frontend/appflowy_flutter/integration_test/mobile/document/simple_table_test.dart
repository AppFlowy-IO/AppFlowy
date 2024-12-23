import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('simple table:', () {
    testWidgets('''
1. insert a simple table via + menu
2. insert a row above the table
3. insert a row below the table
4. insert a column left to the table
5. insert a column right to the table
6. delete the first row
7. delete the first column
''', (tester) async {
      await tester.launchInAnonymousMode();
      await tester.createNewDocumentOnMobile('simple table');

      final editorState = tester.editor.getCurrentEditorState();
      // focus on the editor
      unawaited(
        editorState.updateSelectionWithReason(
          Selection.collapsed(Position(path: [0])),
          reason: SelectionUpdateReason.uiEvent,
        ),
      );
      await tester.pumpAndSettle();

      final firstParagraphPath = [0, 0, 0, 0];

      // open the plus menu and select the table block
      {
        await tester.openPlusMenuAndClickButton(
          LocaleKeys.document_slashMenu_name_table.tr(),
        );

        // check the block is inserted
        final table = editorState.getNodeAtPath([0])!;
        expect(table.type, equals(SimpleTableBlockKeys.type));
        expect(table.rowLength, equals(2));
        expect(table.columnLength, equals(2));

        // focus on the first cell

        final selection = editorState.selection!;
        expect(selection.isCollapsed, isTrue);
        expect(selection.start.path, equals(firstParagraphPath));
      }

      // insert left and insert right
      {
        // click the column menu button
        await tester.clickColumnMenuButton(0);

        // insert left, insert right
        await tester.tapButton(
          find.findTextInFlowyText(
            LocaleKeys.document_plugins_simpleTable_moreActions_insertLeft.tr(),
          ),
        );
        await tester.tapButton(
          find.findTextInFlowyText(
            LocaleKeys.document_plugins_simpleTable_moreActions_insertRight
                .tr(),
          ),
        );

        // click empty area to cancel the selection
        await tester.tapAt(Offset.zero);
        expect(editorState.selection, isNull);
        await tester.pumpUntilNotFound(find.byType(SimpleTableCellBottomSheet));

        // check the table is updated
        final table = editorState.getNodeAtPath([0])!;
        expect(table.type, equals(SimpleTableBlockKeys.type));
        expect(table.rowLength, equals(2));
        expect(table.columnLength, equals(4));
      }

      // insert above and insert below
      {
        // focus on the first cell
        unawaited(
          editorState.updateSelectionWithReason(
            Selection.collapsed(Position(path: firstParagraphPath)),
            reason: SelectionUpdateReason.uiEvent,
          ),
        );
        await tester.pumpAndSettle();

        // click the row menu button
        await tester.clickRowMenuButton(0);

        await tester.tapButton(
          find.findTextInFlowyText(
            LocaleKeys.document_plugins_simpleTable_moreActions_insertAbove
                .tr(),
          ),
        );
        await tester.tapButton(
          find.findTextInFlowyText(
            LocaleKeys.document_plugins_simpleTable_moreActions_insertBelow
                .tr(),
          ),
        );
        // click empty area to cancel the selection
        await tester.tapAt(Offset.zero);
        expect(editorState.selection, isNull);
        await tester.pumpUntilNotFound(find.byType(SimpleTableCellBottomSheet));

        // check the table is updated
        final table = editorState.getNodeAtPath([0])!;
        expect(table.rowLength, equals(4));
        expect(table.columnLength, equals(4));
      }

      // delete the first row
      {
        // focus on the first cell
        unawaited(
          editorState.updateSelectionWithReason(
            Selection.collapsed(Position(path: firstParagraphPath)),
            reason: SelectionUpdateReason.uiEvent,
          ),
        );
        await tester.pumpAndSettle();

        // delete the first row
        await tester.clickRowMenuButton(0);
        await tester.tapButton(
          find.findTextInFlowyText(
            LocaleKeys.document_plugins_simpleTable_moreActions_delete.tr(),
          ),
        );
        await tester.pumpUntilNotFound(find.byType(SimpleTableCellBottomSheet));

        // check the table is updated
        final table = editorState.getNodeAtPath([0])!;
        expect(table.rowLength, equals(3));
        expect(table.columnLength, equals(4));
      }

      // delete the first column
      {
        unawaited(
          editorState.updateSelectionWithReason(
            Selection.collapsed(Position(path: firstParagraphPath)),
            reason: SelectionUpdateReason.uiEvent,
          ),
        );
        await tester.pumpAndSettle();

        await tester.clickColumnMenuButton(0);
        await tester.tapButton(
          find.findTextInFlowyText(
            LocaleKeys.document_plugins_simpleTable_moreActions_delete.tr(),
          ),
        );
        await tester.pumpUntilNotFound(find.byType(SimpleTableCellBottomSheet));

        // check the table is updated
        final table = editorState.getNodeAtPath([0])!;
        expect(table.rowLength, equals(3));
        expect(table.columnLength, equals(3));
      }
    });
  });
}
