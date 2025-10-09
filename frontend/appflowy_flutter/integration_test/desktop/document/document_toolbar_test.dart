import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/desktop_floating_toolbar.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/link/link_create_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/link/link_edit_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/link/link_hover_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/toolbar_item/custom_link_toolbar_item.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/toolbar_item/more_option_toolbar_item.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/toolbar_item/text_suggestions_toolbar_item.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    testWidgets('toolbar will not rebuild after click item', (tester) async {
      const text = 'Test rebuilding';
      await prepareForToolbar(tester, text);
      Finder toolbar = find.byType(DesktopFloatingToolbar);
      Element toolbarElement = toolbar.evaluate().first;
      final elementHashcode = toolbarElement.hashCode;
      final boldButton = find.byFlowySvg(FlowySvgs.toolbar_bold_m),
          underlineButton = find.byFlowySvg(FlowySvgs.toolbar_underline_m),
          italicButton = find.byFlowySvg(FlowySvgs.toolbar_inline_italic_m);
      /// tap format buttons
      await tester.tapButton(boldButton);
      await tester.tapButton(underlineButton);
      await tester.tapButton(italicButton);
      toolbar = find.byType(DesktopFloatingToolbar);
      toolbarElement = toolbar.evaluate().first;
      /// check if the toolbar is not rebuilt
      expect(elementHashcode, toolbarElement.hashCode);
      final editorState = tester.editor.getCurrentEditorState();
      /// check text formats
      expect(
        editorState
            .getDeltaAttributeValueInSelection(AppFlowyRichTextKeys.bold),
        true,
      );
      expect(
        editorState
            .getDeltaAttributeValueInSelection(AppFlowyRichTextKeys.italic),
        true,
      );
      expect(
        editorState
            .getDeltaAttributeValueInSelection(AppFlowyRichTextKeys.underline),
        true,
      );
    });
  });
  group('document toolbar: link', () {
    String? getLinkFromNode(Node node) {
      for (final insert in node.delta!) {
        final link = insert.attributes?.href;
        if (link != null) return link;
      }
      return null;
    }
    bool isPageLink(Node node) {
      for (final insert in node.delta!) {
        final isPage = insert.attributes?.isPage;
        if (isPage == true) return true;
      }
      return false;
    }
    String getNodeText(Node node) {
      for (final insert in node.delta!) {
        if (insert is TextInsert) return insert.text;
      }
      return '';
    }
    testWidgets('insert link and remove link', (tester) async {
      const text = 'insert link', link = 'https://test.appflowy.cloud';
      await prepareForToolbar(tester, text);
      final toolbar = find.byType(DesktopFloatingToolbar);
      expect(toolbar, findsOneWidget);
      /// tap link button to show CreateLinkMenu
      final linkButton = find.byFlowySvg(FlowySvgs.toolbar_link_m);
      await tester.tapButton(linkButton);
      final createLinkMenu = find.byType(LinkCreateMenu);
      expect(createLinkMenu, findsOneWidget);
      /// test esc to close
      await tester.simulateKeyEvent(LogicalKeyboardKey.escape);
      expect(toolbar, findsNothing);
      /// show toolbar again
      await tester.editor.tapLineOfEditorAt(0);
      await selectText(tester, text);
      await tester.tapButton(linkButton);
      /// insert link
      final textField = find.descendant(
        of: createLinkMenu,
        matching: find.byType(TextFormField),
      );
      await tester.enterText(textField, link);
      await tester.pumpAndSettle();
      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
      Node node = tester.editor.getNodeAtPath([0]);
      expect(getLinkFromNode(node), link);
      await tester.simulateKeyEvent(LogicalKeyboardKey.escape);
      /// hover link
      await tester.hoverOnWidget(find.byType(LinkHoverTrigger));
      final hoverMenu = find.byType(LinkHoverMenu);
      expect(hoverMenu, findsOneWidget);
      /// copy link
      final copyButton = find.descendant(
        of: hoverMenu,
        matching: find.byFlowySvg(FlowySvgs.toolbar_link_m),
      );
      await tester.tapButton(copyButton);
      final clipboardContent = await getIt<ClipboardService>().getData();
      final plainText = clipboardContent.plainText;
      expect(plainText, link);
      /// remove link
      await tester.hoverOnWidget(find.byType(LinkHoverTrigger));
      await tester.tapButton(find.byFlowySvg(FlowySvgs.toolbar_link_unlink_m));
      node = tester.editor.getNodeAtPath([0]);
      expect(getLinkFromNode(node), null);
    });
    testWidgets('insert link and edit link', (tester) async {
      const text = 'edit link',
          link = 'https://test.appflowy.cloud',
          afterText = '$text after';
      await prepareForToolbar(tester, text);
      /// tap link button to show CreateLinkMenu
      final linkButton = find.byFlowySvg(FlowySvgs.toolbar_link_m);
      await tester.tapButton(linkButton);
      /// search for page and select it
      final textField = find.descendant(
        of: find.byType(LinkCreateMenu),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(textField, gettingStarted);
      await tester.pumpAndSettle();
      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
      await tester.simulateKeyEvent(LogicalKeyboardKey.escape);
      Node node = tester.editor.getNodeAtPath([0]);
      expect(isPageLink(node), true);
      expect(getLinkFromNode(node) == link, false);
      /// hover link
      await tester.hoverOnWidget(find.byType(LinkHoverTrigger));
      /// click edit button to show LinkEditMenu
      final editButton = find.byFlowySvg(FlowySvgs.toolbar_link_edit_m);
      await tester.tapButton(editButton);
      final linkEditMenu = find.byType(LinkEditMenu);
      expect(linkEditMenu, findsOneWidget);
      /// change the link text
      final titleField = find.descendant(
        of: linkEditMenu,
        matching: find.byType(TextFormField),
      );
      await tester.enterText(titleField, afterText);
      await tester.pumpAndSettle();
      await tester.tapButton(
        find.descendant(of: linkEditMenu, matching: find.text(gettingStarted)),
      );
      final linkField = find.ancestor(
        of: find.text(LocaleKeys.document_toolbar_linkInputHint.tr()),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(linkField, link);
      await tester.pumpAndSettle();
      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
      /// apply the change
      final applyButton =
          find.text(LocaleKeys.settings_appearance_documentSettings_apply.tr());
      await tester.tapButton(applyButton);
      node = tester.editor.getNodeAtPath([0]);
      expect(isPageLink(node), false);
      expect(getLinkFromNode(node), link);
      expect(getNodeText(node), afterText);
    });
    testWidgets('insert link and clear link name', (tester) async {
      const text = 'edit link', link = 'https://test.appflowy.cloud';
      await prepareForToolbar(tester, text);
      /// tap link button to show CreateLinkMenu
      final linkButton = find.byFlowySvg(FlowySvgs.toolbar_link_m);
      await tester.tapButton(linkButton);
      /// search for page and select it
      final textField = find.descendant(
        of: find.byType(LinkCreateMenu),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(textField, link);
      await tester.pumpAndSettle();
      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
      Node node = tester.editor.getNodeAtPath([0]);
      expect(getLinkFromNode(node), link);
      await tester.simulateKeyEvent(LogicalKeyboardKey.escape);
      /// hover link
      await tester.hoverOnWidget(find.byType(LinkHoverTrigger));
      /// click edit button to show LinkEditMenu
      final editButton = find.byFlowySvg(FlowySvgs.toolbar_link_edit_m);
      await tester.tapButton(editButton);
      final linkEditMenu = find.byType(LinkEditMenu);
      expect(linkEditMenu, findsOneWidget);
      /// clear the link name
      final titleField = find.descendant(
        of: linkEditMenu,
        matching: find.byType(TextFormField),
      );
      await tester.enterText(titleField, '');
      await tester.pumpAndSettle();
      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
      node = tester.editor.getNodeAtPath([0]);
      expect(getNodeText(node), link);
    });

    testWidgets('insert link and clear link name and remove link',
        (tester) async {
      const text = 'edit link', link = 'https://test.appflowy.cloud';
      await prepareForToolbar(tester, text);


    
          
            
    

          
          Expand Down
          
            
    

          
          Expand Up
    
    @@ -449,5 +450,77 @@ void main() {
  
      /// tap link button to show CreateLinkMenu
      final linkButton = find.byFlowySvg(FlowySvgs.toolbar_link_m);
      await tester.tapButton(linkButton);
      /// search for page and select it
      final textField = find.descendant(
        of: find.byType(LinkCreateMenu),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(textField, link);
      await tester.pumpAndSettle();
      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
      Node node = tester.editor.getNodeAtPath([0]);
      expect(getLinkFromNode(node), link);
      await tester.simulateKeyEvent(LogicalKeyboardKey.escape);
      /// hover link
      await tester.hoverOnWidget(find.byType(LinkHoverTrigger));
      /// click edit button to show LinkEditMenu
      final editButton = find.byFlowySvg(FlowySvgs.toolbar_link_edit_m);
      await tester.tapButton(editButton);
      final linkEditMenu = find.byType(LinkEditMenu);
      expect(linkEditMenu, findsOneWidget);
      /// clear the link name
      final titleField = find.descendant(
        of: linkEditMenu,
        matching: find.byType(TextFormField),
      );
      await tester.enterText(titleField, '');
      await tester.pumpAndSettle();
      await tester.tapButton(find.byFlowySvg(FlowySvgs.toolbar_link_unlink_m));
      node = tester.editor.getNodeAtPath([0]);
      expect(getNodeText(node), link);
      expect(getLinkFromNode(node), null);
    });

    testWidgets('edit link text with style', (tester) async {
      Attributes getAttribute(Node node, Selection selection) {
        Attributes attributes = {};
        final ops = node.delta?.whereType<TextInsert>() ?? [];
        final startOffset = selection.start.offset;
        var start = 0;
        for (final op in ops) {
          if (start > startOffset) break;
          final length = op.length;
          if (start + length > startOffset) {
            attributes = op.attributes ?? {};
            break;
          }
          start += length;
        }

        return attributes;
      }

      const text = 'edit text with style', link = 'https://test.appflowy.cloud';
      await prepareForToolbar(tester, text);
      final constSelection =
          Selection.single(path: [0], startOffset: 0, endOffset: text.length);

      final bold = find.byFlowySvg(FlowySvgs.toolbar_bold_m),
          italic = find.byFlowySvg(FlowySvgs.toolbar_inline_italic_m),
          underline = find.byFlowySvg(FlowySvgs.toolbar_underline_m);
      await tester.tapButton(bold);
      await tester.tapButton(italic);
      await tester.tapButton(underline);

      Node node = tester.editor.getNodeAtPath([0]);
      Attributes attributes = getAttribute(node, constSelection);
      expect(attributes, {
        AppFlowyRichTextKeys.bold: true,
        AppFlowyRichTextKeys.italic: true,
        AppFlowyRichTextKeys.underline: true,
      });

      /// tap link button to show CreateLinkMenu
      final linkButton = find.byFlowySvg(FlowySvgs.toolbar_link_m);
      await tester.tapButton(linkButton);

      /// search for page and select it
      final textField = find.descendant(
        of: find.byType(LinkCreateMenu),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(textField, gettingStarted);
      await tester.pumpAndSettle();
      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
      await tester.simulateKeyEvent(LogicalKeyboardKey.escape);

      node = tester.editor.getNodeAtPath([0]);
      attributes = getAttribute(node, constSelection);
      expect(isPageLink(node), true);
      expect(getLinkFromNode(node) == link, false);
      expect(attributes[AppFlowyRichTextKeys.bold], true);
      expect(attributes[AppFlowyRichTextKeys.italic], true);
      expect(attributes[AppFlowyRichTextKeys.underline], true);

      /// remove link
      await tester.hoverOnWidget(find.byType(LinkHoverTrigger));
      await tester.tapButton(find.byFlowySvg(FlowySvgs.toolbar_link_unlink_m));
      node = tester.editor.getNodeAtPath([0]);
      attributes = getAttribute(node, constSelection);
      expect(getLinkFromNode(node) == link, false);
      expect(attributes[AppFlowyRichTextKeys.bold], true);
      expect(attributes[AppFlowyRichTextKeys.italic], true);
      expect(attributes[AppFlowyRichTextKeys.underline], true);
    });
  });
}
