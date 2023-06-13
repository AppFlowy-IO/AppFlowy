import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/widgets/row/row_banner.dart';
import 'package:easy_localization/easy_localization.dart';
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

    testWidgets('create a new grid when launching app in first time',
        (tester) async {
      await tester.initializeAppFlowy();

      await tester.tapGoButton();

      // create a new grid
      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      // expect to see a new grid
      tester.expectToSeePageName(
        LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
      );

      await tester.pumpAndSettle();
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
  });
}
