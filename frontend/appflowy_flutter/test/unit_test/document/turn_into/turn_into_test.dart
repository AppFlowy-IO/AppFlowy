import 'package:appflowy/plugins/document/presentation/editor_configuration.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_option_cubit.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('turn into:', () {
    Document createDocument(List<Node> nodes) {
      final document = Document.blank();
      document.insert([0], nodes);
      return document;
    }

    Future<void> checkTurnInto(
      Document document,
      String originalType,
      String originalText,
    ) async {
      final editorState = EditorState(document: document);
      final cubit = BlockActionOptionCubit(
        editorState: editorState,
        blockComponentBuilder: {},
      );
      for (final type in EditorOptionActionType.turnInto.supportTypes) {
        if (type == originalType) {
          continue;
        }

        final node = editorState.getNodeAtPath([0])!;
        expect(node.type, originalType);
        final result = await cubit.turnIntoBlock(
          type,
          node,
        );
        expect(result, true);
        final newNode = editorState.getNodeAtPath([0])!;
        expect(newNode.type, type);
        expect(newNode.delta!.toPlainText(), originalText);

        // turn it back the originalType for the next test
        await cubit.turnIntoBlock(
          originalType,
          newNode,
        );
        expect(result, true);
      }
    }

    setUpAll(() {
      Log.shared.disableLog = true;
    });

    tearDownAll(() {
      Log.shared.disableLog = false;
    });

    test('from heading to another blocks', () async {
      const text = 'Heading 1';
      final document = createDocument([
        headingNode(
          level: 1,
          text: text,
        ),
      ]);
      await checkTurnInto(
        document,
        HeadingBlockKeys.type,
        text,
      );
    });

    test('from paragraph to another blocks', () async {
      const text = 'Paragraph';
      final document = createDocument([
        paragraphNode(
          text: text,
        ),
      ]);
      await checkTurnInto(
        document,
        ParagraphBlockKeys.type,
        text,
      );
    });

    test('from quote list to another blocks', () async {
      const text = 'Quote';
      final document = createDocument([
        quoteNode(
          delta: Delta()..insert(text),
        ),
      ]);
      await checkTurnInto(
        document,
        QuoteBlockKeys.type,
        text,
      );
    });

    test('from todo list to another blocks', () async {
      const text = 'Todo';
      final document = createDocument([
        todoListNode(
          checked: false,
          text: text,
        ),
      ]);
      await checkTurnInto(
        document,
        TodoListBlockKeys.type,
        text,
      );
    });

    test('from bulleted list to another blocks', () async {
      const text = 'bulleted list';
      final document = createDocument([
        bulletedListNode(
          text: text,
        ),
      ]);
      await checkTurnInto(
        document,
        BulletedListBlockKeys.type,
        text,
      );
    });

    test('from numbered list to another blocks', () async {
      const text = 'numbered list';
      final document = createDocument([
        numberedListNode(
          delta: Delta()..insert(text),
        ),
      ]);
      await checkTurnInto(
        document,
        NumberedListBlockKeys.type,
        text,
      );
    });

    test('from callout to another blocks', () async {
      const text = 'callout';
      final document = createDocument([
        calloutNode(
          delta: Delta()..insert(text),
        ),
      ]);
      await checkTurnInto(
        document,
        CalloutBlockKeys.type,
        text,
      );
    });
  });
}
