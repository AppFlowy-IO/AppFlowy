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
        tester.state<SimpleTableCellBlockWidgetState>(firstCell).isEditing,
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
