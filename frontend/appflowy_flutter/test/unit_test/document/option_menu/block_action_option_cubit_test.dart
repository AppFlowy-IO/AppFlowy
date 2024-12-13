import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_option_cubit.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('block action option cubit:', () {
    setUpAll(() {
      Log.shared.disableLog = true;
    });

    tearDownAll(() {
      Log.shared.disableLog = false;
    });

    test('delete blocks', () async {
      const text = 'paragraph';
      final document = Document.blank()
        ..insert([
          0,
        ], [
          paragraphNode(text: text),
          paragraphNode(text: text),
          paragraphNode(text: text),
        ]);

      final editorState = EditorState(document: document);
      final cubit = BlockActionOptionCubit(
        editorState: editorState,
        blockComponentBuilder: {},
      );

      editorState.selection = Selection(
        start: Position(path: [0]),
        end: Position(path: [2], offset: text.length),
      );
      editorState.selectionType = SelectionType.block;

      await cubit.handleAction(OptionAction.delete, document.nodeAtPath([0])!);

      // all the nodes should be deleted
      expect(document.root.children, isEmpty);

      editorState.dispose();
    });

    test('duplicate blocks', () async {
      const text = 'paragraph';
      final document = Document.blank()
        ..insert([
          0,
        ], [
          paragraphNode(text: text),
          paragraphNode(text: text),
          paragraphNode(text: text),
        ]);

      final editorState = EditorState(document: document);
      final cubit = BlockActionOptionCubit(
        editorState: editorState,
        blockComponentBuilder: {},
      );

      editorState.selection = Selection(
        start: Position(path: [0]),
        end: Position(path: [2], offset: text.length),
      );
      editorState.selectionType = SelectionType.block;

      await cubit.handleAction(
        OptionAction.duplicate,
        document.nodeAtPath([0])!,
      );

      expect(document.root.children, hasLength(6));

      editorState.dispose();
    });
  });
}
