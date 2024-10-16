import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_notification.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_button.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/drag_to_reorder/util.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/drag_to_reorder/visual_drag_area.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/string_extension.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/custom_image_block_component/custom_image_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/multi_image_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// this flag is used to disable the tooltip of the block when it is dragged
@visibleForTesting
ValueNotifier<bool> isDraggingAppFlowyEditorBlock = ValueNotifier(false);

class DraggableOptionButton extends StatefulWidget {
  const DraggableOptionButton({
    super.key,
    required this.controller,
    required this.editorState,
    required this.blockComponentContext,
    required this.blockComponentBuilder,
  });

  final PopoverController controller;
  final EditorState editorState;
  final BlockComponentContext blockComponentContext;
  final Map<String, BlockComponentBuilder> blockComponentBuilder;
  @override
  State<DraggableOptionButton> createState() => _DraggableOptionButtonState();
}

class _DraggableOptionButtonState extends State<DraggableOptionButton> {
  late Node node;
  late BlockComponentContext blockComponentContext;

  Offset? globalPosition;

  @override
  void initState() {
    super.initState();

    // copy the node to avoid the node in document being updated
    node = widget.blockComponentContext.node.copyWith();
  }

  @override
  void dispose() {
    node.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Draggable<Node>(
      data: node,
      onDragStarted: _onDragStart,
      onDragUpdate: _onDragUpdate,
      onDragEnd: _onDragEnd,
      feedback: _OptionButtonFeedback(
        controller: widget.controller,
        editorState: widget.editorState,
        blockComponentContext: widget.blockComponentContext,
        blockComponentBuilder: widget.blockComponentBuilder,
      ),
      child: _OptionButton(
        isDragging: isDraggingAppFlowyEditorBlock,
        controller: widget.controller,
        editorState: widget.editorState,
        blockComponentContext: widget.blockComponentContext,
      ),
    );
  }

  void _onDragStart() {
    EditorNotification.dragStart().post();
    isDraggingAppFlowyEditorBlock.value = true;
    widget.editorState.selectionService.removeDropTarget();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    isDraggingAppFlowyEditorBlock.value = true;

    widget.editorState.selectionService.renderDropTargetForOffset(
      details.globalPosition,
      builder: (context, data) {
        return VisualDragArea(
          data: data,
          dragNode: widget.blockComponentContext.node,
        );
      },
    );

    globalPosition = details.globalPosition;

    // auto scroll the page when the drag position is at the edge of the screen
    widget.editorState.scrollService?.startAutoScroll(
      details.localPosition,
    );
  }

  void _onDragEnd(DraggableDetails details) {
    isDraggingAppFlowyEditorBlock.value = false;

    widget.editorState.selectionService.removeDropTarget();

    if (globalPosition == null) {
      return;
    }

    final data = widget.editorState.selectionService.getDropTargetRenderData(
      globalPosition!,
    );
    dragToMoveNode(
      context,
      node: widget.blockComponentContext.node,
      acceptedPath: data?.cursorNode?.path,
      dragOffset: globalPosition!,
    ).then((_) {
      EditorNotification.dragEnd().post();
    });
  }
}

class _OptionButtonFeedback extends StatefulWidget {
  const _OptionButtonFeedback({
    required this.controller,
    required this.editorState,
    required this.blockComponentContext,
    required this.blockComponentBuilder,
  });

  final PopoverController controller;
  final EditorState editorState;
  final BlockComponentContext blockComponentContext;
  final Map<String, BlockComponentBuilder> blockComponentBuilder;

  @override
  State<_OptionButtonFeedback> createState() => _OptionButtonFeedbackState();
}

class _OptionButtonFeedbackState extends State<_OptionButtonFeedback> {
  late Node node;
  late BlockComponentContext blockComponentContext;

  @override
  void initState() {
    super.initState();

    _setupLockComponentContext();
    widget.blockComponentContext.node.addListener(_updateBlockComponentContext);
  }

  @override
  void dispose() {
    widget.blockComponentContext.node
        .removeListener(_updateBlockComponentContext);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = (widget.editorState.renderBox?.size.width ??
            MediaQuery.of(context).size.width) *
        0.8;

    return Opacity(
      opacity: 0.7,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
          ),
          child: IntrinsicHeight(
            child: Provider.value(
              value: widget.editorState,
              child: _buildBlock(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlock() {
    final node = widget.blockComponentContext.node;
    final builder = widget.blockComponentBuilder[node.type];
    if (builder == null) {
      return const SizedBox.shrink();
    }

    const unsupportedRenderBlockTypes = [
      TableBlockKeys.type,
      CustomImageBlockKeys.type,
      MultiImageBlockKeys.type,
      FileBlockKeys.type,
      DatabaseBlockKeys.boardType,
      DatabaseBlockKeys.calendarType,
      DatabaseBlockKeys.gridType,
    ];

    if (unsupportedRenderBlockTypes.contains(node.type)) {
      // unable to render table block without provider/context
      // render a placeholder instead
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: FlowyText(node.type.replaceAll('_', ' ').capitalize()),
      );
    }

    return IntrinsicHeight(
      child: MultiProvider(
        providers: [
          Provider.value(value: widget.editorState),
          Provider.value(value: getIt<ReminderBloc>()),
        ],
        child: builder.build(blockComponentContext),
      ),
    );
  }

  void _updateBlockComponentContext() {
    setState(() => _setupLockComponentContext());
  }

  void _setupLockComponentContext() {
    node = widget.blockComponentContext.node.copyWith();
    blockComponentContext = BlockComponentContext(
      widget.blockComponentContext.buildContext,
      node,
    );
  }
}

class _OptionButton extends StatefulWidget {
  const _OptionButton({
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
  State<_OptionButton> createState() => _OptionButtonState();
}

const _interceptorKey = 'document_option_button_interceptor';

class _OptionButtonState extends State<_OptionButton> {
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
            debugPrint(
              '_updateBlockSelection onTap - selection ${widget.editorState.selection}',
            );
            if (widget.editorState.selection != null) {
              beforeSelection = widget.editorState.selection;
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
    if (beforeSelection == null) {
      final path = widget.blockComponentContext.node.path;
      final selection = Selection.collapsed(
        Position(path: path),
      );
      debugPrint('_updateBlockSelection: selection $selection');
      widget.editorState.updateSelectionWithReason(
        selection,
        customSelectionType: SelectionType.block,
      );
    } else {
      debugPrint('_updateBlockSelection: beforeSelection $beforeSelection');
      widget.editorState.updateSelectionWithReason(
        beforeSelection!,
        customSelectionType: SelectionType.block,
      );
    }
  }

  bool _isTapInBounds(Offset offset) {
    if (renderBox == null) {
      return false;
    }

    final localPosition = renderBox!.globalToLocal(offset);
    final result = renderBox!.paintBounds.contains(localPosition);
    if (result) {
      beforeSelection = widget.editorState.selection;
      debugPrint('_updateBlockSelection update_selection $beforeSelection');
    } else {
      debugPrint('_updateBlockSelection clear selection');
      beforeSelection = null;
    }
    return result;
  }
}
