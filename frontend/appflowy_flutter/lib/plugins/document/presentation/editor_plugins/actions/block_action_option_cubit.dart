import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/sub_page/sub_page_block_component.dart';
import 'package:appflowy/plugins/shared/share/constants.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
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

    Node newNode = _copyBlock(node);

    if (node.type == SubPageBlockKeys.type) {
      final viewId = await _handleDuplicateSubPage(node);
      if (viewId == null) {
        return;
      }

      newNode = newNode.copyWith(attributes: {SubPageBlockKeys.viewId: viewId});
    }

    transaction.insertNode(node.path.next, newNode);
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

  Future<String?> _handleDuplicateSubPage(Node node) async {
    final viewId = node.attributes[SubPageBlockKeys.viewId];
    if (viewId == null) {
      return null;
    }

    final view = (await ViewBackendService.getView(viewId)).toNullable();
    if (view == null) {
      return null;
    }

    final result = await ViewBackendService.duplicate(
      view: view,
      openAfterDuplicate: false,
      includeChildren: true,
      parentViewId: view.parentViewId,
      syncAfterDuplicate: true,
    );

    return result.fold(
      (view) => view.id,
      (error) {
        Log.error(error);
        emit(BlockActionOptionState()); // Emit a new state to trigger UI update
        return null;
      },
    );
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

    final selectedNodes = editorState.getNodesInSelection(selection.normalized);
    Log.info('turnIntoBlock selectedNodes $selectedNodes');

    final insertedNode = <Node>[];

    for (final node in selectedNodes) {
      Log.info(
        'Turn into block: from ${node.type} to $type',
      );

      Node afterNode = node.copyWith(
        type: type,
        attributes: {
          if (toType == HeadingBlockKeys.type) HeadingBlockKeys.level: level,
          if (toType == TodoListBlockKeys.type)
            TodoListBlockKeys.checked: false,
          blockComponentBackgroundColor:
              node.attributes[blockComponentBackgroundColor],
          blockComponentTextDirection:
              node.attributes[blockComponentTextDirection],
          blockComponentDelta: (node.delta ?? Delta()).toJson(),
        },
      );

      insertedNode.add(afterNode);

      // heading block and callout block should not have children
      if ([HeadingBlockKeys.type, CalloutBlockKeys.type].contains(toType)) {
        afterNode = afterNode.copyWith(
          children: [],
        );
        insertedNode.addAll(node.children.map((e) => e.copyWith()));
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
}
