import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_button.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/option_action.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlockOptionButton extends StatelessWidget {
  const BlockOptionButton({
    super.key,
    required this.blockComponentContext,
    required this.blockComponentState,
    required this.actions,
    required this.editorState,
  });

  final BlockComponentContext blockComponentContext;
  final BlockComponentActionState blockComponentState;
  final List<OptionAction> actions;
  final EditorState editorState;

  @override
  Widget build(BuildContext context) {
    final popoverActions = actions.map((e) {
      switch (e) {
        case OptionAction.divider:
          return DividerOptionAction();
        case OptionAction.color:
          return ColorOptionAction(editorState: editorState);
        case OptionAction.align:
          return AlignOptionAction(editorState: editorState);
        case OptionAction.depth:
          return DepthOptionAction(editorState: editorState);
        default:
          return OptionActionWrapper(e);
      }
    }).toList();

    return PopoverActionList<PopoverAction>(
      popoverMutex: PopoverMutex(),
      direction:
          context.read<AppearanceSettingsCubit>().state.layoutDirection ==
                  LayoutDirection.rtlLayout
              ? PopoverDirection.rightWithCenterAligned
              : PopoverDirection.leftWithCenterAligned,
      actions: popoverActions,
      onPopupBuilder: () {
        keepEditorFocusNotifier.increase();
        blockComponentState.alwaysShowActions = true;
      },
      onClosed: () {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          editorState.selectionType = null;
          editorState.selection = null;
          blockComponentState.alwaysShowActions = false;
          keepEditorFocusNotifier.decrease();
        });
      },
      onSelected: (action, controller) {
        if (action is OptionActionWrapper) {
          _onSelectAction(context, action.inner);
          controller.close();
        }
      },
      buildChild: (controller) => _buildOptionButton(context, controller),
    );
  }

  Widget _buildOptionButton(
    BuildContext context,
    PopoverController controller,
  ) {
    return BlockActionButton(
      svg: FlowySvgs.drag_element_s,
      richMessage: TextSpan(
        children: [
          TextSpan(
            // todo: customize the color to highlight the text.
            text: LocaleKeys.document_plugins_optionAction_click.tr(),
            style: context.tooltipTextStyle(),
          ),
          TextSpan(
            text: LocaleKeys.document_plugins_optionAction_toOpenMenu.tr(),
            style: context.tooltipTextStyle(),
          ),
        ],
      ),
      onTap: () {
        controller.show();

        // update selection
        _updateBlockSelection();
      },
    );
  }

  void _updateBlockSelection() {
    final startNode = blockComponentContext.node;
    var endNode = startNode;
    while (endNode.children.isNotEmpty) {
      endNode = endNode.children.last;
    }

    final start = Position(path: startNode.path);
    final end = endNode.selectable?.end() ??
        Position(
          path: endNode.path,
          offset: endNode.delta?.length ?? 0,
        );

    editorState.selectionType = SelectionType.block;
    editorState.selection = Selection(
      start: start,
      end: end,
    );
  }

  void _onSelectAction(BuildContext context, OptionAction action) {
    final node = blockComponentContext.node;
    final transaction = editorState.transaction;
    switch (action) {
      case OptionAction.delete:
        transaction.deleteNode(node);
        break;
      case OptionAction.duplicate:
        _duplicateBlock(context, transaction, node);
        break;
      case OptionAction.turnInto:
        break;
      case OptionAction.moveUp:
        transaction.moveNode(node.path.previous, node);
        break;
      case OptionAction.moveDown:
        transaction.moveNode(node.path.next.next, node);
        break;
      case OptionAction.align:
      case OptionAction.color:
      case OptionAction.divider:
      case OptionAction.depth:
        throw UnimplementedError();
    }
    editorState.apply(transaction);
  }

  void _duplicateBlock(
    BuildContext context,
    Transaction transaction,
    Node node,
  ) {
    // 1. verify the node integrity
    final type = node.type;
    final builder =
        context.read<EditorState>().renderer.blockComponentBuilder(type);

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
    final newNode = _copyBlock(context, node);

    // 3. insert the node to the next of the current node
    transaction.insertNode(
      node.path.next,
      newNode,
    );
  }

  Node _copyBlock(BuildContext context, Node node) {
    Node copiedNode = node.copyWith();

    final type = node.type;
    final builder =
        context.read<EditorState>().renderer.blockComponentBuilder(type);

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
}
