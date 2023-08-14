import 'dart:io';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('copy and paste in document', () {
    testWidgets('paste multiple lines at the first line', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // create a new document
      await tester.createNewPageWithName();

      // mock the clipboard
      const lines = 3;
      AppFlowyClipboard.mockSetData(
        AppFlowyClipboardData(
          text: List.generate(lines, (index) => 'line $index').join('\n'),
        ),
      );

      // paste the text
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyV,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      final editorState = tester.editor.getCurrentEditorState();
      expect(editorState.document.root.children.length, 4);
      for (var i = 0; i < lines; i++) {
        expect(
          editorState.getNodeAtPath([i])!.delta!.toPlainText(),
          'line $i',
        );
      }
    });
  });
}
