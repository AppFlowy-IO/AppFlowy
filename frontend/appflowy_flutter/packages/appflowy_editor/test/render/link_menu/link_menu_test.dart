import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/render/link_menu/link_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('link_menu.dart', () {
    testWidgets('test empty link menu actions', (tester) async {
      const link = 'appflowy.io';
      var submittedText = '';
      final linkMenu = LinkMenu(
        onOpenLink: () {},
        onCopyLink: () {},
        onRemoveLink: () {},
        onFocusChange: (value) {},
        onSubmitted: (text) {
          submittedText = text;
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: linkMenu,
          ),
        ),
      );

      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(TextField), findsOneWidget);

      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), link);
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(submittedText, link);
    });

    testWidgets('test tap linked text', (tester) async {
      const link = 'appflowy.io';
      // This is a link [appflowy.io](appflowy.io)
      final editor = tester.editor
        ..insertTextNode(
          null,
          delta: Delta()
            ..insert(
              link,
              attributes: {
                BuiltInAttributeKey.href: link,
              },
            ),
        );
      await editor.startTesting();
      await tester.pumpAndSettle();
      final finder = find.text(link, findRichText: true);
      expect(finder, findsOneWidget);

      // tap the link
      await editor.updateSelection(
        Selection.single(path: [0], startOffset: 0, endOffset: link.length),
      );
      await tester.tap(finder);
      await tester.pumpAndSettle(const Duration(milliseconds: 350));
      final linkMenu = find.byType(LinkMenu);
      expect(linkMenu, findsOneWidget);
      expect(find.text(link, findRichText: true), findsNWidgets(2));
    });
  });
}
