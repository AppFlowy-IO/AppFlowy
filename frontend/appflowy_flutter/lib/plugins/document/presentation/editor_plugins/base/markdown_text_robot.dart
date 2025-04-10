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

  /// Delete the temporary inserted AI nodes
  Future<void> deleteAINodes() async {
    final nodes = getInsertedNodes();
    final transaction = editorState.transaction..deleteNodes(nodes);
    await editorState.apply(
      transaction,
      options: const ApplyOptions(recordUndo: false),
    );
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
    if (markdownText.isEmpty) {
      assert(false, 'Expected non-empty markdown text');
      Log.error('Expected non-empty markdown text');
      return;
    }

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
    // Question: Why we need to convert the markdown to document first?
    // Answer: Because the markdown text may contain the list item,
    // if we convert the markdown to delta directly, the list item will be
    // treated as a normal text node, and the delta will be incorrect.
    // For example, the markdown text is:
    // ```
    // 1. item1
    // ```
    // if we convert the markdown to delta directly, the delta will be:
    // ```
    // [
    //   {
    //     "insert": "1. item1"
    //   }
    // ]
    // ```
    // if we convert the markdown to document first, the document will be:
    // ```
    // [
    //   {
    //     "type": "numbered_list",
    //     "children": [
    //       {
    //         "insert": "item1"
    //       }
    //     ]
    //   }
    // ]
    final document = customMarkdownToDocument(markdownText);
    final nodes = document.root.children;
    final decoder = DeltaMarkdownDecoder();
    final markdownDelta =
        nodes.firstOrNull?.delta ?? decoder.convert(markdownText);

    if (markdownDelta.isEmpty) {
      assert(false, 'Expected non-empty markdown delta');
      Log.error('Expected non-empty markdown delta');
      return;
    }

    // Replace the delta of the selected node.
    final transaction = editorState.transaction;

    // it means the user selected the entire sentence, we just replace the node
    if (startIndex == 0 && length == node.delta?.length) {
      transaction
        ..insertNodes(node.path.next, nodes)
        ..deleteNode(node);
    } else {
      // it means the user selected a part of the sentence, we need to delete the
      // selected part and insert the new delta.
      transaction
        ..deleteText(node, startIndex, length)
        ..insertTextDelta(node, startIndex, markdownDelta);

      // Add the remaining nodes to the document.
      final remainingNodes = nodes.skip(1);
      if (remainingNodes.isNotEmpty) {
        transaction.insertNodes(
          node.path.next,
          remainingNodes,
        );
      }
    }

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

    final markdownNodes = customMarkdownToDocument(
      markdownText,
      tableWidth: 250.0,
    ).root.children;

    // Get the selected nodes.
    final nodes = editorState.getNodesInSelection(selection);

    // Note: Don't change its order, otherwise the delta will be incorrect.
    // step 1. merge the first selected node and the first node from the ai response
    // step 2. merge the last selected node and the last node from the ai response
    // step 3. insert the middle nodes from the ai response
    // step 4. delete the middle nodes
    final transaction = editorState.transaction;

    // step 1
    final firstNode = nodes.firstOrNull;
    final delta = firstNode?.delta;
    final firstMarkdownNode = markdownNodes.firstOrNull;
    final firstMarkdownDelta = firstMarkdownNode?.delta;
    if (firstNode != null &&
        delta != null &&
        firstMarkdownNode != null &&
        firstMarkdownDelta != null) {
      final startIndex = selection.startIndex;
      final length = delta.length - startIndex;

      transaction
        ..deleteText(firstNode, startIndex, length)
        ..insertTextDelta(firstNode, startIndex, firstMarkdownDelta);
    }

    // step 2
    final lastNode = nodes.lastOrNull;
    final lastDelta = lastNode?.delta;
    final lastMarkdownNode = markdownNodes.lastOrNull;
    final lastMarkdownDelta = lastMarkdownNode?.delta;
    if (lastNode != null &&
        lastDelta != null &&
        lastMarkdownNode != null &&
        lastMarkdownDelta != null) {
      final endIndex = selection.endIndex;

      transaction.deleteText(lastNode, 0, endIndex);

      // if the last node is same as the first node, it means we have replaced the
      // selected text in the first node.
      if (lastMarkdownNode.id != firstMarkdownNode?.id) {
        transaction.insertTextDelta(lastNode, 0, lastMarkdownDelta);
      }
    }

    // step 3
    final insertedPath = selection.start.path.nextNPath(1);
    if (markdownNodes.length > 2) {
      transaction.insertNodes(
        insertedPath,
        markdownNodes.skip(1).take(markdownNodes.length - 2).toList(),
      );
    }

    // step 4
    final length = nodes.length - 2;
    if (length > 0) {
      final middleNodes = nodes.skip(1).take(length).toList();
      transaction.deleteNodes(middleNodes);
    }

    await editorState.apply(transaction);
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
