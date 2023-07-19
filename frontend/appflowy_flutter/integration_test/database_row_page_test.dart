import 'package:appflowy/plugins/database_view/widgets/row/row_banner.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'util/database_test_op.dart';
import 'util/emoji.dart';
import 'util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('grid', () {
    testWidgets('row details page opens', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // Create a new grid
      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      // Hover first row and then open the row page
      await tester.openFirstRowDetailPage();

      // Make sure that the row page is opened
      tester.assertRowDetailPageOpened();
    });

    testWidgets('insert emoji in the row detail page', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // Create a new grid
      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      // Hover first row and then open the row page
      await tester.openFirstRowDetailPage();

      await tester.hoverRowBanner();

      await tester.openEmojiPicker();
      await tester.switchToEmojiList();
      await tester.tapEmoji('😀');

      // After select the emoji, the EmojiButton will show up
      await tester.tapButton(find.byType(EmojiButton));
    });

    testWidgets('update emoji in the row detail page', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // Create a new grid
      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      // Hover first row and then open the row page
      await tester.openFirstRowDetailPage();
      await tester.hoverRowBanner();
      await tester.openEmojiPicker();
      await tester.switchToEmojiList();
      await tester.tapEmoji('😀');

      // Update existing selected emoji
      await tester.tapButton(find.byType(EmojiButton));
      await tester.switchToEmojiList();
      await tester.tapEmoji('😅');

      // The emoji already displayed in the row banner
      final emojiText = find.byWidgetPredicate(
        (widget) => widget is FlowyText && widget.text == '😅',
      );

      // The number of emoji should be two. One in the row displayed in the grid
      // one in the row detail page.
      expect(emojiText, findsNWidgets(2));
    });

    testWidgets('remove emoji in the row detail page', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // Create a new grid
      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      // Hover first row and then open the row page
      await tester.openFirstRowDetailPage();
      await tester.hoverRowBanner();
      await tester.openEmojiPicker();
      await tester.switchToEmojiList();
      await tester.tapEmoji('😀');

      // Remove the emoji
      await tester.tapButton(find.byType(RemoveEmojiButton));
      final emojiText = find.byWidgetPredicate(
        (widget) => widget is FlowyText && widget.text == '😀',
      );
      expect(emojiText, findsNothing);
    });

    testWidgets('create list of fields in row detail page', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // Create a new grid
      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      // Hover first row and then open the row page
      await tester.openFirstRowDetailPage();

      for (final fieldType in [
        FieldType.Checklist,
        FieldType.DateTime,
        FieldType.Number,
        FieldType.URL,
        FieldType.MultiSelect,
        FieldType.LastEditedTime,
        FieldType.CreatedTime,
        FieldType.Checkbox,
      ]) {
        await tester.tapRowDetailPageCreatePropertyButton();
        await tester.renameField(fieldType.name);

        // Open the type option menu
        await tester.tapTypeOptionButton();

        await tester.selectFieldType(fieldType);
        await tester.dismissFieldEditor();

        // After update the field type, the cells should be updated
        await tester.findCellByFieldType(fieldType);
        await tester.scrollRowDetailByOffset(const Offset(0, -50));
      }
    });

    testWidgets('check document is exist in row detail page', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // Create a new grid
      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      // Hover first row and then open the row page
      await tester.openFirstRowDetailPage();

      // Each row detail page should have a document
      await tester.assertDocumentExistInRowDetailPage();
    });

    testWidgets('update the content of the document and re-open it',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // Create a new grid
      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      // Hover first row and then open the row page
      await tester.openFirstRowDetailPage();

      // Wait for the document to be loaded
      await tester.wait(500);

      // Focus on the editor
      final textBlock = find.byType(TextBlockComponentWidget);
      await tester.tapAt(tester.getCenter(textBlock));
      await tester.pumpAndSettle();

      // Input some text
      const inputText = 'Hello World';
      await tester.ime.insertText(inputText);
      expect(
        find.textContaining(inputText, findRichText: true),
        findsOneWidget,
      );

      // Tap outside to dismiss the field
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      // Re-open the document
      await tester.openFirstRowDetailPage();
      expect(
        find.textContaining(inputText, findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets(
        'check if the title wraps properly when a long text is inserted',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // Create a new grid
      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      // Hover first row and then open the row page
      await tester.openFirstRowDetailPage();

      // Wait for the document to be loaded
      await tester.wait(500);

      // Focus on the editor
      final textField = find
          .descendant(
            of: find.byType(SimpleDialog),
            matching: find.byType(TextField),
          )
          .first;

      // Input a long text
      await tester.enterText(textField, 'Long text' * 25);
      await tester.pumpAndSettle();

      // Tap outside to dismiss the field
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      // Check if there is any overflow in the widget tree
      expect(tester.takeException(), isNull);

      // Re-open the document
      await tester.openFirstRowDetailPage();

      // Check again if there is any overflow in the widget tree
      expect(tester.takeException(), isNull);
    });

    testWidgets('delete row in row detail page', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // Create a new grid
      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      // Hover first row and then open the row page
      await tester.openFirstRowDetailPage();

      await tester.tapRowDetailPageDeleteRowButton();
      await tester.tapEscButton();

      await tester.assertNumberOfRowsInGridPage(2);
    });

    testWidgets('duplicate row in row detail page', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // Create a new grid
      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      // Hover first row and then open the row page
      await tester.openFirstRowDetailPage();

      await tester.tapRowDetailPageDuplicateRowButton();
      await tester.tapEscButton();

      await tester.assertNumberOfRowsInGridPage(4);
    });
  });
}
