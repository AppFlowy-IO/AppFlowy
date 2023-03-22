import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import '../infra/test_editor.dart';

void main() {
  group('command_extension.dart', () {
    testWidgets('insert a new checkbox after an existing checkbox',
        (tester) async {
      final editor = tester.editor
        ..insertTextNode(
          'Welcome',
        )
        ..insertTextNode(
          'to',
        )
        ..insertTextNode(
          'Appflowy 😁',
        );
      await editor.startTesting();
      final selection = Selection(
        start: Position(path: [2], offset: 5),
        end: Position(path: [0], offset: 5),
      );
      await editor.updateSelection(selection);
      final textNodes = editor
          .editorState.service.selectionService.currentSelectedNodes
          .whereType<TextNode>()
          .toList(growable: false);
      final texts = editor.editorState.getTextInSelection(
        textNodes.normalized,
        selection.normalized,
      );
      expect(texts, ['me', 'to', 'Appfl']);
    });
  });
}
