import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/render/selection_menu/selection_menu_item_widget.dart';
import 'package:appflowy_editor/src/render/selection_menu/selection_menu_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('slash_handler.dart', () {
    testWidgets('Presses / to trigger selection menu', (tester) async {
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
        expect(find.byWidget(item.icon), findsOneWidget);
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
