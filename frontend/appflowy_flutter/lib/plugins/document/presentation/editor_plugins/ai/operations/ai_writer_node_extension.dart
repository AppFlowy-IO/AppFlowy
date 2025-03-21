import 'package:appflowy/plugins/document/presentation/editor_plugins/parsers/document_markdown_parsers.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/parsers/sub_page_node_parser.dart';
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

  /// Determines whether the document is empty up to the selection
  ///
  /// If empty and the title is also empty, the continue writing option will be disabled.
  bool isEmptyForContinueWriting({
    Selection? selection,
  }) {
    if (selection != null && !selection.isCollapsed) {
      return false;
    }

    final effectiveSelection = Selection(
      start: Position(path: [0]),
      end: selection?.normalized.end ??
          this.selection?.normalized.end ??
          Position(path: getLastSelectable()?.$1.path ?? [0]),
    );

    // if the selected nodes are not entirely selected, slice the nodes
    final slicedNodes = <Node>[];
    final nodes = getNodesInSelection(effectiveSelection);

    for (final node in nodes) {
      final delta = node.delta;
      if (delta == null) {
        continue;
      }

      final slicedDelta = delta.slice(
        node == nodes.first ? effectiveSelection.startIndex : 0,
        node == nodes.last ? effectiveSelection.endIndex : delta.length,
      );

      final copiedNode = node.copyWith(
        attributes: {
          ...node.attributes,
          blockComponentDelta: slicedDelta.toJson(),
        },
      );

      slicedNodes.add(copiedNode);
    }

    // using less custom parsers to avoid futures
    final markdown = documentToMarkdown(
      Document.blank()..insert([0], slicedNodes),
      customParsers: [
        const MathEquationNodeParser(),
        const CalloutNodeParser(),
        const ToggleListNodeParser(),
        const CustomParagraphNodeParser(),
        const SubPageNodeParser(),
        const SimpleTableNodeParser(),
        const LinkPreviewNodeParser(),
        const FileBlockNodeParser(),
      ],
    );

    return markdown.trim().isEmpty;
  }
}
