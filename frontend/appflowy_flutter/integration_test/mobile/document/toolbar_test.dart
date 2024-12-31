import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/editor/mobile_editor_screen.dart';
import 'package:appflowy/mobile/presentation/mobile_bottom_navigation_bar.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/appflowy_mobile_toolbar_item.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/util.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('toolbar menu:', () {
    testWidgets('insert links', (tester) async {
      await tester.launchInAnonymousMode();

      final createPageButton = find.byKey(
        BottomNavigationBarItemType.add.valueKey,
      );
      await tester.tapButton(createPageButton);
      expect(find.byType(MobileDocumentScreen), findsOneWidget);

      final editor = find.byType(AppFlowyEditor);
      expect(editor, findsOneWidget);
      final editorState = tester.editor.getCurrentEditorState();

      /// move cursor to content
      final root = editorState.document.root;
      final lastNode = root.children.lastOrNull;
      await editorState.updateSelectionWithReason(
        Selection.collapsed(Position(path: lastNode!.path)),
      );
      await tester.pumpAndSettle();

      /// insert two lines of text
      const strFirst = 'FirstLine',
          strSecond = 'SecondLine',
          link = 'google.com';
      await editorState.insertTextAtCurrentSelection(strFirst);
      await tester.pumpAndSettle();
      await editorState.insertNewLine();
      await tester.pumpAndSettle();
      await editorState.insertTextAtCurrentSelection(strSecond);
      await tester.pumpAndSettle();
      final firstLine = find.text(strFirst, findRichText: true),
          secondLine = find.text(strSecond, findRichText: true);
      expect(firstLine, findsOneWidget);
      expect(secondLine, findsOneWidget);

      /// select the first line
      await tester.longPress(firstLine);
      await tester.pumpAndSettle();

      /// find aa item and tap it
      final aaItem = find.byWidgetPredicate(
        (widget) =>
            widget is AppFlowyMobileToolbarIconItem &&
            widget.icon == FlowySvgs.m_toolbar_aa_m,
      );
      expect(aaItem, findsOneWidget);
      await tester.tapButton(aaItem);

      /// find link button and tap it
      final linkButton = find.byWidgetPredicate(
        (widget) =>
            widget is MobileToolbarMenuItemWrapper &&
            widget.icon == FlowySvgs.m_toolbar_link_m,
      );
      expect(linkButton, findsOneWidget);
      await tester.tapButton(linkButton);

      /// input the link
      final linkField = find.byWidgetPredicate(
        (w) =>
            w is FlowyTextField &&
            w.hintText == LocaleKeys.document_inlineLink_url_placeholder.tr(),
      );
      await tester.enterText(linkField, link);
      await tester.pumpAndSettle();

      /// complete inputting
      await tester.tapButton(find.text(LocaleKeys.button_done.tr()));

      /// do it again
      /// select the second line
      await tester.longPress(secondLine);
      await tester.pumpAndSettle();
      await tester.tapButton(aaItem);
      await tester.tapButton(linkButton);
      await tester.enterText(linkField, link);
      await tester.pumpAndSettle();
      await tester.tapButton(find.text(LocaleKeys.button_done.tr()));

      final firstNode = editorState.getNodeAtPath([0]);
      final secondNode = editorState.getNodeAtPath([1]);

      Map commonDeltaJson(String insert) => {
            "insert": insert,
            "attributes": {"href": link},
          };

      expect(
        firstNode?.delta?.toJson(),
        commonDeltaJson(strFirst),
      );
      expect(
        secondNode?.delta?.toJson(),
        commonDeltaJson(strSecond),
      );
    });
  });
}
