import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/common/type_option_separator.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/cell/bloc/checklist_cell_bloc.dart';

import 'checklist_progress_bar.dart';

class ChecklistCellEditor extends StatefulWidget {
  const ChecklistCellEditor({required this.cellController, super.key});

  final ChecklistCellController cellController;

  @override
  State<ChecklistCellEditor> createState() => _ChecklistCellEditorState();
}

class _ChecklistCellEditorState extends State<ChecklistCellEditor> {
  /// Focus node for the new task text field
  late final FocusNode newTaskFocusNode;

  @override
  void initState() {
    super.initState();
    newTaskFocusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          node.unfocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChecklistCellBloc, ChecklistCellState>(
      listener: (context, state) {
        if (state.tasks.isEmpty) {
          newTaskFocusNode.requestFocus();
        }
      },
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.tasks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: ChecklistProgressBar(
                  tasks: state.tasks,
                  percent: state.percent,
                ),
              ),
            ChecklistItemList(
              options: state.tasks,
              onUpdateTask: () => newTaskFocusNode.requestFocus(),
            ),
            if (state.tasks.isNotEmpty) const TypeOptionSeparator(spacing: 0.0),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: NewTaskItem(focusNode: newTaskFocusNode),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    newTaskFocusNode.dispose();
    super.dispose();
  }
}

/// Displays the a list of all the exisiting tasks and an input field to create
/// a new task if `isAddingNewTask` is true
class ChecklistItemList extends StatelessWidget {
  const ChecklistItemList({
    super.key,
    required this.options,
    required this.onUpdateTask,
  });

  final List<ChecklistSelectOption> options;
  final VoidCallback onUpdateTask;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    final itemList = options
        .mapIndexed(
          (index, option) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ChecklistItem(
              task: option,
              onSubmitted: index == options.length - 1 ? onUpdateTask : null,
              key: ValueKey(option.data.id),
            ),
          ),
        )
        .toList();

    return Flexible(
      child: ListView.separated(
        itemBuilder: (context, index) => itemList[index],
        separatorBuilder: (context, index) => const VSpace(4),
        itemCount: itemList.length,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
      ),
    );
  }
}

class _SelectTaskIntent extends Intent {
  const _SelectTaskIntent();
}

class _EndEditingTaskIntent extends Intent {
  const _EndEditingTaskIntent();
}

/// Represents an existing task
@visibleForTesting
class ChecklistItem extends StatefulWidget {
  const ChecklistItem({
    super.key,
    required this.task,
    this.onSubmitted,
    this.autofocus = false,
  });

  final ChecklistSelectOption task;
  final VoidCallback? onSubmitted;
  final bool autofocus;

  @override
  State<ChecklistItem> createState() => _ChecklistItemState();
}

class _ChecklistItemState extends State<ChecklistItem> {
  late final TextEditingController _textController;
  final FocusNode _focusNode = FocusNode(skipTraversal: true);
  final FocusNode _textFieldFocusNode = FocusNode();

  bool _isHovered = false;
  bool _isFocused = false;
  Timer? _debounceOnChanged;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.task.data.name);
  }

  @override
  void dispose() {
    _debounceOnChanged?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChecklistItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.data.name != oldWidget.task.data.name) {
      final selection = _textController.selection;
      // Ensure the selection offset is within the new text bounds
      int offset = selection.start;
      if (offset > widget.task.data.name.length) {
        offset = widget.task.data.name.length;
      }
      _textController.selection = TextSelection.collapsed(offset: offset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      focusNode: _focusNode,
      onShowHoverHighlight: (isHovered) {
        setState(() => _isHovered = isHovered);
      },
      onFocusChange: (isFocused) {
        setState(() => _isFocused = isFocused);
      },
      actions: {
        _SelectTaskIntent: CallbackAction<_SelectTaskIntent>(
          onInvoke: (_SelectTaskIntent intent) => context
              .read<ChecklistCellBloc>()
              .add(ChecklistCellEvent.selectTask(widget.task.data.id)),
        ),
        _EndEditingTaskIntent: CallbackAction<_EndEditingTaskIntent>(
          onInvoke: (_EndEditingTaskIntent intent) =>
              _textFieldFocusNode.unfocus(),
        ),
      },
      shortcuts: {
        SingleActivator(
          LogicalKeyboardKey.enter,
          meta: Platform.isMacOS,
          control: !Platform.isMacOS,
        ): const _SelectTaskIntent(),
      },
      child: Container(
        constraints: BoxConstraints(minHeight: GridSize.popoverItemHeight),
        decoration: BoxDecoration(
          color: _isHovered || _isFocused || _textFieldFocusNode.hasFocus
              ? AFThemeExtension.of(context).lightGreyHover
              : Colors.transparent,
          borderRadius: Corners.s6Border,
        ),
        child: Row(
          children: [
            ExcludeFocus(
              child: FlowyIconButton(
                width: 32,
                icon: FlowySvg(
                  widget.task.isSelected
                      ? FlowySvgs.check_filled_s
                      : FlowySvgs.uncheck_s,
                  blendMode: BlendMode.dst,
                ),
                hoverColor: Colors.transparent,
                onPressed: () => context.read<ChecklistCellBloc>().add(
                      ChecklistCellEvent.selectTask(widget.task.data.id),
                    ),
              ),
            ),
            Expanded(
              child: Shortcuts(
                shortcuts: const {
                  SingleActivator(LogicalKeyboardKey.escape):
                      _EndEditingTaskIntent(),
                },
                child: Builder(
                  builder: (context) {
                    return TextField(
                      controller: _textController,
                      focusNode: _textFieldFocusNode,
                      autofocus: widget.autofocus,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.only(
                          top: 8.0,
                          bottom: 8.0,
                          left: 2.0,
                          right: _isHovered ? 2.0 : 8.0,
                        ),
                        hintText: LocaleKeys.grid_checklist_taskHint.tr(),
                      ),
                      textInputAction: widget.onSubmitted == null
                          ? TextInputAction.done
                          : null,
                      onChanged: (text) {
                        if (_textController.value.composing.isCollapsed) {
                          _debounceOnChangedText(text);
                        }
                      },
                      onSubmitted: (description) {
                        _submitUpdateTaskDescription(description);
                        if (widget.onSubmitted != null) {
                          widget.onSubmitted?.call();
                        } else {
                          Actions.invoke(context, const NextFocusIntent());
                        }
                      },
                    );
                  },
                ),
              ),
            ),
            if (_isHovered || _isFocused || _textFieldFocusNode.hasFocus)
              _DeleteTaskButton(
                onPressed: () => context.read<ChecklistCellBloc>().add(
                      ChecklistCellEvent.deleteTask(widget.task.data.id),
                    ),
              ),
          ],
        ),
      ),
    );
  }

  void _debounceOnChangedText(String text) {
    _debounceOnChanged?.cancel();
    _debounceOnChanged = Timer(const Duration(milliseconds: 300), () {
      _submitUpdateTaskDescription(text);
    });
  }

  void _submitUpdateTaskDescription(String description) {
    context.read<ChecklistCellBloc>().add(
          ChecklistCellEvent.updateTaskName(
            widget.task.data,
            description,
          ),
        );
  }
}

/// Creates a new task after entering the description and pressing enter.
/// This can be cancelled by pressing escape
@visibleForTesting
class NewTaskItem extends StatefulWidget {
  const NewTaskItem({super.key, required this.focusNode});

  final FocusNode focusNode;

  @override
  State<NewTaskItem> createState() => _NewTaskItemState();
}

class _NewTaskItemState extends State<NewTaskItem> {
  final _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.focusNode.canRequestFocus) {
      widget.focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      constraints: BoxConstraints(minHeight: GridSize.popoverItemHeight),
      child: Row(
        children: [
          const HSpace(8),
          Expanded(
            child: TextField(
              focusNode: widget.focusNode,
              controller: _textEditingController,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 6.0,
                  horizontal: 2.0,
                ),
                hintText: LocaleKeys.grid_checklist_addNew.tr(),
              ),
              onSubmitted: (taskDescription) {
                if (taskDescription.isNotEmpty) {
                  context
                      .read<ChecklistCellBloc>()
                      .add(ChecklistCellEvent.createNewTask(taskDescription));
                  _textEditingController.clear();
                }
                widget.focusNode.requestFocus();
              },
              onChanged: (value) => setState(() {}),
            ),
          ),
          FlowyTextButton(
            LocaleKeys.grid_checklist_submitNewTask.tr(),
            fontSize: 11,
            fillColor: _textEditingController.text.isEmpty
                ? Theme.of(context).disabledColor
                : Theme.of(context).colorScheme.primary,
            hoverColor: _textEditingController.text.isEmpty
                ? Theme.of(context).disabledColor
                : Theme.of(context).colorScheme.primaryContainer,
            fontColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            onPressed: _textEditingController.text.isEmpty
                ? null
                : () {
                    context.read<ChecklistCellBloc>().add(
                          ChecklistCellEvent.createNewTask(
                            _textEditingController.text,
                          ),
                        );
                    widget.focusNode.requestFocus();
                    _textEditingController.clear();
                  },
          ),
        ],
      ),
    );
  }
}

class _DeleteTaskButton extends StatefulWidget {
  const _DeleteTaskButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  State<_DeleteTaskButton> createState() => _DeleteTaskButtonState();
}

class _DeleteTaskButtonState extends State<_DeleteTaskButton> {
  final _materialStatesController = WidgetStatesController();

  @override
  void dispose() {
    _materialStatesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: widget.onPressed,
      onHover: (_) => setState(() {}),
      onFocusChange: (_) => setState(() {}),
      style: ButtonStyle(
        fixedSize: const WidgetStatePropertyAll(Size.square(32)),
        minimumSize: const WidgetStatePropertyAll(Size.square(32)),
        maximumSize: const WidgetStatePropertyAll(Size.square(32)),
        overlayColor: WidgetStateProperty.resolveWith((state) {
          if (state.contains(WidgetState.focused)) {
            return AFThemeExtension.of(context).greyHover;
          }
          return Colors.transparent;
        }),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: Corners.s6Border),
        ),
      ),
      statesController: _materialStatesController,
      child: FlowySvg(
        FlowySvgs.delete_s,
        color: _materialStatesController.value.contains(WidgetState.hovered) ||
                _materialStatesController.value.contains(WidgetState.focused)
            ? Theme.of(context).colorScheme.error
            : null,
      ),
    );
  }
}
