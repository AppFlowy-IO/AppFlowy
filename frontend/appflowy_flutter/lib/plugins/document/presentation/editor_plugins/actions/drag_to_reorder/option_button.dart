import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_button.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_option_cubit.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _interceptorKey = 'document_option_button_interceptor';

class OptionButton extends StatefulWidget {
  const OptionButton({
    super.key,
    required this.controller,
    required this.editorState,
    required this.blockComponentContext,
    required this.isDragging,
  });

  final PopoverController controller;
  final EditorState editorState;
  final BlockComponentContext blockComponentContext;
  final ValueNotifier<bool> isDragging;

  @override
  State<OptionButton> createState() => _OptionButtonState();
}

class _OptionButtonState extends State<OptionButton> {
  late final registerKey =
      _interceptorKey + widget.blockComponentContext.node.id;
  late final gestureInterceptor = SelectionGestureInterceptor(
    key: registerKey,
    canTap: (details) => !_isTapInBounds(details.globalPosition),
  );

  // the selection will be cleared when tap the option button
  // so we need to restore the selection after tap the option button
  Selection? beforeSelection;
  RenderBox? get renderBox => context.findRenderObject() as RenderBox?;

  @override
  void initState() {
    super.initState();

    widget.editorState.service.selectionService.registerGestureInterceptor(
      gestureInterceptor,
    );
  }

  @override
  void dispose() {
    widget.editorState.service.selectionService.unregisterGestureInterceptor(
      registerKey,
    );

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.isDragging,
      builder: (context, isDragging, child) {
        return BlockActionButton(
          svg: FlowySvgs.drag_element_s,
          showTooltip: !isDragging,
          richMessage: TextSpan(
            children: [
              TextSpan(
                text: LocaleKeys.document_plugins_optionAction_drag.tr(),
                style: context.tooltipTextStyle(),
              ),
              TextSpan(
                text: LocaleKeys.document_plugins_optionAction_toMove.tr(),
                style: context.tooltipTextStyle(),
              ),
              const TextSpan(text: '\n'),
              TextSpan(
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
            final selection = widget.editorState.selection;
            if (selection != null) {
              beforeSelection = selection.normalized;
            }

            widget.controller.show();

            // update selection
            _updateBlockSelection(context);
          },
        );
      },
    );
  }

  void _updateBlockSelection(BuildContext context) {
    final cubit = context.read<BlockActionOptionCubit>();
    final selection = cubit.calculateTurnIntoSelection(
      widget.blockComponentContext.node,
      beforeSelection,
    );
    Log.info(
      'update block selection, beforeSelection: $beforeSelection, afterSelection: $selection',
    );
    widget.editorState.updateSelectionWithReason(
      selection,
      customSelectionType: SelectionType.block,
    );
  }

  bool _isTapInBounds(Offset offset) {
    final renderBox = this.renderBox;
    if (renderBox == null) {
      return false;
    }

    final localPosition = renderBox.globalToLocal(offset);
    final result = renderBox.paintBounds.contains(localPosition);
    if (result) {
      beforeSelection = widget.editorState.selection?.normalized;
    } else {
      beforeSelection = null;
    }

    return result;
  }
}
