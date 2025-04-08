import 'dart:convert';

import 'package:appflowy/plugins/document/presentation/editor_plugins/numbered_list/numbered_list_icon.dart';
import 'package:appflowy/shared/markdown_to_document.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
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

  /// Selection before the refresh.
  Selection? _previousSelection;

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
    Selection? previousSelection,
    Position? position,
  }) {
    _insertPosition = position ?? editorState.selection?.start;
    _previousSelection = previousSelection ?? editorState.selection;

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
  Future<void> persist({
    String? markdownText,
  }) async {
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

  /// Replace the selected content with the AI's response
  Future<void> replace({
    required Selection selection,
    required String markdownText,
  }) async {
    if (selection.isSingle) {
      await _replaceInSameLine(
        selection: selection,
        markdownText: markdownText,
      );
    } else {
      await _replaceInMultiLines(
        selection: selection,
        markdownText: markdownText,
      );
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

    // check if the first selected node before the refresh is a numbered list node
    final previousSelection = _previousSelection;
    final previousSelectedNode = previousSelection == null
        ? null
        : editorState.getNodeAtPath(previousSelection.start.path);
    final firstNodeIsNumberedList = previousSelectedNode != null &&
        previousSelectedNode.type == NumberedListBlockKeys.type;

    final newNodes = attributes == null
        ? documentNodes
        : documentNodes.mapIndexed((index, node) {
            final n = _styleDelta(node: node, attributes: attributes);
            n.externalValues = AINodeExternalValues(
              isAINode: true,
            );
            if (index == 0 && n.type == NumberedListBlockKeys.type) {
              if (firstNodeIsNumberedList) {
                final builder = NumberedListIndexBuilder(
                  editorState: editorState,
                  node: previousSelectedNode,
                );
                final firstIndex = builder.indexInSameLevel;
                n.updateAttributes({
                  NumberedListBlockKeys.number: firstIndex,
                });
              }

              n.externalValues = AINodeExternalValues(
                isAINode: true,
                isFirstNumberedListNode: true,
              );
            }
            return n;
          }).toList();

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

  /// If the selected content is in the same line,
  /// keep the selected node and replace the delta.
  Future<void> _replaceInSameLine({
    required Selection selection,
    required String markdownText,
  }) async {
    selection = selection.normalized;

    // If the selection is not a single node, do nothing.
    if (!selection.isSingle) {
      assert(false, 'Expected single node selection');
      Log.error('Expected single node selection');
      return;
    }

    final startIndex = selection.startIndex;
    final endIndex = selection.endIndex;
    final length = endIndex - startIndex;

    // Get the selected node.
    final node = editorState.getNodeAtPath(selection.start.path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      assert(false, 'Expected non-null node and delta');
      Log.error('Expected non-null node and delta');
      return;
    }

    // Convert the markdown text to delta.
    final decoder = DeltaMarkdownDecoder();
    final markdownDelta = decoder.convert(markdownText);

    // Replace the delta of the selected node.
    final transaction = editorState.transaction;
    transaction
      ..deleteText(node, startIndex, length)
      ..insertTextDelta(node, startIndex, markdownDelta);
    await editorState.apply(transaction);
  }

  /// If the selected content is in multiple lines
  Future<void> _replaceInMultiLines({
    required Selection selection,
    required String markdownText,
  }) async {
    selection = selection.normalized;

    // If the selection is a single node, do nothing.
    if (selection.isSingle) {
      assert(false, 'Expected multi-line selection');
      Log.error('Expected multi-line selection');
      return;
    }

    // Get the selected nodes.
    final nodes = editorState.getNodesInSelection(selection);

    // Replace the delta of the selected nodes.
  }
}

class AINodeExternalValues extends NodeExternalValues {
  const AINodeExternalValues({
    this.isAINode = false,
    this.isFirstNumberedListNode = false,
  });

  final bool isAINode;
  final bool isFirstNumberedListNode;
}
