import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/ai_writer_block_component.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

/// Notes: All the operation related to the AI writer block will be applied
/// in memory.
class AIWriterBlockOperations {
  AIWriterBlockOperations({
    required this.editorState,
    required this.aiWriterNode,
  }) : assert(aiWriterNode.type == AIWriterBlockKeys.type);

  final EditorState editorState;
  final Node aiWriterNode;

  /// Update the prompt text in the node.
  Future<void> updatePromptText(String prompt) async {
    final transaction = editorState.transaction;
    transaction.updateNode(
      aiWriterNode,
      {AIWriterBlockKeys.prompt: prompt},
    );
    await editorState.apply(
      transaction,
      options: const ApplyOptions(
        inMemoryUpdate: true,
        recordUndo: false,
      ),
    );
  }

  /// Update the generation count in the node.
  Future<void> updateGenerationCount(int count) async {
    final transaction = editorState.transaction;
    transaction.updateNode(
      aiWriterNode,
      {AIWriterBlockKeys.generationCount: count},
    );
    await editorState.apply(
      transaction,
      options: const ApplyOptions(inMemoryUpdate: true),
    );
  }

  /// Ensure the previous node is a empty paragraph node without any styles.
  Future<void> ensurePreviousNodeIsEmptyParagraphNode() async {
    final previous = aiWriterNode.previous;
    final Selection selection;

    // 1. previous node is null or
    // 2. previous node is not a paragraph node or
    // 3. previous node is a paragraph node but not empty
    final isNotEmptyParagraphNode = previous == null ||
        previous.type != ParagraphBlockKeys.type ||
        (previous.delta?.toPlainText().isNotEmpty ?? false);

    if (isNotEmptyParagraphNode) {
      final path = aiWriterNode.path;
      final transaction = editorState.transaction;
      selection = Selection.collapsed(Position(path: path));
      transaction
        ..insertNode(
          path,
          paragraphNode(),
        )
        ..afterSelection = selection;
      await editorState.apply(transaction);
    } else {
      selection = Selection.collapsed(Position(path: previous.path));
    }

    final transaction = editorState.transaction;
    transaction.updateNode(aiWriterNode, {
      AIWriterBlockKeys.startSelection: selection.toJson(),
    });
    transaction.afterSelection = selection;
    await editorState.apply(
      transaction,
      options: const ApplyOptions(inMemoryUpdate: true),
    );
  }

  /// Discard the current response and delete the previous node.
  Future<void> discardCurrentResponse({
    required Node aiWriterNode,
    Selection? selection,
  }) async {
    if (selection != null) {
      final start = selection.start.path;
      final end = aiWriterNode.previous?.path;
      if (end != null) {
        final transaction = editorState.transaction;
        transaction.deleteNodesAtPath(
          start,
          end.last - start.last + 1,
        );
        await editorState.apply(transaction);
        await ensurePreviousNodeIsEmptyParagraphNode();
      }
    }
  }

  /// Remove the ai writer node from the editor.
  Future<void> removeAIWriterNode(Node aiWriterNode) async {
    final transaction = editorState.transaction;
    transaction.deleteNode(aiWriterNode);
    await editorState.apply(
      transaction,
      options: const ApplyOptions(inMemoryUpdate: true),
    );
  }
}
