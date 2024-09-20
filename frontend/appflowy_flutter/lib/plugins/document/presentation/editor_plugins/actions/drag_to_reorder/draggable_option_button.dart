import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_button.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/string_extension.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/custom_image_block_component/custom_image_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/multi_image_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

// this flag is used to disable the tooltip of the block when it is dragged

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

  ValueNotifier<bool> isDraggingAppFlowyEditorBlock = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    // copy the node to avoid the node in document being updated
    node = widget.blockComponentContext.node.copyWith();
  }

  @override
  void dispose() {
    node.dispose();
    isDraggingAppFlowyEditorBlock.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Draggable<Node>(
      data: node,
      feedback: _OptionButtonFeedback(
        controller: widget.controller,
        editorState: widget.editorState,
        blockComponentContext: widget.blockComponentContext,
        blockComponentBuilder: widget.blockComponentBuilder,
      ),
      onDragStarted: () {
        isDraggingAppFlowyEditorBlock.value = true;

        widget.editorState.selectionService.removeDropTarget();
      },
      onDragUpdate: (details) {
        isDraggingAppFlowyEditorBlock.value = true;

        widget.editorState.selectionService
            .renderDropTargetForOffset(details.globalPosition);

        globalPosition = details.globalPosition;

        // auto scroll the page when the drag position is at the edge of the screen
        widget.editorState.scrollService?.startAutoScroll(
          details.localPosition,
        );
      },
      onDragEnd: (details) {
        isDraggingAppFlowyEditorBlock.value = false;

        widget.editorState.selectionService.removeDropTarget();

        if (globalPosition == null) {
          return;
        }

        final data = widget.editorState.selectionService
            .getDropTargetRenderData(globalPosition!);
        final acceptedPath = data?.dropPath;

        _moveNodeToNewPosition(node, acceptedPath);
      },
      child: _OptionButton(
        isDragging: isDraggingAppFlowyEditorBlock,
        controller: widget.controller,
        editorState: widget.editorState,
        blockComponentContext: widget.blockComponentContext,
      ),
    );
  }

  Future<void> _moveNodeToNewPosition(Node node, Path? acceptedPath) async {
    if (acceptedPath == null) {
      Log.info('acceptedPath is null');
      return;
    }

    Log.info('move node($node) to path($acceptedPath)');

    // check the move target is a valid path
    // - cannot move to its children
    if (widget.blockComponentContext.node.path.isParentOf(acceptedPath)) {
      Log.info('cannot move to its children');
      showToastNotification(
        context,
        message: LocaleKeys.document_plugins_cannotMoveToItsChildren.tr(),
        type: ToastificationType.error,
      );
      return;
    }

    if (widget.blockComponentContext.node.path.equals(acceptedPath)) {
      Log.info('cannot move to the same path');
      return;
    }

    final transaction = widget.editorState.transaction;
    // use the node in document instead of the local node
    transaction.moveNode(acceptedPath, widget.blockComponentContext.node);
    await widget.editorState.apply(transaction);
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

class _OptionButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isDragging,
      builder: (context, isDragging, child) {
        return BlockActionButton(
          svg: FlowySvgs.drag_element_s,
          richMessage: isDragging
              ? const TextSpan()
              : TextSpan(
                  children: [
                    TextSpan(
                      text: LocaleKeys.document_plugins_optionAction_drag.tr(),
                      style: context.tooltipTextStyle(),
                    ),
                    TextSpan(
                      text:
                          LocaleKeys.document_plugins_optionAction_toMove.tr(),
                      style: context.tooltipTextStyle(),
                    ),
                    const TextSpan(text: '\n'),
                    TextSpan(
                      text: LocaleKeys.document_plugins_optionAction_click.tr(),
                      style: context.tooltipTextStyle(),
                    ),
                    TextSpan(
                      text: LocaleKeys.document_plugins_optionAction_toOpenMenu
                          .tr(),
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
}
