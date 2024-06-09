import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_button.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/option_action.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
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
          _onSelectAction(action.inner);
          controller.close();
        }
      },
      buildChild: (controller) => _buildOptionButton(controller),
    );
  }

  Widget _buildOptionButton(PopoverController controller) {
    return BlockActionButton(
      svg: FlowySvgs.drag_element_s,
      richMessage: TextSpan(
        children: [
          TextSpan(
            // todo: customize the color to highlight the text.
            text: LocaleKeys.document_plugins_optionAction_click.tr(),
          ),
          TextSpan(
            text: LocaleKeys.document_plugins_optionAction_toOpenMenu.tr(),
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

  void _onSelectAction(OptionAction action) {
    final node = blockComponentContext.node;
    final transaction = editorState.transaction;
    switch (action) {
      case OptionAction.delete:
        transaction.deleteNode(node);
        break;
      case OptionAction.duplicate:
        transaction.insertNode(
          node.path.next,
          node.copyWith(),
        );
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
}
