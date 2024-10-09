import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_option_cubit.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/option_action.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'drag_to_reorder/draggable_option_button.dart';

class BlockOptionButton extends StatelessWidget {
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

  List<PopoverAction> get popoverActions => actions.map((e) {
        switch (e) {
          case OptionAction.divider:
            return DividerOptionAction();
          case OptionAction.color:
            return ColorOptionAction(editorState: editorState);
          case OptionAction.align:
            return AlignOptionAction(editorState: editorState);
          case OptionAction.depth:
            return DepthOptionAction(editorState: editorState);
          case OptionAction.turnInto:
            return TurnIntoOptionAction(editorState: editorState);
          default:
            return OptionActionWrapper(e);
        }
      }).toList();

  @override
  Widget build(BuildContext context) {
    final direction =
        context.read<AppearanceSettingsCubit>().state.layoutDirection ==
                LayoutDirection.rtlLayout
            ? PopoverDirection.rightWithCenterAligned
            : PopoverDirection.leftWithCenterAligned;
    return BlocProvider(
      create: (context) => BlockActionOptionCubit(
        editorState: editorState,
        blockComponentBuilder: blockComponentBuilder,
      ),
      child: BlocBuilder<BlockActionOptionCubit, BlockActionOptionState>(
        builder: (context, _) => PopoverActionList<PopoverAction>(
          actions: popoverActions,
          animationDuration: Durations.short3,
          slideDistance: 5,
          beginScaleFactor: 1.0,
          beginOpacity: 0.8,
          direction: direction,
          onPopupBuilder: _onPopoverBuilder,
          onClosed: () => _onPopoverClosed(context),
          onSelected: (action, controller) => _onActionSelected(
            context,
            action,
            controller,
          ),
          buildChild: (controller) => DraggableOptionButton(
            controller: controller,
            editorState: editorState,
            blockComponentContext: blockComponentContext,
            blockComponentBuilder: blockComponentBuilder,
          ),
        ),
      ),
    );
  }

  void _onPopoverBuilder() {
    keepEditorFocusNotifier.increase();
    blockComponentState.alwaysShowActions = true;
  }

  void _onPopoverClosed(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      editorState.selectionType = null;
      editorState.selection = null;
      blockComponentState.alwaysShowActions = false;
    });
  }

  void _onActionSelected(
    BuildContext context,
    PopoverAction action,
    PopoverController controller,
  ) {
    if (action is! OptionActionWrapper) {
      return;
    }

    context.read<BlockActionOptionCubit>().handleAction(
          action.inner,
          blockComponentContext.node,
        );
    controller.close();
  }
}
