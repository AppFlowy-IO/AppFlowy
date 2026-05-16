import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Block option interaction tests', () {
    testWidgets('has correct block selection on tap option button',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // We edit the document by entering some characters, to ensure the document has focus
      await tester.editor.updateSelection(
        Selection.collapsed(Position(path: [2])),
      );

      // Insert character 'a' three times - easy to identify
      await tester.ime.insertText('aaa');
      await tester.pumpAndSettle();

      final editorState = tester.editor.getCurrentEditorState();
      final node = editorState.getNodeAtPath([2]);
      expect(node?.delta?.toPlainText(), startsWith('aaa'));

      final multiSelection = Selection(
        start: Position(path: [2], offset: 3),
        end: Position(path: [4], offset: 40),
      );

      // Select multiple items
      await tester.editor.updateSelection(multiSelection);
      await tester.pumpAndSettle();

      // Press the block option menu
      await tester.editor.hoverAndClickOptionMenuButton([2]);
      await tester.pumpAndSettle();

      // Expect the selection to be Block type and not have changed
      expect(editorState.selectionType, SelectionType.block);
      expect(editorState.selection, multiSelection);
    });
  });
}
