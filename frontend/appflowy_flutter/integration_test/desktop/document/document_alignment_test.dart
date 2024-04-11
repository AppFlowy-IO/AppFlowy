import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/keyboard.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('document alignment', () {
    testWidgets('edit alignment in toolbar', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      final selection = Selection.single(
        path: [0],
        startOffset: 0,
        endOffset: 1,
      );
      // click the first line of the readme
      await tester.editor.tapLineOfEditorAt(0);
      await tester.editor.updateSelection(selection);
      await tester.pumpAndSettle();

      // click the align center
      await tester.tapButtonWithFlowySvgData(FlowySvgs.toolbar_align_left_s);
      await tester.tapButtonWithFlowySvgData(FlowySvgs.toolbar_align_center_s);

      // expect to see the align center
      final editorState = tester.editor.getCurrentEditorState();
      final first = editorState.getNodeAtPath([0])!;
      expect(first.attributes[blockComponentAlign], 'center');

      // click the align right
      await tester.tapButtonWithFlowySvgData(FlowySvgs.toolbar_align_center_s);
      await tester.tapButtonWithFlowySvgData(FlowySvgs.toolbar_align_right_s);
      expect(first.attributes[blockComponentAlign], 'right');

      // click the align left
      await tester.tapButtonWithFlowySvgData(FlowySvgs.toolbar_align_right_s);
      await tester.tapButtonWithFlowySvgData(FlowySvgs.toolbar_align_left_s);
      expect(first.attributes[blockComponentAlign], 'left');
    });

    testWidgets('edit alignment using shortcut', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // click the first line of the readme
      await tester.editor.tapLineOfEditorAt(0);

      await tester.pumpAndSettle();

      final editorState = tester.editor.getCurrentEditorState();
      final first = editorState.getNodeAtPath([0])!;

      // expect to see text aligned to the right
      await FlowyTestKeyboard.simulateKeyDownEvent(
        [
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyR,
        ],
        tester: tester,
      );
      expect(first.attributes[blockComponentAlign], rightAlignmentKey);

      // expect to see text aligned to the center
      await FlowyTestKeyboard.simulateKeyDownEvent(
        [
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyE,
        ],
        tester: tester,
      );
      expect(first.attributes[blockComponentAlign], centerAlignmentKey);

      // expect to see text aligned to the left
      await FlowyTestKeyboard.simulateKeyDownEvent(
        [
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyL,
        ],
        tester: tester,
      );
      expect(first.attributes[blockComponentAlign], leftAlignmentKey);
    });
  });
}
