import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_button.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

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
  late final gestureInterceptor = SelectionGestureInterceptor(
    key: _interceptorKey,
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
      _interceptorKey,
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
            _updateBlockSelection();
          },
        );
      },
    );
  }

  void _updateBlockSelection() {
    final beforeSelection = this.beforeSelection;
    final path = widget.blockComponentContext.node.path;
    final selection = Selection.collapsed(
      Position(path: path),
    );
    Log.info(
      'update block selection, beforeSelection: $beforeSelection, path: $path',
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
      widget.editorState.updateSelectionWithReason(
        selection,
        customSelectionType: SelectionType.block,
      );
      return;
    }
    // if the beforeSelection start with the current block,
    //  then updating the selection with the beforeSelection that may contains multiple blocks
    widget.editorState.updateSelectionWithReason(
      beforeSelection,
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
