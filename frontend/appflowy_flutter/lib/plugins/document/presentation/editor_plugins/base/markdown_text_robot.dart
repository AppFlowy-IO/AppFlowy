import 'dart:convert';

import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:synchronized/synchronized.dart';

class MarkdownTextRobot {
  MarkdownTextRobot({
    required this.editorState,
    this.enableDebug = true,
  });

  final EditorState editorState;
  final bool enableDebug;

  final Lock lock = Lock();

  // The selection before the text robot is ready.
  Selection? _startSelection;

  // The markdown text to be inserted.
  String _markdownText = '';

  // Only for debug. Enable by [enableDebug].
  @visibleForTesting
  final List<String> debugMarkdownTexts = [];

  // The nodes inserted in the previous refresh.
  Iterable<Node> _previousInsertedNodes = [];

  /// Start the text robot.
  ///
  /// Must call this function before using the text robot.
  void start() {
    _startSelection = editorState.selection;

    if (enableDebug) {
      Log.info(
        'MarkdownTextRobot prepare, current selection: $_startSelection',
      );
    }
  }

  /// Append the markdown text to the text robot.
  Future<void> appendMarkdownText(String text) async {
    _markdownText += text;

    await lock.synchronized(() async {
      await _refresh();
    });

    if (enableDebug) {
      debugMarkdownTexts.add(text);
      Log.info('debug markdown texts: ${jsonEncode(debugMarkdownTexts)}');
    }
  }

  /// Stop the text robot.
  Future<void> stop() async {
    _markdownText = '';

    if (enableDebug) {
      Log.info(
        'debug markdown texts: ${jsonEncode(debugMarkdownTexts)}',
      );
      debugMarkdownTexts.clear();
    }

    // persist the markdown text
  }

  /// Refreshes the editor state with the current markdown text by:
  ///
  /// 1. Converting markdown to document nodes
  /// 2. Replacing previously inserted nodes with new nodes
  /// 3. Updating selection position
  Future<void> _refresh() async {
    final start = _startSelection?.start;
    if (start == null) {
      return;
    }

    final transaction = editorState.transaction;

    // Convert markdown and deep copy nodes
    final nodes = markdownToDocument(_markdownText).root.children.map(
          (node) => node.copyWith(),
        ); // deep copy the nodes to avoid the linked entities being changed.

    // Insert new nodes at selection start
    transaction.insertNodes(start.path, nodes);

    // Remove previously inserted nodes if they exist
    if (_previousInsertedNodes.isNotEmpty) {
      // fallback to the calculated position if the selection is null.
      final end = editorState.selection?.end ??
          Position(
            path: start.path.nextNPath(_previousInsertedNodes.length - 1),
          );
      final deletedNodes = editorState.getNodesInSelection(
        Selection(start: start, end: end),
      );
      transaction.deleteNodes(deletedNodes);
    }

    // Update selection to end of inserted content if it contains text
    final lastDelta = nodes.lastOrNull?.delta;
    if (lastDelta != null) {
      transaction.afterSelection = Selection.collapsed(
        Position(
          path: start.path.nextNPath(nodes.length - 1),
          offset: nodes.last.delta!.length,
        ),
      );
    }

    await editorState.apply(
      transaction,
      options: const ApplyOptions(
        inMemoryUpdate: true,
        recordUndo: false,
      ),
    );

    _previousInsertedNodes = nodes;
  }
}
