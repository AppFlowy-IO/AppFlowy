import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('slash_handler.dart', () {
    testWidgets('Presses / to trigger selection menu in 0 index',
        (tester) async {
      const text = 'Welcome to Appflowy 😁';
      const lines = 3;
      final editor = tester.editor;
      for (var i = 0; i < lines; i++) {
        editor.insertTextNode(text);
      }
      await editor.startTesting();
      await editor.updateSelection(Selection.single(path: [1], startOffset: 0));
      await editor.pressLogicKey(LogicalKeyboardKey.slash);

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));

      expect(
        find.byType(SelectionMenuWidget, skipOffstage: false),
        findsOneWidget,
      );

      for (final item in defaultSelectionMenuItems) {
        expect(find.text(item.name), findsOneWidget);
      }

      await editor.updateSelection(Selection.single(path: [1], startOffset: 0));

      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      expect(
        find.byType(SelectionMenuItemWidget, skipOffstage: false),
        findsNothing,
      );
    });

    testWidgets('Presses / to trigger selection menu in not 0 index',
        (tester) async {
      const text = 'Welcome to Appflowy 😁';
      const lines = 3;
      final editor = tester.editor;
      for (var i = 0; i < lines; i++) {
        editor.insertTextNode(text);
      }
      await editor.startTesting();
      await editor.updateSelection(Selection.single(path: [1], startOffset: 5));
      await editor.pressLogicKey(LogicalKeyboardKey.slash);

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));

      expect(
        find.byType(SelectionMenuWidget, skipOffstage: false),
        findsOneWidget,
      );

      for (final item in defaultSelectionMenuItems) {
        expect(find.text(item.name), findsOneWidget);
      }

      await editor.updateSelection(Selection.single(path: [1], startOffset: 0));

      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      expect(
        find.byType(SelectionMenuItemWidget, skipOffstage: false),
        findsNothing,
      );
    });
  });
}
