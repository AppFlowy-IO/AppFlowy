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
      Selection? selection,
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
        editorState.selection = selection ??
            Selection.collapsed(
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
        editorState.selection = selection ??
            Selection.collapsed(
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

    for (final type in [
      HeadingBlockKeys.type,
      QuoteBlockKeys.type,
      CalloutBlockKeys.type,
    ]) {
      test('from nested bulleted list to $type', () async {
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
          toType: type,
          afterTurnInto: (editorState, node) {
            expect(node.type, type);
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
    }

    for (final type in [
      HeadingBlockKeys.type,
      QuoteBlockKeys.type,
      CalloutBlockKeys.type,
    ]) {
      test('from nested numbered list to $type', () async {
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
          toType: type,
          afterTurnInto: (editorState, node) {
            expect(node.type, type);
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
    }

    for (final type in [
      HeadingBlockKeys.type,
      QuoteBlockKeys.type,
      CalloutBlockKeys.type,
    ]) {
      // numbered list, bulleted list, todo list
      // before
      // - numbered list 1
      //   - nested list 1
      // - bulleted list 2
      //   - nested list 2
      // - todo list 3
      //   - nested list 3
      // after
      // - heading 1
      // - nested list 1
      // - heading 2
      // - nested list 2
      // - heading 3
      // - nested list 3
      test('from nested mixed list to $type', () async {
        const text1 = 'numbered list 1';
        const text2 = 'bulleted list 2';
        const text3 = 'todo list 3';
        const nestedText1 = 'nested list 1';
        const nestedText2 = 'nested list 2';
        const nestedText3 = 'nested list 3';
        final document = createDocument([
          numberedListNode(
            delta: Delta()..insert(text1),
            children: [
              numberedListNode(
                delta: Delta()..insert(nestedText1),
              ),
            ],
          ),
          bulletedListNode(
            delta: Delta()..insert(text2),
            children: [
              bulletedListNode(
                delta: Delta()..insert(nestedText2),
              ),
            ],
          ),
          todoListNode(
            checked: false,
            text: text3,
            children: [
              todoListNode(
                checked: false,
                text: nestedText3,
              ),
            ],
          ),
        ]);
        await checkTurnInto(
          document,
          NumberedListBlockKeys.type,
          text1,
          toType: type,
          selection: Selection(
            start: Position(path: [0]),
            end: Position(path: [2]),
          ),
          afterTurnInto: (editorState, node) {
            final nodes = editorState.document.root.children;
            expect(nodes.length, 6);
            final texts = [
              text1,
              nestedText1,
              text2,
              nestedText2,
              text3,
              nestedText3,
            ];
            final types = [
              type,
              NumberedListBlockKeys.type,
              type,
              BulletedListBlockKeys.type,
              type,
              TodoListBlockKeys.type,
            ];
            for (var i = 0; i < 6; i++) {
              expect(nodes[i].type, types[i]);
              expect(nodes[i].children.length, 0);
              expect(nodes[i].delta!.toPlainText(), texts[i]);
            }
          },
        );
      });
    }

    for (final type in [
      ParagraphBlockKeys.type,
      BulletedListBlockKeys.type,
      NumberedListBlockKeys.type,
      TodoListBlockKeys.type,
    ]) {
      // numbered list, bulleted list, todo list
      // before
      // - numbered list 1
      //   - nested list 1
      // - bulleted list 2
      //   - nested list 2
      // - todo list 3
      //   - nested list 3
      // after
      // - new_list_type
      //  - nested list 1
      // - new_list_type
      //  - nested list 2
      // - new_list_type
      //  - nested list 3
      test('from nested mixed list to $type', () async {
        const text1 = 'numbered list 1';
        const text2 = 'bulleted list 2';
        const text3 = 'todo list 3';
        const nestedText1 = 'nested list 1';
        const nestedText2 = 'nested list 2';
        const nestedText3 = 'nested list 3';
        final document = createDocument([
          numberedListNode(
            delta: Delta()..insert(text1),
            children: [
              numberedListNode(
                delta: Delta()..insert(nestedText1),
              ),
            ],
          ),
          bulletedListNode(
            delta: Delta()..insert(text2),
            children: [
              bulletedListNode(
                delta: Delta()..insert(nestedText2),
              ),
            ],
          ),
          todoListNode(
            checked: false,
            text: text3,
            children: [
              todoListNode(
                checked: false,
                text: nestedText3,
              ),
            ],
          ),
        ]);
        await checkTurnInto(
          document,
          NumberedListBlockKeys.type,
          text1,
          toType: type,
          selection: Selection(
            start: Position(path: [0]),
            end: Position(path: [2]),
          ),
          afterTurnInto: (editorState, node) {
            final nodes = editorState.document.root.children;
            expect(nodes.length, 3);
            final texts = [
              text1,
              text2,
              text3,
            ];
            final nestedTexts = [
              nestedText1,
              nestedText2,
              nestedText3,
            ];
            final types = [
              NumberedListBlockKeys.type,
              BulletedListBlockKeys.type,
              TodoListBlockKeys.type,
            ];
            for (var i = 0; i < 3; i++) {
              expect(nodes[i].type, type);
              expect(nodes[i].children.length, 1);
              expect(nodes[i].delta!.toPlainText(), texts[i]);
              expect(nodes[i].children[0].type, types[i]);
              expect(nodes[i].children[0].delta!.toPlainText(), nestedTexts[i]);
            }
          },
        );
      });
    }
  });
}
