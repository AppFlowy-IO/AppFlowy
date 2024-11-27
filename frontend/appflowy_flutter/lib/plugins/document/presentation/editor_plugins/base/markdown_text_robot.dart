import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:synchronized/synchronized.dart';

class MarkdownTextRobot {
  MarkdownTextRobot({
    required this.editorState,
  });

  final EditorState editorState;
  final Lock lock = Lock();

  // The selection before the text robot is ready.
  Selection? _selection;

  // The markdown text to be inserted.
  String _markdownText = '';

  // The nodes inserted in the previous refresh.
  Iterable<Node> _previousInsertedNodes = [];

  // Must call this function before using the text robot.
  void start() {
    _selection = editorState.selection;

    Log.info('MarkdownTextRobot prepare, current selection: $_selection');
  }

  Future<void> appendMarkdownText(String text) async {
    _markdownText += text;

    await lock.synchronized(() async {
      await _refresh();
    });
  }

  Future<void> stop() async {
    _markdownText = '';

    // persist the markdown text
  }

  Future<void> _refresh() async {
    final selection = _selection;
    if (selection == null) {
      return;
    }

    debugPrint('MarkdownTextRobot refresh, markdownText: $_markdownText');

    final document = markdownToDocument(_markdownText);

    // deep copy the nodes to avoid the linked entities being changed.
    final nodes = document.root.children.map((node) => node.copyWith());

    // 1. remove the nodes inserted in the previous refresh.
    // 2. insert the new nodes.
    final transaction = editorState.transaction;
    final start = selection.start;
    if (_previousInsertedNodes.isNotEmpty) {
      transaction.deleteNodesAtPath(start.path, _previousInsertedNodes.length);
    }
    transaction.insertNodes(start.path, nodes);
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
