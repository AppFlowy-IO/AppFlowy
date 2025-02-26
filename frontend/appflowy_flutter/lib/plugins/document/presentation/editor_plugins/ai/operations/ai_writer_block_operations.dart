import 'package:appflowy/shared/markdown_to_document.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

import '../ai_writer_block_component.dart';
import 'ai_writer_entities.dart';

Future<void> removeAiWriterNode(EditorState editorState, Node node) async {
  final transaction = editorState.transaction..deleteNode(node);
  await editorState.apply(
    transaction,
    options: const ApplyOptions(recordUndo: false),
    withUpdateSelection: false,
  );
}

void formatSelection(
  EditorState editorState,
  Selection selection,
  Transaction transaction,
  ApplySuggestionFormatType formatType,
) {
  final nodes = editorState.getNodesInSelection(selection).toList();
  if (nodes.isEmpty) {
    return;
  }

  if (nodes.length == 1) {
    final node = nodes.removeAt(0);
    if (node.delta != null) {
      final delta = Delta()
        ..retain(selection.start.offset)
        ..retain(
          selection.length,
          attributes: formatType.attributes,
        );
      transaction.addDeltaToComposeMap(node, delta);
    }
  } else {
    final firstNode = nodes.removeAt(0);
    final lastNode = nodes.removeLast();

    if (firstNode.delta != null) {
      final text = firstNode.delta!.toPlainText();
      final remainderLength = text.length - selection.start.offset;
      final delta = Delta()
        ..retain(selection.start.offset)
        ..retain(remainderLength, attributes: formatType.attributes);
      transaction.addDeltaToComposeMap(firstNode, delta);
    }

    if (lastNode.delta != null) {
      final delta = Delta()
        ..retain(selection.end.offset, attributes: formatType.attributes);
      transaction.addDeltaToComposeMap(lastNode, delta);
    }

    for (final node in nodes) {
      if (node.delta == null) {
        continue;
      }
      final length = node.delta!.length;
      if (length != 0) {
        final delta = Delta()
          ..retain(length, attributes: formatType.attributes);
        transaction.addDeltaToComposeMap(node, delta);
      }
    }
  }

  transaction.compose();
}

Position ensurePreviousNodeIsEmptyParagraph(
  EditorState editorState,
  Node aiWriterNode,
  Transaction transaction,
) {
  final previous = aiWriterNode.previous;
  final needsEmptyParagraphNode = previous == null ||
      previous.type != ParagraphBlockKeys.type ||
      (previous.delta?.toPlainText().isNotEmpty ?? false);

  final Position position;
  if (needsEmptyParagraphNode) {
    position = Position(path: aiWriterNode.path);
    transaction.insertNode(aiWriterNode.path, paragraphNode());
  } else {
    position = Position(path: previous.path);
  }

  transaction.updateNode(aiWriterNode, {
    AiWriterBlockKeys.isInitialized: true,
  });

  return position;
}

extension SaveAIResponseExtension on EditorState {
  Future<void> insertBelow({
    required Node node,
    required String markdownText,
  }) async {
    final selection = this.selection?.normalized;
    if (selection == null) {
      return;
    }

    final nodes = customMarkdownToDocument(
      markdownText,
      tableWidth: 250.0,
    ).root.children.map((e) => e.deepCopy()).toList();
    if (nodes.isEmpty) {
      return;
    }

    final insertedPath = selection.end.path.next;
    final lastDeltaLength = nodes.lastOrNull?.delta?.length ?? 0;

    final transaction = this.transaction
      ..insertNodes(insertedPath, nodes)
      ..afterSelection = Selection(
        start: Position(path: insertedPath),
        end: Position(
          path: insertedPath.nextNPath(nodes.length - 1),
          offset: lastDeltaLength,
        ),
      );

    await apply(transaction);
  }

  Future<void> replace({
    required Selection selection,
    required String text,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return;
    }
    await switch (kdefaultReplacementType) {
      AskAIReplacementType.markdown =>
        _replaceWithMarkdown(selection, trimmedText),
      AskAIReplacementType.plainText =>
        _replaceWithPlainText(selection, trimmedText),
    };
  }

  Future<void> _replaceWithMarkdown(
    Selection selection,
    String markdownText,
  ) async {
    final nodes = customMarkdownToDocument(markdownText)
        .root
        .children
        .map((e) => e.deepCopy())
        .toList();
    if (nodes.isEmpty) {
      return;
    }

    final nodesInSelection = getNodesInSelection(selection);
    final newSelection = Selection(
      start: selection.start,
      end: Position(
        path: selection.start.path.nextNPath(nodes.length - 1),
        offset: nodes.lastOrNull?.delta?.length ?? 0,
      ),
    );

    final transaction = this.transaction
      ..insertNodes(selection.start.path, nodes)
      ..deleteNodes(nodesInSelection)
      ..afterSelection = newSelection;
    await apply(transaction);
  }

  Future<void> _replaceWithPlainText(
    Selection selection,
    String plainText,
  ) async {
    final nodes = getNodesInSelection(selection);
    if (nodes.isEmpty || nodes.any((element) => element.delta == null)) {
      return;
    }

    final replaceTexts = plainText.split('\n')
      ..removeWhere((element) => element.isEmpty);
    final transaction = this.transaction
      ..replaceTexts(
        nodes,
        selection,
        replaceTexts,
      );
    await apply(transaction);

    int endOffset = replaceTexts.last.length;
    if (replaceTexts.length == 1) {
      endOffset += selection.start.offset;
    }
    final end = Position(
      path: [selection.start.path.first + replaceTexts.length - 1],
      offset: endOffset,
    );
    this.selection = Selection(
      start: selection.start,
      end: end,
    );
  }
}
