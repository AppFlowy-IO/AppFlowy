import 'package:appflowy/plugins/database_view/widgets/row/row_banner.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('grid', () {
    const location = 'appflowy';

    setUp(() async {
      await TestFolder.cleanTestLocation(location);
      await TestFolder.setTestLocation(location);
    });

    tearDown(() async {
      await TestFolder.cleanTestLocation(location);
    });

    tearDownAll(() async {
      await TestFolder.cleanTestLocation(null);
    });

    testWidgets('open first row of the grid', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // Create a new grid
      await tester.tapAddButton();
      await tester.tapCreateGridButton();
      await tester.pumpAndSettle();

      // Hover first row and then open the row page
      await tester.openFirstRowDetailPage();
      await tester.pumpAndSettle();
    });

    testWidgets('insert emoji in the row detail page', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // Create a new grid
      await tester.tapAddButton();
      await tester.tapCreateGridButton();
      await tester.pumpAndSettle();

      // Hover first row and then open the row page
      await tester.openFirstRowDetailPage();

      await tester.hoverRowBanner();

      await tester.openEmojiPicker();
      await tester.switchToEmojiList();
      await tester.tapEmoji('😀');

      // After select the emoji, the EmojiButton will show up
      await tester.tapButton(find.byType(EmojiButton));

      await tester.pumpAndSettle();
    });

    testWidgets('update emoji in the row detail page', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // Create a new grid
      await tester.tapAddButton();
      await tester.tapCreateGridButton();
      await tester.pumpAndSettle();

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
        (widget) => widget is FlowyText && widget.title == '😅',
      );

      // The number of emoji should be two. One in the row displayed in the grid
      // one in the row detail page.
      expect(emojiText, findsNWidgets(2));
      await tester.pumpAndSettle();
    });

    testWidgets('remove emoji in the row detail page', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // Create a new grid
      await tester.tapAddButton();
      await tester.tapCreateGridButton();
      await tester.pumpAndSettle();

      // Hover first row and then open the row page
      await tester.openFirstRowDetailPage();
      await tester.hoverRowBanner();
      await tester.openEmojiPicker();
      await tester.switchToEmojiList();
      await tester.tapEmoji('😀');

      // Remove the emoji
      await tester.tapButton(find.byType(RemoveEmojiButton));
      final emojiText = find.byWidgetPredicate(
        (widget) => widget is FlowyText && widget.title == '😀',
      );
      expect(emojiText, findsNothing);
    });

    testWidgets('create list of fields in row detail page', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // Create a new grid
      await tester.tapAddButton();
      await tester.tapCreateGridButton();
      await tester.pumpAndSettle();

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
        await tester.pumpAndSettle();
      }
    });

    testWidgets('check document is exist in row detail page', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // Create a new grid
      await tester.tapAddButton();
      await tester.tapCreateGridButton();
      await tester.pumpAndSettle();

      // Hover first row and then open the row page
      await tester.openFirstRowDetailPage();

      // Each row detail page should have a document
      await tester.assertDocumentExistInRowDetailPage();

      await tester.pumpAndSettle();
    });
  });
}
