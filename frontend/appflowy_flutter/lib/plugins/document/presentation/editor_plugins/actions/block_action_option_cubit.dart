import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_notification.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/shared/share/constants.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlockActionOptionState {}

class BlockActionOptionCubit extends Cubit<BlockActionOptionState> {
  BlockActionOptionCubit({
    required this.editorState,
    required this.blockComponentBuilder,
  }) : super(BlockActionOptionState());

  final EditorState editorState;
  final Map<String, BlockComponentBuilder> blockComponentBuilder;

  Future<void> handleAction(OptionAction action, Node node) async {
    final transaction = editorState.transaction;
    switch (action) {
      case OptionAction.delete:
        transaction.deleteNode(node);
        break;
      case OptionAction.duplicate:
        await _duplicateBlock(transaction, node);
        EditorNotification.paste().post();

        break;
      case OptionAction.moveUp:
        transaction.moveNode(node.path.previous, node);
        break;
      case OptionAction.moveDown:
        transaction.moveNode(node.path.next.next, node);
        break;
      case OptionAction.copyLinkToBlock:
        await _copyLinkToBlock(node);
        break;
      case OptionAction.align:
      case OptionAction.color:
      case OptionAction.divider:
      case OptionAction.depth:
      case OptionAction.turnInto:
        throw UnimplementedError();
    }

    await editorState.apply(transaction);
  }

  Future<void> _duplicateBlock(Transaction transaction, Node node) async {
    final type = node.type;
    final builder = editorState.renderer.blockComponentBuilder(type);

    if (builder == null) {
      Log.error('Block type $type is not supported');
      return;
    }

    final valid = builder.validate(node);
    if (!valid) {
      Log.error('Block type $type is not valid');
    }

    transaction.insertNode(node.path.next, _copyBlock(node));
  }

  Node _copyBlock(Node node) {
    Node copiedNode = node.copyWith();

    final type = node.type;
    final builder = editorState.renderer.blockComponentBuilder(type);

    if (builder == null) {
      Log.error('Block type $type is not supported');
    } else {
      final valid = builder.validate(node);
      if (!valid) {
        Log.error('Block type $type is not valid');
        if (node.type == TableBlockKeys.type) {
          copiedNode = _fixTableBlock(node);
        }
      }
    }

    return copiedNode;
  }

  Node _fixTableBlock(Node node) {
    if (node.type != TableBlockKeys.type) {
      return node;
    }

    // the table node should contains colsLen and rowsLen
    final colsLen = node.attributes[TableBlockKeys.colsLen];
    final rowsLen = node.attributes[TableBlockKeys.rowsLen];
    if (colsLen == null || rowsLen == null) {
      return node;
    }

    final newChildren = <Node>[];
    final children = node.children;

    // based on the colsLen and rowsLen, iterate the children and fix the data
    for (var i = 0; i < rowsLen; i++) {
      for (var j = 0; j < colsLen; j++) {
        final cell = children
            .where(
              (n) =>
                  n.attributes[TableCellBlockKeys.rowPosition] == i &&
                  n.attributes[TableCellBlockKeys.colPosition] == j,
            )
            .firstOrNull;
        if (cell != null) {
          newChildren.add(cell.copyWith());
        } else {
          newChildren.add(
            tableCellNode('', i, j),
          );
        }
      }
    }

    return node.copyWith(
      children: newChildren,
      attributes: {
        ...node.attributes,
        TableBlockKeys.colsLen: colsLen,
        TableBlockKeys.rowsLen: rowsLen,
      },
    );
  }

  Future<void> _copyLinkToBlock(Node node) async {
    final context = editorState.document.root.context;
    final viewId = context?.read<DocumentBloc>().documentId;
    if (viewId == null) {
      return;
    }

    final workspace = await FolderEventReadCurrentWorkspace().send();
    final workspaceId = workspace.fold(
      (l) => l.id,
      (r) => '',
    );

    if (workspaceId.isEmpty || viewId.isEmpty) {
      Log.error('Failed to get workspace id: $workspaceId or view id: $viewId');
      emit(BlockActionOptionState()); // Emit a new state to trigger UI update
      return;
    }

    final link = ShareConstants.buildShareUrl(
      workspaceId: workspaceId,
      viewId: viewId,
      blockId: node.id,
    );
    await getIt<ClipboardService>().setData(
      ClipboardServiceData(plainText: link),
    );

    emit(BlockActionOptionState()); // Emit a new state to trigger UI update
  }

  Future<bool> turnIntoBlock(
    String type,
    Node node, {
    int? level,
  }) async {
    final selection = editorState.selection;
    if (selection == null) {
      return false;
    }

    final toType = type;

    // only handle the node in the same depth
    final selectedNodes = editorState
        .getNodesInSelection(selection.normalized)
        .where((e) => e.path.length == node.path.length)
        .toList();
    Log.info('turnIntoBlock selectedNodes $selectedNodes');

    // try to turn into a single toggle heading block
    if (await turnIntoSingleToggleHeading(
      type: toType,
      selectedNodes: selectedNodes,
      level: level,
    )) {
      return true;
    }

    final insertedNode = <Node>[];

    for (final node in selectedNodes) {
      Log.info(
        'Turn into block: from ${node.type} to $type',
      );

      Node afterNode = node.copyWith(
        type: type,
        attributes: {
          if (toType == HeadingBlockKeys.type) HeadingBlockKeys.level: level,
          if (toType == ToggleListBlockKeys.type)
            ToggleListBlockKeys.level: level,
          if (toType == TodoListBlockKeys.type)
            TodoListBlockKeys.checked: false,
          blockComponentBackgroundColor:
              node.attributes[blockComponentBackgroundColor],
          blockComponentTextDirection:
              node.attributes[blockComponentTextDirection],
          blockComponentDelta: (node.delta ?? Delta()).toJson(),
        },
      );

      // heading block and callout block should not have children
      if ([HeadingBlockKeys.type, CalloutBlockKeys.type, QuoteBlockKeys.type]
          .contains(toType)) {
        afterNode = afterNode.copyWith(
          children: [],
        );
        insertedNode.add(afterNode);
        insertedNode.addAll(node.children.map((e) => e.copyWith()));
      } else if (!EditorOptionActionType.turnInto.supportTypes
          .contains(node.type)) {
        afterNode = node.copyWith();
        insertedNode.add(afterNode);
      } else {
        insertedNode.add(afterNode);
      }
    }

    final transaction = editorState.transaction;
    transaction.insertNodes(
      node.path,
      insertedNode,
    );
    transaction.deleteNodes(selectedNodes);
    await editorState.apply(transaction);

    return true;
  }

  // turn a single node into toggle heading block
  // 1. find the sibling nodes after the selected node until
  //  meet the first node that contains level and its value is greater or equal to the level
  // 2. move the found nodes in the selected node
  //
  // example:
  // Toggle Heading 1 <- selected node
  // - bulleted item 1
  // - bulleted item 2
  // - bulleted item 3
  // Heading 1
  // - paragraph 1
  // - paragraph 2
  // when turning "Toggle Heading 1" into toggle heading, the bulleted items will be moved into the toggle heading
  Future<bool> turnIntoSingleToggleHeading({
    required String type,
    required List<Node> selectedNodes,
    int? level,
    Delta? delta,
    Selection? afterSelection,
  }) async {
    // only support turn a single node into toggle heading block
    if (type != ToggleListBlockKeys.type ||
        selectedNodes.length != 1 ||
        level == null) {
      return false;
    }

    // find the sibling nodes after the selected node until
    final insertedNodes = <Node>[];
    final node = selectedNodes.first;
    Path path = node.path.next;
    Node? nextNode = editorState.getNodeAtPath(path);
    while (nextNode != null) {
      if (nextNode.type == HeadingBlockKeys.type &&
          nextNode.attributes[HeadingBlockKeys.level] != null &&
          nextNode.attributes[HeadingBlockKeys.level]! <= level) {
        break;
      }

      if (nextNode.type == ToggleListBlockKeys.type &&
          nextNode.attributes[ToggleListBlockKeys.level] != null &&
          nextNode.attributes[ToggleListBlockKeys.level]! <= level) {
        break;
      }

      insertedNodes.add(nextNode);

      path = path.next;
      nextNode = editorState.getNodeAtPath(path);
    }

    Log.info('insertedNodes $insertedNodes');

    Log.info(
      'Turn into block: from ${node.type} to $type',
    );

    final afterNode = node.copyWith(
      type: type,
      attributes: {
        ToggleListBlockKeys.level: level,
        ToggleListBlockKeys.collapsed:
            node.attributes[ToggleListBlockKeys.collapsed] ?? false,
        blockComponentBackgroundColor:
            node.attributes[blockComponentBackgroundColor],
        blockComponentTextDirection:
            node.attributes[blockComponentTextDirection],
        blockComponentDelta: (delta ?? node.delta ?? Delta()).toJson(),
      },
      children: [
        ...node.children,
        ...insertedNodes.map((e) => e.copyWith()),
      ],
    );

    final transaction = editorState.transaction;
    transaction.insertNode(
      node.path,
      afterNode,
    );
    transaction.deleteNodes([
      node,
      ...insertedNodes,
    ]);
    if (afterSelection != null) {
      transaction.afterSelection = afterSelection;
    }
    await editorState.apply(transaction);

    return true;
  }

  Selection? calculateTurnIntoSelection(
    Node selectedNode,
    Selection? beforeSelection,
  ) {
    final path = selectedNode.path;
    final selection = Selection.collapsed(
      Position(path: path),
    );

    // if the previous selection is null or the start path is not in the same level as the current block path,
    // then update the selection with the current block path
    // for example,'|' means the selection,
    // case 1: collapsed selection
    // - bulleted item 1
    // - bulleted |item 2
    // when clicking the bulleted item 1, the bulleted item 1 path should be selected
    // case 2: not collapsed selection
    // - bulleted item 1
    // - bulleted |item 2
    // - bulleted |item 3
    // when clicking the bulleted item 1, the bulleted item 1 path should be selected
    if (beforeSelection == null ||
        beforeSelection.start.path.length != path.length ||
        !path.inSelection(beforeSelection)) {
      return selection;
    }
    // if the beforeSelection start with the current block,
    //  then updating the selection with the beforeSelection that may contains multiple blocks
    return beforeSelection;
  }
}
