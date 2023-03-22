import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

Document createEmptyDocument() {
  return Document(
    root: Node(
      type: 'editor',
    ),
  );
}

void main() async {
  group('transaction.dart', () {
    testWidgets('test replaceTexts, textNodes.length == texts.length',
        (tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();

      final editor = tester.editor
        ..insertTextNode('0123456789')
        ..insertTextNode('0123456789')
        ..insertTextNode('0123456789')
        ..insertTextNode('0123456789');
      await editor.startTesting();
      await tester.pumpAndSettle();

      expect(editor.documentLength, 4);

      final selection = Selection(
        start: Position(path: [0], offset: 4),
        end: Position(path: [3], offset: 4),
      );
      final transaction = editor.editorState.transaction;
      var textNodes = [0, 1, 2, 3]
          .map((e) => editor.nodeAtPath([e])!)
          .whereType<TextNode>()
          .toList(growable: false);
      final texts = ['ABC', 'ABC', 'ABC', 'ABC'];
      transaction.replaceTexts(textNodes, selection, texts);
      editor.editorState.apply(transaction);
      await tester.pumpAndSettle();

      expect(editor.documentLength, 4);
      textNodes = [0, 1, 2, 3]
          .map((e) => editor.nodeAtPath([e])!)
          .whereType<TextNode>()
          .toList(growable: false);
      expect(textNodes[0].toPlainText(), '0123ABC');
      expect(textNodes[1].toPlainText(), 'ABC');
      expect(textNodes[2].toPlainText(), 'ABC');
      expect(textNodes[3].toPlainText(), 'ABC456789');
    });

    testWidgets('test replaceTexts, textNodes.length >  texts.length',
        (tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();

      final editor = tester.editor
        ..insertTextNode('0123456789')
        ..insertTextNode('0123456789')
        ..insertTextNode('0123456789')
        ..insertTextNode('0123456789')
        ..insertTextNode('0123456789');
      await editor.startTesting();
      await tester.pumpAndSettle();

      expect(editor.documentLength, 5);

      final selection = Selection(
        start: Position(path: [0], offset: 4),
        end: Position(path: [4], offset: 4),
      );
      final transaction = editor.editorState.transaction;
      var textNodes = [0, 1, 2, 3, 4]
          .map((e) => editor.nodeAtPath([e])!)
          .whereType<TextNode>()
          .toList(growable: false);
      final texts = ['ABC', 'ABC', 'ABC', 'ABC'];
      transaction.replaceTexts(textNodes, selection, texts);
      editor.editorState.apply(transaction);
      await tester.pumpAndSettle();

      expect(editor.documentLength, 4);
      textNodes = [0, 1, 2, 3]
          .map((e) => editor.nodeAtPath([e])!)
          .whereType<TextNode>()
          .toList(growable: false);
      expect(textNodes[0].toPlainText(), '0123ABC');
      expect(textNodes[1].toPlainText(), 'ABC');
      expect(textNodes[2].toPlainText(), 'ABC');
      expect(textNodes[3].toPlainText(), 'ABC456789');
    });

    testWidgets('test replaceTexts, textNodes.length >> texts.length',
        (tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();

      final editor = tester.editor
        ..insertTextNode('0123456789')
        ..insertTextNode('0123456789')
        ..insertTextNode('0123456789')
        ..insertTextNode('0123456789')
        ..insertTextNode('0123456789');
      await editor.startTesting();
      await tester.pumpAndSettle();

      expect(editor.documentLength, 5);

      final selection = Selection(
        start: Position(path: [0], offset: 4),
        end: Position(path: [4], offset: 4),
      );
      final transaction = editor.editorState.transaction;
      var textNodes = [0, 1, 2, 3, 4]
          .map((e) => editor.nodeAtPath([e])!)
          .whereType<TextNode>()
          .toList(growable: false);
      final texts = ['ABC'];
      transaction.replaceTexts(textNodes, selection, texts);
      editor.editorState.apply(transaction);
      await tester.pumpAndSettle();

      expect(editor.documentLength, 1);
      textNodes = [0]
          .map((e) => editor.nodeAtPath([e])!)
          .whereType<TextNode>()
          .toList(growable: false);
      expect(textNodes[0].toPlainText(), '0123ABC');
    });

    testWidgets('test replaceTexts, textNodes.length < texts.length',
        (tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();

      final editor = tester.editor
        ..insertTextNode('0123456789')
        ..insertTextNode('0123456789')
        ..insertTextNode('0123456789');
      await editor.startTesting();
      await tester.pumpAndSettle();

      expect(editor.documentLength, 3);

      final selection = Selection(
        start: Position(path: [0], offset: 4),
        end: Position(path: [2], offset: 4),
      );
      final transaction = editor.editorState.transaction;
      var textNodes = [0, 1, 2]
          .map((e) => editor.nodeAtPath([e])!)
          .whereType<TextNode>()
          .toList(growable: false);
      final texts = ['ABC', 'ABC', 'ABC', 'ABC'];
      transaction.replaceTexts(textNodes, selection, texts);
      editor.editorState.apply(transaction);
      await tester.pumpAndSettle();

      expect(editor.documentLength, 4);
      textNodes = [0, 1, 2, 3]
          .map((e) => editor.nodeAtPath([e])!)
          .whereType<TextNode>()
          .toList(growable: false);
      expect(textNodes[0].toPlainText(), '0123ABC');
      expect(textNodes[1].toPlainText(), 'ABC');
      expect(textNodes[2].toPlainText(), 'ABC');
      expect(textNodes[3].toPlainText(), 'ABC456789');
    });
  });
}
