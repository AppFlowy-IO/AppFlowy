import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy/workspace/presentation/widgets/more_view_actions/widgets/view_meta_info.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('MoreViewActions', () {
    testWidgets('can duplicate and delete from menu', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.pumpAndSettle();

      final pageFinder = find.byType(ViewItem);
      expect(pageFinder, findsNWidgets(1));

      // Duplicate
      await tester.openMoreViewActions();
      await tester.duplicateByMoreViewActions();
      await tester.pumpAndSettle();

      expect(pageFinder, findsNWidgets(2));

      // Delete
      await tester.openMoreViewActions();
      await tester.deleteByMoreViewActions();
      await tester.pumpAndSettle();

      expect(pageFinder, findsNWidgets(1));
    });
  });

  testWidgets('count title towards word count', (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();
    await tester.createNewPageWithNameUnderParent();

    Finder title = tester.editor.findDocumentTitle('');

    await tester.openMoreViewActions();
    final viewMetaInfo = find.byType(ViewMetaInfo);
    expect(viewMetaInfo, findsOneWidget);

    ViewMetaInfo viewMetaInfoWidget =
        viewMetaInfo.evaluate().first.widget as ViewMetaInfo;
    Counters titleCounter = viewMetaInfoWidget.titleCounters!;

    expect(titleCounter.charCount, 0);
    expect(titleCounter.wordCount, 0);

    /// input [str1] within title
    const str1 = 'Hello',
        str2 = '$str1 AppFlowy',
        str3 = '$str2!',
        str4 = 'Hello world';
    await tester.simulateKeyEvent(LogicalKeyboardKey.escape);
    await tester.tapButton(title);
    await tester.enterText(title, str1);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.openMoreViewActions();
    viewMetaInfoWidget = viewMetaInfo.evaluate().first.widget as ViewMetaInfo;
    titleCounter = viewMetaInfoWidget.titleCounters!;
    expect(titleCounter.charCount, str1.length);
    expect(titleCounter.wordCount, 1);

    /// input [str2] within title
    title = tester.editor.findDocumentTitle(str1);
    await tester.simulateKeyEvent(LogicalKeyboardKey.escape);
    await tester.tapButton(title);
    await tester.enterText(title, str2);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.openMoreViewActions();
    viewMetaInfoWidget = viewMetaInfo.evaluate().first.widget as ViewMetaInfo;
    titleCounter = viewMetaInfoWidget.titleCounters!;
    expect(titleCounter.charCount, str2.length);
    expect(titleCounter.wordCount, 2);

    /// input [str3] within title
    title = tester.editor.findDocumentTitle(str2);
    await tester.simulateKeyEvent(LogicalKeyboardKey.escape);
    await tester.tapButton(title);
    await tester.enterText(title, str3);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.openMoreViewActions();
    viewMetaInfoWidget = viewMetaInfo.evaluate().first.widget as ViewMetaInfo;
    titleCounter = viewMetaInfoWidget.titleCounters!;
    expect(titleCounter.charCount, str3.length);
    expect(titleCounter.wordCount, 2);

    /// input [str4] within document
    await tester.simulateKeyEvent(LogicalKeyboardKey.escape);
    await tester.editor
        .updateSelection(Selection.collapsed(Position(path: [0])));
    await tester.pumpAndSettle();
    await tester.editor
        .getCurrentEditorState()
        .insertTextAtCurrentSelection(str4);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.openMoreViewActions();
    final texts =
        find.descendant(of: viewMetaInfo, matching: find.byType(FlowyText));
    expect(texts, findsNWidgets(3));
    viewMetaInfoWidget = viewMetaInfo.evaluate().first.widget as ViewMetaInfo;
    titleCounter = viewMetaInfoWidget.titleCounters!;
    final Counters documentCounters = viewMetaInfoWidget.documentCounters!;
    final wordCounter = texts.evaluate().elementAt(0).widget as FlowyText,
        charCounter = texts.evaluate().elementAt(1).widget as FlowyText;
    final numberFormat = NumberFormat();
    expect(
      wordCounter.text,
      LocaleKeys.moreAction_wordCount.tr(
        args: [
          numberFormat
              .format(titleCounter.wordCount + documentCounters.wordCount)
              .toString(),
        ],
      ),
    );
    expect(
      charCounter.text,
      LocaleKeys.moreAction_charCount.tr(
        args: [
          numberFormat
              .format(
                titleCounter.charCount + documentCounters.charCount,
              )
              .toString(),
        ],
      ),
    );
  });
}
