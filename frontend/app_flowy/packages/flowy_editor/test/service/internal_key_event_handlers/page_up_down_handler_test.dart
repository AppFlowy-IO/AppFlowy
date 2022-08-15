import 'package:flowy_editor/flowy_editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('page_up_down_handler_test.dart', () {
    testWidgets('Presses PageUp and pageDown key in large document',
        (tester) async {
      const text = 'Welcome to Appflowy 😁';
      final editor = tester.editor;
      for (var i = 0; i < 1000; i++) {
        editor.insertTextNode(text);
      }
      await editor.startTesting();
      await editor.updateSelection(
        Selection.single(path: [0], startOffset: 0),
      );

      final scrollService = editor.editorState.service.scrollService;

      expect(scrollService != null, true);

      if (scrollService == null) {
        return;
      }

      final page = scrollService.page;
      final onePageHeight = scrollService.onePageHeight;
      expect(page != null, true);
      expect(onePageHeight != null, true);

      // Pressing the pageDown key continuously.
      var currentOffsetY = 0.0;
      for (int i = 1; i <= page!; i++) {
        await editor.pressLogicKey(
          LogicalKeyboardKey.pageDown,
        );
        currentOffsetY += onePageHeight!;
        final dy = scrollService.dy;
        expect(dy, currentOffsetY);
      }

      for (int i = 1; i <= 5; i++) {
        await editor.pressLogicKey(
          LogicalKeyboardKey.pageDown,
        );
        final dy = scrollService.dy;
        expect(dy == scrollService.maxScrollExtent, true);
      }

      // Pressing the pageUp key continuously.
      for (int i = page; i >= 1; i--) {
        await editor.pressLogicKey(
          LogicalKeyboardKey.pageUp,
        );
        currentOffsetY -= onePageHeight!;
        final dy = editor.editorState.service.scrollService?.dy;
        expect(dy, currentOffsetY);
      }

      for (int i = 1; i <= 5; i++) {
        await editor.pressLogicKey(
          LogicalKeyboardKey.pageUp,
        );
        final dy = scrollService.dy;
        expect(dy == scrollService.minScrollExtent, true);
      }
    });
  });
}
