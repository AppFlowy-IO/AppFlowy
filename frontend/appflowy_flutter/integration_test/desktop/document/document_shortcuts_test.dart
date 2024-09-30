import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('document shortcuts:', () {
    testWidgets('ctrl/cmd+x to delete a line when the selection is collapsed',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      const pageName = 'Test Document Shortcuts';
      await tester.createNewPageWithNameUnderParent(name: pageName);

      // focus on the editor
      await tester.tap(find.byType(AppFlowyEditor));

      // mock the data
      final editorState = tester.editor.getCurrentEditorState();
      final transaction = editorState.transaction;
      transaction.insertNodes([
        0,
      ], [
        paragraphNode(text: '1. First line'),
        paragraphNode(text: '2. Second line'),
      ]);
      await editorState.apply(transaction);
      await tester.pumpAndSettle();

      // focus on the end of the first line
      await tester.editor.tapLineOfEditorAt(0);
      // press the keybinding
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyX,
        isControlPressed: !UniversalPlatform.isMacOS,
        isMetaPressed: UniversalPlatform.isMacOS,
      );
      await tester.pumpAndSettle();

      final node = tester.editor.getNodeAtPath([0]);
      expect(
        node.delta?.toPlainText(),
        equals('2. Second line'),
      );

      // select the whole line
      editorState.selection = Selection.single(
        path: [0],
        startOffset: 0,
        endOffset: node.delta?.length ?? 0,
      );

      // press the keybinding
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyX,
        isControlPressed: !UniversalPlatform.isMacOS,
        isMetaPressed: UniversalPlatform.isMacOS,
      );
      await tester.pumpAndSettle();

      // nothing should happen
      expect(
        node.delta?.toPlainText(),
        equals('2. Second line'),
      );
    });
  });
}
