import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('document selection:', () {
    testWidgets('select text from start to end by pan gesture ',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent();

      final editor = tester.editor;
      final editorState = editor.getCurrentEditorState();
      // insert a paragraph
      final transaction = editorState.transaction;
      transaction.insertNode(
        [0],
        paragraphNode(
          text:
              '''Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.''',
        ),
      );
      await editorState.apply(transaction);
      await tester.pumpAndSettle(Durations.short1);

      final textBlocks = find.byType(AppFlowyRichText);
      final topLeft = tester.getTopLeft(textBlocks.at(0));

      final gesture = await tester.startGesture(
        topLeft,
        pointer: 7,
      );
      await tester.pumpAndSettle();

      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(10, 0));
        await tester.pump(Durations.short1);
      }

      expect(editorState.selection!.start.offset, 0);
    });

    testWidgets('select and delete text', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      /// create a new document
      await tester.createNewPageWithNameUnderParent();

      /// input text
      final editor = tester.editor;
      final editorState = editor.getCurrentEditorState();

      const inputText = 'Test for text selection and deletion';
      final texts = inputText.split(' ');
      await editor.tapLineOfEditorAt(0);
      await tester.ime.insertText(inputText);

      /// selecte and delete
      int index = 0;
      while (texts.isNotEmpty) {
        final text = texts.removeAt(0);
        await tester.editor.updateSelection(
          Selection(
            start: Position(path: [0], offset: index),
            end: Position(path: [0], offset: index + text.length),
          ),
        );
        await tester.simulateKeyEvent(LogicalKeyboardKey.delete);
        index++;
      }

      /// excpete the text value is correct
      final node = editorState.getNodeAtPath([0])!;
      final nodeText = node.delta?.toPlainText() ?? '';
      expect(nodeText, ' ' * (index - 1));
    });
  });
}
