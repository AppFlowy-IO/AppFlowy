import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_option_cubit.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/toolbar_item/text_heading_toolbar_item.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

// Changing the block type of a multi-block selection used to leave every block
// holding the FIRST block's text, destroying the others' content.
//
// `formatNodeToText` read the delta once from `selection.start` and reused it
// inside the `formatNode` callback -- which runs for every node in the
// selection. The second test below fails on the unfixed code with
// ['first paragraph', 'first paragraph'].
//
// The `turnIntoBlock` cases are guards: that path reads the delta per node
// already, and these keep it that way.

Document _twoParagraphs() => Document(
      root: pageNode(
        children: [
          paragraphNode(text: 'first paragraph'),
          paragraphNode(text: 'second paragraph'),
        ],
      ),
    );

/// Selects from the start of the first block to the end of the last.
Selection _selectAll(EditorState editorState) {
  final children = editorState.document.root.children;
  return Selection(
    start: Position(path: children.first.path),
    end: Position(
      path: children.last.path,
      offset: children.last.delta?.length ?? 0,
    ),
  );
}

List<String> _texts(EditorState editorState) =>
    editorState.document.root.children
        .map((n) => n.delta?.toPlainText() ?? '')
        .toList();

void main() {
  group('block type change across a multi-block selection', () {
    test('turning two paragraphs into headings keeps each ones own text',
        () async {
      final editorState = EditorState(document: _twoParagraphs());
      editorState.selection = _selectAll(editorState);

      await BlockActionOptionCubit.turnIntoBlock(
        HeadingBlockKeys.type,
        editorState.getNodeAtPath([0])!,
        editorState,
        level: 3,
        keepSelection: true,
      );

      expect(_texts(editorState), ['first paragraph', 'second paragraph']);
      expect(
        editorState.document.root.children.map((n) => n.type),
        everyElement(HeadingBlockKeys.type),
      );
    });

    test('turning two headings back into text keeps each ones own text',
        () async {
      final editorState = EditorState(
        document: Document(
          root: pageNode(
            children: [
              headingNode(level: 3, text: 'first paragraph'),
              headingNode(level: 3, text: 'second paragraph'),
            ],
          ),
        ),
      );
      editorState.selection = _selectAll(editorState);

      formatNodeToText(editorState);
      await Future<void>.delayed(Duration.zero);

      expect(_texts(editorState), ['first paragraph', 'second paragraph']);
    });

    test('an alignment attribute does not reintroduce the duplication',
        () async {
      final editorState = EditorState(
        document: Document(
          root: pageNode(
            children: [
              paragraphNode(
                text: 'first paragraph',
                attributes: {blockComponentAlign: 'justify'},
              ),
              paragraphNode(
                text: 'second paragraph',
                attributes: {blockComponentAlign: 'justify'},
              ),
            ],
          ),
        ),
      );
      editorState.selection = _selectAll(editorState);

      await BlockActionOptionCubit.turnIntoBlock(
        HeadingBlockKeys.type,
        editorState.getNodeAtPath([0])!,
        editorState,
        level: 3,
        keepSelection: true,
      );
      expect(_texts(editorState), ['first paragraph', 'second paragraph']);

      editorState.selection = _selectAll(editorState);
      formatNodeToText(editorState);
      await Future<void>.delayed(Duration.zero);
      expect(_texts(editorState), ['first paragraph', 'second paragraph']);
    });

    test('a single-block selection is unaffected', () async {
      final editorState = EditorState(document: _twoParagraphs());
      editorState.selection = Selection.single(path: [1], startOffset: 0);

      await BlockActionOptionCubit.turnIntoBlock(
        HeadingBlockKeys.type,
        editorState.getNodeAtPath([1])!,
        editorState,
        level: 1,
      );

      expect(_texts(editorState), ['first paragraph', 'second paragraph']);
    });
  });
}
