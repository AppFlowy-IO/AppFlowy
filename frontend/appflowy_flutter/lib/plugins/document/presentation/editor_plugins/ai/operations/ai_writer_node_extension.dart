import 'package:appflowy/shared/markdown_to_document.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

import '../ai_writer_block_component.dart';
import 'ai_writer_entities.dart';

extension AiWriterExtension on Node {
  bool get isAiWriterInitialized {
    return attributes[AiWriterBlockKeys.isInitialized];
  }

  Selection? get aiWriterSelection {
    final selection = attributes[AiWriterBlockKeys.selection];
    if (selection == null) {
      return null;
    }
    return Selection.fromJson(selection);
  }

  AiWriterCommand get aiWriterCommand {
    final index = attributes[AiWriterBlockKeys.command];
    return AiWriterCommand.values[index];
  }
}

extension AiWriterNodeExtension on EditorState {
  Future<String> getMarkdownInSelection(Selection? selection) async {
    selection ??= this.selection?.normalized;
    if (selection == null || selection.isCollapsed) {
      return '';
    }

    // if the selected nodes are not entirely selected, slice the nodes
    final slicedNodes = <Node>[];
    final nodes = getNodesInSelection(selection);

    for (final node in nodes) {
      final delta = node.delta;
      if (delta == null) {
        continue;
      }

      final slicedDelta = delta.slice(
        node == nodes.first ? selection.startIndex : 0,
        node == nodes.last ? selection.endIndex : delta.length,
      );

      final copiedNode = node.copyWith(
        attributes: {
          ...node.attributes,
          blockComponentDelta: slicedDelta.toJson(),
        },
      );

      slicedNodes.add(copiedNode);
    }

    final markdown = await customDocumentToMarkdown(
      Document.blank()..insert([0], slicedNodes),
    );

    return markdown;
  }

  List<String> getPlainTextInSelection(Selection? selection) {
    selection ??= this.selection?.normalized;
    if (selection == null || selection.isCollapsed) {
      return [];
    }

    final res = <String>[];
    if (selection.isCollapsed) {
      return res;
    }

    final nodes = getNodesInSelection(selection);

    for (final node in nodes) {
      final delta = node.delta;
      if (delta == null) {
        continue;
      }
      final startIndex = node == nodes.first ? selection.startIndex : 0;
      final endIndex = node == nodes.last ? selection.endIndex : delta.length;
      res.add(delta.slice(startIndex, endIndex).toPlainText());
    }

    return res;
  }
}
