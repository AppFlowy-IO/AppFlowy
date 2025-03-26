import 'dart:convert';

import 'package:appflowy/shared/markdown_to_document.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:synchronized/synchronized.dart';

const _enableDebug = false;

class MarkdownTextRobot {
  MarkdownTextRobot({
    required this.editorState,
  });

  final EditorState editorState;

  final Lock _lock = Lock();

  /// The text position where new nodes will be inserted
  Position? _insertPosition;

  /// The markdown text to be inserted
  String _markdownText = '';

  /// The nodes inserted in the previous refresh.
  Iterable<Node> _insertedNodes = [];

  /// Only for debug via [_enableDebug].
  final List<String> _debugMarkdownTexts = [];

  bool get hasAnyResult => _markdownText.isNotEmpty;

  String get markdownText => _markdownText;

  Selection? getInsertedSelection() {
    final position = _insertPosition;
    if (position == null) {
      Log.error("Expected non-null insert markdown text position");
      return null;
    }

    if (_insertedNodes.isEmpty) {
      return Selection.collapsed(position);
    }
    return Selection(
      start: position,
      end: Position(
        path: position.path.nextNPath(_insertedNodes.length - 1),
      ),
    );
  }

  List<Node> getInsertedNodes() {
    final selection = getInsertedSelection();
    return selection == null ? [] : editorState.getNodesInSelection(selection);
  }

  void start({
    Position? position,
  }) {
    _insertPosition = position ?? editorState.selection?.start;

    if (_enableDebug) {
      Log.info(
        'MarkdownTextRobot start with insert text position: $_insertPosition',
      );
    }
  }

  /// The text will be inserted into the document but only in memory
  Future<void> appendMarkdownText(
    String text, {
    bool updateSelection = true,
    Map<String, dynamic>? attributes,
  }) async {
    _markdownText += text;

    await _lock.synchronized(() async {
      await _refresh(
        inMemoryUpdate: true,
        updateSelection: updateSelection,
        attributes: attributes,
      );
    });

    if (_enableDebug) {
      _debugMarkdownTexts.add(text);
      Log.info(
        'MarkdownTextRobot receive markdown: ${jsonEncode(_debugMarkdownTexts)}',
      );
    }
  }

  Future<void> stop({
    Map<String, dynamic>? attributes,
  }) async {
    await _lock.synchronized(() async {
      await _refresh(
        inMemoryUpdate: true,
        attributes: attributes,
      );
    });
  }

  /// Persist the text into the document
  Future<void> persist({String? markdownText}) async {
    if (markdownText != null) {
      _markdownText = markdownText;
    }
    await _lock.synchronized(() async {
      await _refresh(inMemoryUpdate: false);
    });

    if (_enableDebug) {
      Log.info('MarkdownTextRobot stop');
      _debugMarkdownTexts.clear();
    }
  }

  /// Discard the inserted content
  Future<void> discard() async {
    final start = _insertPosition;
    if (start == null) {
      return;
    }
    if (_insertedNodes.isEmpty) {
      return;
    }

    // fallback to the calculated position if the selection is null.
    final end = Position(
      path: start.path.nextNPath(_insertedNodes.length - 1),
    );
    final deletedNodes = editorState.getNodesInSelection(
      Selection(start: start, end: end),
    );
    final transaction = editorState.transaction
      ..deleteNodes(deletedNodes)
      ..afterSelection = Selection.collapsed(start);

    await editorState.apply(
      transaction,
      options: const ApplyOptions(recordUndo: false, inMemoryUpdate: true),
    );

    if (_enableDebug) {
      Log.info('MarkdownTextRobot discard');
    }
  }

  void clear() {
    _markdownText = '';
    _insertedNodes = [];
  }

  void reset() {
    _insertPosition = null;
  }

  Future<void> _refresh({
    required bool inMemoryUpdate,
    bool updateSelection = false,
    Map<String, dynamic>? attributes,
  }) async {
    final position = _insertPosition;
    if (position == null) {
      Log.error("Expected non-null insert markdown text position");
      return;
    }

    // Convert markdown and deep copy the nodes, prevent ing the linked
    // entities from being changed
    final documentNodes = customMarkdownToDocument(
      _markdownText,
      tableWidth: 250.0,
    ).root.children;

    final newNodes = attributes == null
        ? documentNodes
        : documentNodes
            .map((node) => _styleDelta(node: node, attributes: attributes))
            .toList();

    if (newNodes.isEmpty) {
      return;
    }

    final deleteTransaction = editorState.transaction
      ..deleteNodes(getInsertedNodes());

    await editorState.apply(
      deleteTransaction,
      options: ApplyOptions(
        inMemoryUpdate: inMemoryUpdate,
        recordUndo: false,
      ),
    );

    final insertTransaction = editorState.transaction
      ..insertNodes(position.path, newNodes);

    final lastDelta = newNodes.lastOrNull?.delta;
    if (lastDelta != null) {
      insertTransaction.afterSelection = Selection.collapsed(
        Position(
          path: position.path.nextNPath(newNodes.length - 1),
          offset: lastDelta.length,
        ),
      );
    }

    await editorState.apply(
      insertTransaction,
      options: ApplyOptions(
        inMemoryUpdate: inMemoryUpdate,
        recordUndo: !inMemoryUpdate,
      ),
      withUpdateSelection: updateSelection,
    );

    _insertedNodes = newNodes;
  }

  Node _styleDelta({
    required Node node,
    required Map<String, dynamic> attributes,
  }) {
    if (node.delta != null) {
      final delta = node.delta!;
      final attributeDelta = Delta()
        ..retain(delta.length, attributes: attributes);
      final newDelta = delta.compose(attributeDelta);
      final newAttributes = node.attributes;
      newAttributes['delta'] = newDelta.toJson();
      node.updateAttributes(newAttributes);
    }

    List<Node>? children;
    if (node.children.isNotEmpty) {
      children = node.children
          .map((child) => _styleDelta(node: child, attributes: attributes))
          .toList();
    }

    return node.copyWith(
      children: children,
    );
  }
}
