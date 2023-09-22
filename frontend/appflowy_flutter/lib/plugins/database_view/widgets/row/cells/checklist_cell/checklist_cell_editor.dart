import 'dart:async';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/common/type_option_separator.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'checklist_cell_editor_bloc.dart';
import 'checklist_progress_bar.dart';

class GridChecklistCellEditor extends StatefulWidget {
  final ChecklistCellController cellController;
  const GridChecklistCellEditor({required this.cellController, super.key});

  @override
  State<GridChecklistCellEditor> createState() =>
      _GridChecklistCellEditorState();
}

class _GridChecklistCellEditorState extends State<GridChecklistCellEditor> {
  late ChecklistCellEditorBloc _bloc;

  /// Focus node for the new task text field
  late final FocusNode newTaskFocusNode;

  @override
  void initState() {
    super.initState();
    newTaskFocusNode = FocusNode(
      onKey: (node, event) {
        if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          node.unfocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
    _bloc = ChecklistCellEditorBloc(cellController: widget.cellController)
      ..add(const ChecklistCellEditorEvent.initial());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<ChecklistCellEditorBloc, ChecklistCellEditorState>(
        listener: (context, state) {
          if (state.allOptions.isEmpty) {
            newTaskFocusNode.requestFocus();
          }
        },
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: state.allOptions.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: ChecklistProgressBar(
                          percent: state.percent,
                        ),
                      ),
              ),
              ChecklistItemList(
                options: state.allOptions,
                onUpdateTask: () => newTaskFocusNode.requestFocus(),
              ),
              if (state.allOptions.isNotEmpty)
                const TypeOptionSeparator(spacing: 0.0),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: NewTaskItem(focusNode: newTaskFocusNode),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }
}

/// Displays the a list of all the exisiting tasks and an input field to create
/// a new task if `isAddingNewTask` is true
class ChecklistItemList extends StatefulWidget {
  final List<ChecklistSelectOption> options;
  final VoidCallback onUpdateTask;

  const ChecklistItemList({
    super.key,
    required this.options,
    required this.onUpdateTask,
  });

  @override
  State<ChecklistItemList> createState() => _ChecklistItemListState();
}

class _ChecklistItemListState extends State<ChecklistItemList> {
  @override
  Widget build(BuildContext context) {
    if (widget.options.isEmpty) {
      return const SizedBox.shrink();
    }

    final itemList = widget.options
        .mapIndexed(
          (index, option) => ChecklistItem(
            option: option,
            onSubmitted:
                index == widget.options.length - 1 ? widget.onUpdateTask : null,
            key: ValueKey(option.data.id),
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

/// Represents an existing task
@visibleForTesting
class ChecklistItem extends StatefulWidget {
  final ChecklistSelectOption option;
  final VoidCallback? onSubmitted;
  const ChecklistItem({
    required this.option,
    Key? key,
    this.onSubmitted,
  }) : super(key: key);

  @override
  State<ChecklistItem> createState() => _ChecklistItemState();
}

class _ChecklistItemState extends State<ChecklistItem> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  bool _isHovered = false;
  Timer? _debounceOnChanged;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.option.data.name);
    _focusNode = FocusNode(
      onKey: (node, event) {
        if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          node.unfocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final icon = FlowySvg(
      widget.option.isSelected ? FlowySvgs.check_filled_s : FlowySvgs.uncheck_s,
      blendMode: BlendMode.dst,
    );
    return MouseRegion(
      onEnter: (event) => setState(() => _isHovered = true),
      onExit: (event) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        constraints: BoxConstraints(minHeight: GridSize.popoverItemHeight),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _isHovered
                ? AFThemeExtension.of(context).lightGreyHover
                : Colors.transparent,
            borderRadius: Corners.s6Border,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FlowyIconButton(
                width: 32,
                icon: icon,
                hoverColor: Colors.transparent,
                onPressed: () => context.read<ChecklistCellEditorBloc>().add(
                      ChecklistCellEditorEvent.selectTask(widget.option.data),
                    ),
              ),
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 6.0,
                      horizontal: 2.0,
                    ),
                    hintText: LocaleKeys.grid_checklist_taskHint.tr(),
                  ),
                  onChanged: _debounceOnChangedText,
                  onSubmitted: (description) {
                    _submitUpdateTaskDescription(description);
                    widget.onSubmitted?.call();
                  },
                ),
              ),
              if (_isHovered)
                FlowyIconButton(
                  width: 32,
                  icon: const FlowySvg(FlowySvgs.delete_s),
                  hoverColor: Colors.transparent,
                  iconColorOnHover: Theme.of(context).colorScheme.error,
                  onPressed: () => context.read<ChecklistCellEditorBloc>().add(
                        ChecklistCellEditorEvent.deleteTask(widget.option.data),
                      ),
                ),
            ],
          ),
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
    context.read<ChecklistCellEditorBloc>().add(
          ChecklistCellEditorEvent.updateTaskName(
            widget.option.data,
            description,
          ),
        );
  }
}

/// Creates a new task after entering the description and pressing enter.
/// This can be cancelled by pressing escape
@visibleForTesting
class NewTaskItem extends StatefulWidget {
  final FocusNode focusNode;
  const NewTaskItem({super.key, required this.focusNode});

  @override
  State<NewTaskItem> createState() => _NewTaskItemState();
}

class _NewTaskItemState extends State<NewTaskItem> {
  late final TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    if (widget.focusNode.canRequestFocus) {
      widget.focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      constraints: BoxConstraints(minHeight: GridSize.popoverItemHeight),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const HSpace(8),
          Expanded(
            child: TextField(
              focusNode: widget.focusNode,
              controller: _textEditingController,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
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
                if (taskDescription.trim().isNotEmpty) {
                  context.read<ChecklistCellEditorBloc>().add(
                        ChecklistCellEditorEvent.newTask(
                          taskDescription.trim(),
                        ),
                      );
                }
                widget.focusNode.requestFocus();
                _textEditingController.clear();
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
            onPressed: () {
              if (_textEditingController.text.trim().isNotEmpty) {
                context.read<ChecklistCellEditorBloc>().add(
                      ChecklistCellEditorEvent.newTask(
                        _textEditingController.text..trim(),
                      ),
                    );
              }
              widget.focusNode.requestFocus();
              _textEditingController.clear();
            },
          ),
        ],
      ),
    );
  }
}
