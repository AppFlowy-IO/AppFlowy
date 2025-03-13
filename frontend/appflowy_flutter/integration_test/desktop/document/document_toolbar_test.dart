import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/toolbar_item/more_option_toolbar_item.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/toolbar_item/text_suggestions_toolbar_item.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> selectText(WidgetTester tester, String text) async {
    await tester.editor.updateSelection(
      Selection.single(
        path: [0],
        startOffset: 0,
        endOffset: text.length,
      ),
    );
  }

  Future<void> prepareForToolbar(WidgetTester tester, String text) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();

    await tester.createNewPageWithNameUnderParent();

    await tester.editor.tapLineOfEditorAt(0);
    await tester.ime.insertText(text);
    await selectText(tester, text);
  }

  group('document toolbar:', () {
    testWidgets('font family', (tester) async {
      await prepareForToolbar(tester, 'font family');

      // tap more options button
      await tester.tapButtonWithFlowySvgData(FlowySvgs.toolbar_more_m);
      // tap the font family button
      final fontFamilyButton = find.byKey(kFontFamilyToolbarItemKey);
      await tester.tapButton(fontFamilyButton);

      // expect to see the font family dropdown immediately
      expect(find.byType(FontFamilyDropDown), findsOneWidget);

      // click the font family 'Abel'
      const abel = 'Abel';
      await tester.tapButton(find.text(abel));

      // check the text is updated to 'Abel'
      final editorState = tester.editor.getCurrentEditorState();
      expect(
        editorState.getDeltaAttributeValueInSelection(
          AppFlowyRichTextKeys.fontFamily,
        ),
        abel,
      );
    });

    testWidgets('heading 1~3', (tester) async {
      const text = 'heading';
      await prepareForToolbar(tester, text);

      Future<void> testChangeHeading(
        FlowySvgData svg,
        String title,
        int level,
      ) async {
        /// tap suggestions item
        final suggestionsButton = find.byKey(kSuggestionsItemKey);
        await tester.tapButton(suggestionsButton);

        /// tap item
        await tester.ensureVisible(find.byFlowySvg(svg));
        await tester.tapButton(find.byFlowySvg(svg));

        /// check the type of node is [HeadingBlockKeys.type]
        await selectText(tester, text);
        final editorState = tester.editor.getCurrentEditorState();
        final selection = editorState.selection!;
        final node = editorState.getNodeAtPath(selection.start.path)!,
            nodeLevel = node.attributes[HeadingBlockKeys.level]!;
        expect(node.type, HeadingBlockKeys.type);
        expect(nodeLevel, level);

        /// show toolbar again
        await selectText(tester, text);

        /// the text of suggestions item should be changed
        expect(
          find.descendant(of: suggestionsButton, matching: find.text(title)),
          findsOneWidget,
        );
      }

      await testChangeHeading(
        FlowySvgs.type_h1_m,
        LocaleKeys.document_toolbar_h1.tr(),
        1,
      );

      await testChangeHeading(
        FlowySvgs.type_h2_m,
        LocaleKeys.document_toolbar_h2.tr(),
        2,
      );
      await testChangeHeading(
        FlowySvgs.type_h3_m,
        LocaleKeys.document_toolbar_h3.tr(),
        3,
      );
    });

    testWidgets('toggle 1~3', (tester) async {
      const text = 'toggle';
      await prepareForToolbar(tester, text);

      Future<void> testChangeToggle(
        FlowySvgData svg,
        String title,
        int? level,
      ) async {
        /// tap suggestions item
        final suggestionsButton = find.byKey(kSuggestionsItemKey);
        await tester.tapButton(suggestionsButton);

        /// tap item
        await tester.ensureVisible(find.byFlowySvg(svg));
        await tester.tapButton(find.byFlowySvg(svg));

        /// check the type of node is [HeadingBlockKeys.type]
        await selectText(tester, text);
        final editorState = tester.editor.getCurrentEditorState();
        final selection = editorState.selection!;
        final node = editorState.getNodeAtPath(selection.start.path)!,
            nodeLevel = node.attributes[ToggleListBlockKeys.level];
        expect(node.type, ToggleListBlockKeys.type);
        expect(nodeLevel, level);

        /// show toolbar again
        await selectText(tester, text);

        /// the text of suggestions item should be changed
        expect(
          find.descendant(of: suggestionsButton, matching: find.text(title)),
          findsOneWidget,
        );
      }

      await testChangeToggle(
        FlowySvgs.type_toggle_list_m,
        LocaleKeys.editor_toggleListShortForm.tr(),
        null,
      );

      await testChangeToggle(
        FlowySvgs.type_toggle_h1_m,
        LocaleKeys.editor_toggleHeading1ShortForm.tr(),
        1,
      );

      await testChangeToggle(
        FlowySvgs.type_toggle_h2_m,
        LocaleKeys.editor_toggleHeading2ShortForm.tr(),
        2,
      );

      await testChangeToggle(
        FlowySvgs.type_toggle_h3_m,
        LocaleKeys.editor_toggleHeading3ShortForm.tr(),
        3,
      );
    });
  });
}
