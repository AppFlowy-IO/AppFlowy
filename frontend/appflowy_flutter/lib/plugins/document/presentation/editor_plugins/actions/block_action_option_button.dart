import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_option_cubit.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/option_action.dart';
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
    return BlocProvider(
      create: (context) => BlockActionOptionCubit(
        editorState: widget.editorState,
        blockComponentBuilder: widget.blockComponentBuilder,
      ),
      child: PopoverActionList<PopoverAction>(
        popoverMutex: PopoverMutex(),
        actions: popoverActions,
        animationDuration: Durations.short3,
        slideDistance: 5,
        beginScaleFactor: 1.0,
        beginOpacity: 0.8,
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
            context.read<BlockActionOptionCubit>().handleAction(
                  action.inner,
                  widget.blockComponentContext.node,
                );
            controller.close();
          }
        },
        buildChild: (controller) => DraggableOptionButton(
          controller: controller,
          editorState: widget.editorState,
          blockComponentContext: widget.blockComponentContext,
          blockComponentBuilder: widget.blockComponentBuilder,
        ),
      ),
    );
  }
}
