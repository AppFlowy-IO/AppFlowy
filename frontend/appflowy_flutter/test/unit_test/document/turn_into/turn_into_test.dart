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
      String originalText, {
      String? toType,
      void Function(EditorState editorState, Node node)? afterTurnInto,
    }) async {
      final editorState = EditorState(document: document);
      final cubit = BlockActionOptionCubit(
        editorState: editorState,
        blockComponentBuilder: {},
      );

      final types = toType == null
          ? EditorOptionActionType.turnInto.supportTypes
          : [toType];
      for (final type in types) {
        if (type == originalType) {
          continue;
        }

        editorState.selectionType = SelectionType.block;
        editorState.selection = Selection.collapsed(
          Position(path: [0]),
        );

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
        afterTurnInto?.call(
          editorState,
          newNode,
        );

        // turn it back the originalType for the next test
        editorState.selectionType = SelectionType.block;
        editorState.selection = Selection.collapsed(
          Position(path: [0]),
        );
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

    test('from nested list to heading', () async {
      const text = 'bulleted list';
      const nestedText1 = 'nested bulleted list 1';
      const nestedText2 = 'nested bulleted list 2';
      const nestedText3 = 'nested bulleted list 3';
      final document = createDocument([
        bulletedListNode(
          text: text,
          children: [
            bulletedListNode(
              text: nestedText1,
            ),
            bulletedListNode(
              text: nestedText2,
            ),
            bulletedListNode(
              text: nestedText3,
            ),
          ],
        ),
      ]);
      await checkTurnInto(
        document,
        BulletedListBlockKeys.type,
        text,
        toType: HeadingBlockKeys.type,
        afterTurnInto: (editorState, node) {
          expect(node.type, HeadingBlockKeys.type);
          expect(node.children.length, 0);
          expect(node.delta!.toPlainText(), text);

          expect(editorState.document.root.children.length, 4);
          expect(
            editorState.document.root.children[1].type,
            BulletedListBlockKeys.type,
          );
          expect(
            editorState.document.root.children[1].delta!.toPlainText(),
            nestedText1,
          );
          expect(
            editorState.document.root.children[2].type,
            BulletedListBlockKeys.type,
          );
          expect(
            editorState.document.root.children[2].delta!.toPlainText(),
            nestedText2,
          );
          expect(
            editorState.document.root.children[3].type,
            BulletedListBlockKeys.type,
          );
          expect(
            editorState.document.root.children[3].delta!.toPlainText(),
            nestedText3,
          );
        },
      );
    });

    test('from numbered list to heading', () async {
      const text = 'numbered list';
      const nestedText1 = 'nested numbered list 1';
      const nestedText2 = 'nested numbered list 2';
      const nestedText3 = 'nested numbered list 3';
      final document = createDocument([
        numberedListNode(
          delta: Delta()..insert(text),
          children: [
            numberedListNode(
              delta: Delta()..insert(nestedText1),
            ),
            numberedListNode(
              delta: Delta()..insert(nestedText2),
            ),
            numberedListNode(
              delta: Delta()..insert(nestedText3),
            ),
          ],
        ),
      ]);
      await checkTurnInto(
        document,
        NumberedListBlockKeys.type,
        text,
        toType: HeadingBlockKeys.type,
        afterTurnInto: (editorState, node) {
          expect(node.type, HeadingBlockKeys.type);
          expect(node.children.length, 0);
          expect(node.delta!.toPlainText(), text);

          expect(editorState.document.root.children.length, 4);
          expect(
            editorState.document.root.children[1].type,
            NumberedListBlockKeys.type,
          );
          expect(
            editorState.document.root.children[1].delta!.toPlainText(),
            nestedText1,
          );
          expect(
            editorState.document.root.children[2].type,
            NumberedListBlockKeys.type,
          );
          expect(
            editorState.document.root.children[2].delta!.toPlainText(),
            nestedText2,
          );
          expect(
            editorState.document.root.children[3].type,
            NumberedListBlockKeys.type,
          );
          expect(
            editorState.document.root.children[3].delta!.toPlainText(),
            nestedText3,
          );
        },
      );
    });
  });
}
