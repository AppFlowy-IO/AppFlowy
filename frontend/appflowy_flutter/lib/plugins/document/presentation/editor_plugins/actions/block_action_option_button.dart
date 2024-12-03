import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_option_cubit.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/option/option_actions.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  // the mutex is used to ensure that only one popover is open at a time
  // for example, when the user is selecting the color, the turn into option
  // should not be shown.
  final mutex = PopoverMutex();

  @override
  Widget build(BuildContext context) {
    final direction =
        context.read<AppearanceSettingsCubit>().state.layoutDirection ==
                LayoutDirection.rtlLayout
            ? PopoverDirection.rightWithCenterAligned
            : PopoverDirection.leftWithCenterAligned;
    return BlocProvider(
      create: (context) => BlockActionOptionCubit(
        editorState: widget.editorState,
        blockComponentBuilder: widget.blockComponentBuilder,
      ),
      child: BlocBuilder<BlockActionOptionCubit, BlockActionOptionState>(
        builder: (context, _) => PopoverActionList<PopoverAction>(
          actions: _buildPopoverActions(context),
          popoverMutex: PopoverMutex(),
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
            editorState: widget.editorState,
            blockComponentContext: widget.blockComponentContext,
            blockComponentBuilder: widget.blockComponentBuilder,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    mutex.dispose();

    super.dispose();
  }

  List<PopoverAction> _buildPopoverActions(BuildContext context) {
    return widget.actions.map((e) {
      switch (e) {
        case OptionAction.divider:
          return DividerOptionAction();
        case OptionAction.color:
          return ColorOptionAction(
            editorState: widget.editorState,
            mutex: mutex,
          );
        case OptionAction.align:
          return AlignOptionAction(editorState: widget.editorState);
        case OptionAction.depth:
          return DepthOptionAction(editorState: widget.editorState);
        case OptionAction.turnInto:
          return TurnIntoOptionAction(
            editorState: widget.editorState,
            blockComponentBuilder: widget.blockComponentBuilder,
            mutex: mutex,
          );
        default:
          return OptionActionWrapper(e);
      }
    }).toList();
  }

  void _onPopoverBuilder() {
    keepEditorFocusNotifier.increase();
    widget.blockComponentState.alwaysShowActions = true;
  }

  void _onPopoverClosed(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.editorState.selectionType = null;
      widget.editorState.selection = null;
      widget.blockComponentState.alwaysShowActions = false;
    });

    PopoverContainer.maybeOf(context)?.closeAll();
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
          widget.blockComponentContext.node,
        );
    controller.close();
  }
}
