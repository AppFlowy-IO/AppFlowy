import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/option_action.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/sub_page/sub_page_block_component.dart';
import 'package:appflowy/plugins/shared/share/constants.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/snap_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import 'drag_to_reorder/draggable_option_button.dart';

class BlockOptionButton extends StatefulWidget {
  const BlockOptionButton({
    super.key,
    required this.blockComponentContext,
    required this.blockComponentState,
    required this.actions,
    required this.editorState,
    required this.blockComponentBuilder,
  });

  final BlockComponentContext blockComponentContext;
  final BlockComponentActionState blockComponentState;
  final List<OptionAction> actions;
  final EditorState editorState;
  final Map<String, BlockComponentBuilder> blockComponentBuilder;

  @override
  State<BlockOptionButton> createState() => _BlockOptionButtonState();
}

class _BlockOptionButtonState extends State<BlockOptionButton> {
  late final List<PopoverAction> popoverActions;

  @override
  void initState() {
    super.initState();

    popoverActions = widget.actions.map((e) {
      switch (e) {
        case OptionAction.divider:
          return DividerOptionAction();
        case OptionAction.color:
          return ColorOptionAction(editorState: widget.editorState);
        case OptionAction.align:
          return AlignOptionAction(editorState: widget.editorState);
        case OptionAction.depth:
          return DepthOptionAction(editorState: widget.editorState);
        default:
          return OptionActionWrapper(e);
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return PopoverActionList<PopoverAction>(
      popoverMutex: PopoverMutex(),
      actions: popoverActions,
      animationDuration: const Duration(milliseconds: 200),
      slideDistance: 5,
      direction:
          context.read<AppearanceSettingsCubit>().state.layoutDirection ==
                  LayoutDirection.rtlLayout
              ? PopoverDirection.rightWithCenterAligned
              : PopoverDirection.leftWithCenterAligned,
      onPopupBuilder: () {
        keepEditorFocusNotifier.increase();
        widget.blockComponentState.alwaysShowActions = true;
      },
      onClosed: () {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (!mounted) {
            return;
          }
          widget.editorState.selectionType = null;
          widget.editorState.selection = null;
          widget.blockComponentState.alwaysShowActions = false;
          keepEditorFocusNotifier.decrease();
        });
      },
      onSelected: (action, controller) {
        if (action is OptionActionWrapper) {
          _onSelectAction(context, action.inner);
          controller.close();
        }
      },
      buildChild: (controller) => DraggableOptionButton(
        controller: controller,
        editorState: widget.editorState,
        blockComponentContext: widget.blockComponentContext,
        blockComponentBuilder: widget.blockComponentBuilder,
      ),
    );
  }

  Future<void> _onSelectAction(
    BuildContext context,
    OptionAction action,
  ) async {
    final node = widget.blockComponentContext.node;
    final transaction = widget.editorState.transaction;
    switch (action) {
      case OptionAction.delete:
        transaction.deleteNode(node);
        break;
      case OptionAction.duplicate:
        await _duplicateBlock(context, transaction, node);
        break;
      case OptionAction.turnInto:
        break;
      case OptionAction.moveUp:
        transaction.moveNode(node.path.previous, node);
        break;
      case OptionAction.moveDown:
        transaction.moveNode(node.path.next.next, node);
        break;
      case OptionAction.copyLinkToBlock:
        await _copyLinkToBlock(context, node);
        break;
      case OptionAction.align:
      case OptionAction.color:
      case OptionAction.divider:
      case OptionAction.depth:
        throw UnimplementedError();
    }

    await widget.editorState.apply(transaction);
  }

  Future<void> _duplicateBlock(
    BuildContext context,
    Transaction transaction,
    Node node,
  ) async {
    // 1. verify the node integrity
    final type = node.type;
    final builder = widget.editorState.renderer.blockComponentBuilder(type);

    if (builder == null) {
      Log.error('Block type $type is not supported');
      return;
    }

    final valid = builder.validate(node);
    if (!valid) {
      Log.error('Block type $type is not valid');
    }

    // 2. duplicate the node
    //  the _copyBlock will fix the table block
    Node newNode = _copyBlock(context, node);

    // 3. if the node is sub page, duplicate the view
    if (node.type == SubPageBlockKeys.type) {
      final viewId = await _handleDuplicateSubPage(context, node);
      if (viewId == null) {
        return;
      }

      newNode = newNode.copyWith(attributes: {SubPageBlockKeys.viewId: viewId});
    }

    // 4. insert the node to the next of the current node
    transaction.insertNode(node.path.next, newNode);
  }

  Node _copyBlock(BuildContext context, Node node) {
    Node copiedNode = node.copyWith();

    final type = node.type;
    final builder = widget.editorState.renderer.blockComponentBuilder(type);

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

  Future<void> _copyLinkToBlock(BuildContext context, Node node) async {
    final viewId = context.read<DocumentBloc>().documentId;

    final workspace = await FolderEventReadCurrentWorkspace().send();
    final workspaceId = workspace.fold(
      (l) => l.id,
      (r) => '',
    );

    if (workspaceId.isEmpty || viewId.isEmpty) {
      Log.error('Failed to get workspace id: $workspaceId or view id: $viewId');
      if (context.mounted) {
        showToastNotification(
          context,
          message: LocaleKeys.shareAction_copyLinkToBlockFailed.tr(),
          type: ToastificationType.error,
        );
      }
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

    if (context.mounted) {
      showToastNotification(
        context,
        message: LocaleKeys.shareAction_copyLinkToBlockSuccess.tr(),
      );
    }
  }

  /// Handles duplicating a SubPage.
  ///
  /// If the duplication fails for any reason, this method will return false, and inserting
  /// the duplicate node should be aborted.
  ///
  Future<String?> _handleDuplicateSubPage(
    BuildContext context,
    Node node,
  ) async {
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
        if (context.mounted) {
          showSnapBar(
            context,
            LocaleKeys.document_plugins_subPage_errors_failedDuplicatePage.tr(),
          );
        }
        return null;
      },
    );
  }
}
