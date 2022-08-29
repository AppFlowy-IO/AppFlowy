import 'package:appflowy_editor/src/render/link_menu/link_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  });
}
