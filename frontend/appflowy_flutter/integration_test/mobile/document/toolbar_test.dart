import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet_edit_link_widget.dart';
import 'package:appflowy/mobile/presentation/editor/mobile_editor_screen.dart';
import 'package:appflowy/mobile/presentation/mobile_bottom_navigation_bar.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> createNeaPage(WidgetTester tester) async {
    final createPageButton =
        find.byKey(BottomNavigationBarItemType.add.valueKey);
    await tester.tapButton(createPageButton);
    expect(find.byType(MobileDocumentScreen), findsOneWidget);
    final editor = find.byType(AppFlowyEditor);
    expect(editor, findsOneWidget);
  }

  const testLink = 'https://appflowy.io/';

  group('links', () {
    testWidgets('insert links', (tester) async {
      await tester.launchInAnonymousMode();

      await createNeaPage(tester);
      await tester.editor.tapLineOfEditorAt(0);
      final editorState = tester.editor.getCurrentEditorState();

      /// insert two lines of text
      const strFirst = 'FirstLine', strSecond = 'SecondLine';
      await tester.ime.insertText(strFirst);
      await editorState.insertNewLine();
      await tester.ime.insertText(strSecond);
      final firstLine = find.text(strFirst, findRichText: true),
          secondLine = find.text(strSecond, findRichText: true);
      expect(firstLine, findsOneWidget);
      expect(secondLine, findsOneWidget);

      /// select the first line
      await tester.doubleTapAt(tester.getCenter(firstLine));
      await tester.pumpAndSettle();

      /// find link button and tap it
      final linkButton = find.byFlowySvg(FlowySvgs.toolbar_link_m);
      await tester.tapButton(linkButton);

      /// input the link
      final textFormField = find.byType(TextFormField);
      expect(textFormField, findsNWidgets(2));
      final linkField = textFormField.last;
      await tester.enterText(linkField, testLink);
      await tester.pumpAndSettle();
      await tester.tapButton(find.byFlowySvg(FlowySvgs.toolbar_link_earth_m));

      /// apply the link
      await tester.tapButton(find.text(LocaleKeys.button_done.tr()));

      /// do it again
      /// select the second line
      await tester.doubleTapAt(tester.getCenter(secondLine));
      await tester.pumpAndSettle();
      await tester.tapButton(linkButton);
      await tester.enterText(linkField, testLink);
      await tester.pumpAndSettle();
      await tester.tapButton(find.byFlowySvg(FlowySvgs.toolbar_link_earth_m));
      await tester.tapButton(find.text(LocaleKeys.button_done.tr()));

      final firstNode = editorState.getNodeAtPath([0]);
      final secondNode = editorState.getNodeAtPath([1]);

      Map commonDeltaJson(String insert) => {
            'insert': insert,
            'attributes': {'href': testLink, 'is_page_link': false},
          };

      expect(
        firstNode?.delta?.toJson(),
        [commonDeltaJson(strFirst)],
      );
      expect(
        secondNode?.delta?.toJson(),
        [commonDeltaJson(strSecond)],
      );
    });

    testWidgets('change a link', (tester) async {
      await tester.launchInAnonymousMode();

      await createNeaPage(tester);
      await tester.editor.tapLineOfEditorAt(0);
      final editorState = tester.editor.getCurrentEditorState();
      const testText = 'TestText';
      await tester.ime.insertText(testText);
      final textFinder = find.text(testText, findRichText: true);

      /// select the first line
      await tester.doubleTapAt(tester.getCenter(textFinder));
      await tester.pumpAndSettle();

      /// find link button and tap it
      final linkButton = find.byFlowySvg(FlowySvgs.toolbar_link_m);
      await tester.tapButton(linkButton);

      /// input the link
      final textFormField = find.byType(TextFormField);
      expect(textFormField, findsNWidgets(2));
      final linkField = textFormField.last;
      await tester.enterText(linkField, testLink);
      await tester.pumpAndSettle();
      await tester.tapButton(find.byFlowySvg(FlowySvgs.toolbar_link_earth_m));

      /// apply the link
      await tester.tapButton(find.text(LocaleKeys.button_done.tr()));

      /// show edit link menu
      await tester.longPress(textFinder);
      await tester.pumpAndSettle();
      final linkEditMenu = find.byType(MobileBottomSheetEditLinkWidget);
      expect(linkEditMenu, findsOneWidget);

      /// remove the link
      await tester.tapButton(find.byFlowySvg(FlowySvgs.toolbar_link_unlink_m));
      final node = editorState.getNodeAtPath([0]);
      expect(
        node?.delta?.toJson(),
        [
          {'insert': testText},
        ],
      );
    });
  });
}
