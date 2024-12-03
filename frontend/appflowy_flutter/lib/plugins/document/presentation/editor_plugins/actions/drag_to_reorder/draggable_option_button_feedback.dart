import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_button.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/string_extension.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DraggleOptionButtonFeedback extends StatefulWidget {
  const DraggleOptionButtonFeedback({
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
  State<DraggleOptionButtonFeedback> createState() =>
      _DraggleOptionButtonFeedbackState();
}

class _DraggleOptionButtonFeedbackState
    extends State<DraggleOptionButtonFeedback> {
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
          onPointerDown: () {
            if (widget.editorState.selection != null) {
              beforeSelection = widget.editorState.selection;
            }
          },
          onTap: () {
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
      widget.editorState.updateSelectionWithReason(
        selection,
        customSelectionType: SelectionType.block,
      );
    } else {
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
    } else {
      beforeSelection = null;
    }

    return result;
  }
}
