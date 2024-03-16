import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // +, ... button beside the block component.
  group('document with option action button', () {
    testWidgets(
        'click + to add a block after current selection, and click + and option key to add a block before current selection',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      var editorState = tester.editor.getCurrentEditorState();
      expect(editorState.getNodeAtPath([1])?.delta?.toPlainText(), isNotEmpty);

      // add a new block after the current selection
      await tester.editor.hoverAndClickOptionAddButton([0], false);
      // await tester.pumpAndSettle();
      expect(editorState.getNodeAtPath([1])?.delta?.toPlainText(), isEmpty);

      // cancel the selection menu
      await tester.tapAt(Offset.zero);

      await tester.editor.hoverAndClickOptionAddButton([0], true);
      await tester.pumpAndSettle();
      expect(editorState.getNodeAtPath([0])?.delta?.toPlainText(), isEmpty);
      // cancel the selection menu
      await tester.tapAt(Offset.zero);
      await tester.tapAt(Offset.zero);

      await tester.createNewPageWithNameUnderParent(name: 'test');
      await tester.openPage(gettingStarted);

      // check the status again
      editorState = tester.editor.getCurrentEditorState();
      expect(editorState.getNodeAtPath([0])?.delta?.toPlainText(), isEmpty);
      expect(editorState.getNodeAtPath([2])?.delta?.toPlainText(), isEmpty);
    });
  });
}
