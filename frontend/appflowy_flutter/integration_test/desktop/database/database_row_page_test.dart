import 'package:appflowy/plugins/database/widgets/cell/desktop_row_detail/desktop_row_detail_checklist_cell.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/checklist_cell_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/header/desktop_field_cell.dart';
import 'package:appflowy/plugins/database/widgets/row/row_detail.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/database_test_op.dart';
import '../../shared/emoji.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('grid row detail page:', () {
    testWidgets('opens', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // Create a new grid
      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      // Hover first row and then open the row page
      await tester.openFirstRowDetailPage();

      // Make sure that the row page is opened
      tester.assertRowDetailPageOpened();

      // Each row detail page should have a document
      await tester.assertDocumentExistInRowDetailPage();
    });

    testWidgets('add and update emoji', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // Create a new grid
      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      // Hover first row and then open the row page
      await tester.openFirstRowDetailPage();
      await tester.hoverRowBanner();
      await tester.openEmojiPicker();
      await tester.tapEmoji('😀');

      // expect to find the emoji selected
      final firstEmojiFinder = find.byWidgetPredicate(
        (w) => w is FlowyText && w.text == '😀',
      );

      // There are 2 eomjis - one in the row banner and another in the primary cell
      expect(firstEmojiFinder, findsNWidgets(2));

      // Update existing selected emoji - tap on it to update
      await tester.tapButton(find.byType(EmojiIconWidget));
      await tester.pumpAndSettle();

      await tester.tapEmoji('😅');

      // The emoji already displayed in the row banner
      final emojiText = find.byWidgetPredicate(
        (widget) => widget is FlowyText && widget.text == '😅',
      );

      // The number of emoji should be two. One in the row displayed in the grid
      // one in the row detail page.
      expect(emojiText, findsNWidgets(2));
    });

    testWidgets('remove emoji', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // Create a new grid
      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      // Hover first row and then open the row page
      await tester.openFirstRowDetailPage();
      await tester.hoverRowBanner();
      await tester.openEmojiPicker();
      await tester.tapEmoji('😀');

      // Remove the emoji
      await tester.tapButton(find.byType(EmojiIconWidget));
      await tester.tapButton(find.text(LocaleKeys.button_remove.tr()));

      final emojiText = find.byWidgetPredicate(
        (widget) => widget is FlowyText && widget.text == '😀',
      );
      expect(emojiText, findsNothing);
    });

    testWidgets('create list of fields', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // Create a new grid
      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

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

        // Open the type option menu
        await tester.tapSwitchFieldTypeButton();

        await tester.selectFieldType(fieldType);

        final field = find.descendant(
          of: find.byType(RowDetailPage),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is FieldCellButton &&
                widget.field.name == fieldType.i18n,
          ),
        );
        expect(field, findsOneWidget);

        // After update the field type, the cells should be updated
        tester.findCellByFieldType(fieldType);
        await tester.scrollRowDetailByOffset(const Offset(0, -50));
      }
    });

    testWidgets('change order of fields and cells', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // Create a new grid
      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      // Hover first row and then open the row page
      await tester.openFirstRowDetailPage();

      // Assert that the first field in the row details page is the select
      // option type
      tester.assertFirstFieldInRowDetailByType(FieldType.SingleSelect);

      // Reorder first field in list
      final gesture = await tester.hoverOnFieldInRowDetail(index: 0);
      await tester.pumpAndSettle();
      await tester.reorderFieldInRowDetail(offset: 30);

      // Orders changed, now the checkbox is first
      tester.assertFirstFieldInRowDetailByType(FieldType.Checkbox);
      await gesture.removePointer();
      await tester.pumpAndSettle();

      // Reorder second field in list
      await tester.hoverOnFieldInRowDetail(index: 1);
      await tester.pumpAndSettle();
      await tester.reorderFieldInRowDetail(offset: -30);

      // First field is now back to select option
      tester.assertFirstFieldInRowDetailByType(FieldType.SingleSelect);
    });

    testWidgets('hide and show hidden fields', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // Create a new grid
      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      // Hover first row and then open the row page
      await tester.openFirstRowDetailPage();

      // Assert that the show hidden fields button isn't visible
      tester.assertToggleShowHiddenFieldsVisibility(false);

      // Hide the first field in the field list
      await tester.tapGridFieldWithNameInRowDetailPage("Type");
      await tester.tapHidePropertyButtonInFieldEditor();

      // Assert that the field is now hidden
      tester.noFieldWithName("Type");

      // Assert that the show hidden fields button appears
      tester.assertToggleShowHiddenFieldsVisibility(true);

      // Click on the show hidden fields button
      await tester.toggleShowHiddenFields();

      // Assert that the hidden field is shown again and that the show
      // hidden fields button is still present
      tester.findFieldWithName("Type");
      tester.assertToggleShowHiddenFieldsVisibility(true);

      // Click hide hidden fields
      await tester.toggleShowHiddenFields();

      // Assert that the hidden field has vanished
      tester.noFieldWithName("Type");

      // Click show hidden fields
      await tester.toggleShowHiddenFields();

      // delete the hidden field
      await tester.tapGridFieldWithNameInRowDetailPage("Type");
      await tester.tapDeletePropertyInFieldEditor();

      // Assert that the that the show hidden fields button is gone
      tester.assertToggleShowHiddenFieldsVisibility(false);
    });

    testWidgets('update the contents of the document and re-open it',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // Create a new grid
      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      // Hover first row and then open the row page
      await tester.openFirstRowDetailPage();

      // Wait for the document to be loaded
      await tester.wait(500);

      // Focus on the editor
      final textBlock = find.byType(ParagraphBlockComponentWidget);
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
      await tester.tapAnonymousSignInButton();

      // Create a new grid
      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

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

    testWidgets('delete row', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // Create a new grid
      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      // Hover first row and then open the row page
      await tester.openFirstRowDetailPage();

      await tester.tapRowDetailPageRowActionButton();
      await tester.tapRowDetailPageDeleteRowButton();
      await tester.tapEscButton();

      tester.assertNumberOfRowsInGridPage(2);
    });

    testWidgets('duplicate row', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // Create a new grid
      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      // Hover first row and then open the row page
      await tester.openFirstRowDetailPage();

      await tester.tapRowDetailPageRowActionButton();
      await tester.tapRowDetailPageDuplicateRowButton();
      await tester.tapEscButton();

      tester.assertNumberOfRowsInGridPage(4);
    });

    testWidgets('edit checklist cell', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      const fieldType = FieldType.Checklist;
      await tester.createField(fieldType);

      await tester.openFirstRowDetailPage();
      await tester.hoverOnWidget(
        find.byType(ChecklistRowDetailCell),
        onHover: () async {
          await tester.tapButton(find.byType(ChecklistItemControl));
        },
      );

      tester.assertPhantomChecklistItemAtIndex(index: 0);
      await tester.enterText(find.byType(PhantomChecklistItem), 'task 1');
      await tester.pumpAndSettle();
      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      tester.assertChecklistTaskInEditor(
        index: 0,
        name: "task 1",
        isChecked: false,
      );
      tester.assertPhantomChecklistItemAtIndex(index: 1);

      await tester.enterText(find.byType(PhantomChecklistItem), 'task 2');
      await tester.pumpAndSettle();
      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      tester.assertChecklistTaskInEditor(
        index: 1,
        name: "task 2",
        isChecked: false,
      );
      tester.assertPhantomChecklistItemAtIndex(index: 2);

      await tester.simulateKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(PhantomChecklistItem), findsNothing);

      await tester.renameChecklistTask(index: 0, name: "task -1", enter: false);
      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);

      tester.assertChecklistTaskInEditor(
        index: 0,
        name: "task -1",
        isChecked: false,
      );
      tester.assertPhantomChecklistItemAtIndex(index: 1);

      await tester.enterText(find.byType(PhantomChecklistItem), 'task 0');
      await tester.pumpAndSettle();
      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      tester.assertPhantomChecklistItemAtIndex(index: 2);

      await tester.checkChecklistTask(index: 1);
      expect(find.byType(PhantomChecklistItem), findsNothing);
      expect(find.byType(ChecklistItem), findsNWidgets(3));

      tester.assertChecklistTaskInEditor(
        index: 0,
        name: "task -1",
        isChecked: false,
      );
      tester.assertChecklistTaskInEditor(
        index: 1,
        name: "task 0",
        isChecked: true,
      );
      tester.assertChecklistTaskInEditor(
        index: 2,
        name: "task 2",
        isChecked: false,
      );

      await tester.tapButton(
        find.descendant(
          of: find.byType(ProgressAndHideCompleteButton),
          matching: find.byType(FlowyIconButton),
        ),
      );
      expect(find.byType(ChecklistItem), findsNWidgets(2));

      tester.assertChecklistTaskInEditor(
        index: 0,
        name: "task -1",
        isChecked: false,
      );
      tester.assertChecklistTaskInEditor(
        index: 1,
        name: "task 2",
        isChecked: false,
      );

      await tester.renameChecklistTask(index: 1, name: "task 3", enter: false);
      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);

      await tester.renameChecklistTask(index: 0, name: "task 1", enter: false);
      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);

      await tester.enterText(find.byType(PhantomChecklistItem), 'task 2');
      await tester.pumpAndSettle();
      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      tester.assertChecklistTaskInEditor(
        index: 0,
        name: "task 1",
        isChecked: false,
      );
      tester.assertChecklistTaskInEditor(
        index: 1,
        name: "task 2",
        isChecked: false,
      );
      tester.assertChecklistTaskInEditor(
        index: 2,
        name: "task 3",
        isChecked: false,
      );
      tester.assertPhantomChecklistItemAtIndex(index: 2);

      await tester.checkChecklistTask(index: 1);
      expect(find.byType(ChecklistItem), findsNWidgets(2));
    });
  });
}
