import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar_actions.dart';
import 'package:appflowy/mobile/presentation/home/setting/settings_popup_menu.dart';
import 'package:appflowy/mobile/presentation/mobile_bottom_navigation_bar.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_option_tile.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Change default text direction', (tester) async {
    await tester.launchInAnonymousMode();

    /// tap [Setting] button
    await tester.tapButton(find.byType(HomePageSettingsPopupMenu));
    await tester
        .tapButton(find.text(LocaleKeys.settings_popupMenuItem_settings.tr()));

    /// tap [Default Text Direction]
    await tester.tapButton(
      find.text(LocaleKeys.settings_appearance_textDirection_label.tr()),
    );

    /// there are 3 items: LTR-RTL-AUTO
    final bottomSheet = find.ancestor(
      of: find.byType(FlowyOptionTile),
      matching: find.byType(SafeArea),
    );
    final items = find.descendant(
      of: bottomSheet,
      matching: find.byType(FlowyOptionTile),
    );
    expect(items, findsNWidgets(3));

    /// select [Auto]
    await tester.tapButton(items.last);
    expect(
      find.text(LocaleKeys.settings_appearance_textDirection_auto.tr()),
      findsOneWidget,
    );

    /// go back home
    await tester.tapButton(find.byType(AppBarImmersiveBackButton));

    /// create new page
    final createPageButton =
        find.byKey(BottomNavigationBarItemType.add.valueKey);
    await tester.tapButton(createPageButton);

    final editorState = tester.editor.getCurrentEditorState();
    // focus on the editor
    await tester.editor.tapLineOfEditorAt(0);

    const testEnglish = 'English', testArabic = 'إنجليزي';

    /// insert [testEnglish]
    await editorState.insertTextAtCurrentSelection(testEnglish);
    await tester.pumpAndSettle();
    await editorState.insertNewLine(position: editorState.selection!.end);
    await tester.pumpAndSettle();

    /// insert [testArabic]
    await editorState.insertTextAtCurrentSelection(testArabic);
    await tester.pumpAndSettle();
    final testEnglishFinder = find.text(testEnglish, findRichText: true),
        testArabicFinder = find.text(testArabic, findRichText: true);
    final testEnglishRenderBox =
            testEnglishFinder.evaluate().first.renderObject as RenderBox,
        testArabicRenderBox =
            testArabicFinder.evaluate().first.renderObject as RenderBox;
    final englishPosition = testEnglishRenderBox.localToGlobal(Offset.zero),
        arabicPosition = testArabicRenderBox.localToGlobal(Offset.zero);
    expect(englishPosition.dx > arabicPosition.dx, true);
  });
}
