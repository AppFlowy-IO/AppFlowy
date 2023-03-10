import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('space_on_web_handler.dart', () {
    testWidgets('Presses space key on web', (tester) async {
      if (!kIsWeb) return;
      const count = 10;
      const text = 'Welcome to Appflowy 😁';
      final editor = tester.editor;
      for (var i = 0; i < count; i++) {
        editor.insertTextNode(text);
      }
      await editor.startTesting();

      for (var i = 0; i < count; i++) {
        await editor.updateSelection(
          Selection.single(path: [i], startOffset: 1),
        );
        await editor.pressLogicKey(LogicalKeyboardKey.space);
        expect(
          (editor.nodeAtPath([i]) as TextNode).toPlainText(),
          'W elcome to Appflowy 😁',
        );
      }
      for (var i = 0; i < count; i++) {
        await editor.updateSelection(
          Selection.single(path: [i], startOffset: text.length + 1),
        );
        await editor.pressLogicKey(LogicalKeyboardKey.space);
        expect(
          (editor.nodeAtPath([i]) as TextNode).toPlainText(),
          'W elcome to Appflowy 😁 ',
        );
      }
    });
  });
}
