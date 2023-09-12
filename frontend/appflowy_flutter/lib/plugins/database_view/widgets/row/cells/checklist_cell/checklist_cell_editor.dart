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

  /// A flag that determines whether the new task text field is visible
  bool _isAddingNewTask = false;

  @override
  void initState() {
    super.initState();
    newTaskFocusNode = FocusNode();
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
            setState(() => _isAddingNewTask = true);
          }
        },
        builder: (context, state) {
          return Focus(
            onKey: (node, event) {
              // don't hide new task text field if there are no tasks at all
              if (state.allOptions.isNotEmpty &&
                  event is RawKeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.escape) {
                setState(() {
                  _isAddingNewTask = false;
                });
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: CustomScrollView(
              shrinkWrap: true,
              physics: StyledScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: AnimatedSwitcher(
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
                ),
                ChecklistItemList(
                  options: state.allOptions,
                  newTaskFocusNode: newTaskFocusNode,
                  isAddingNewTask: _isAddingNewTask,
                  onUpdateTask: () => setState(() {
                    _isAddingNewTask = true;
                    newTaskFocusNode.requestFocus();
                  }),
                ),
                const SliverToBoxAdapter(
                  child: TypeOptionSeparator(spacing: 0.0),
                ),
                SliverToBoxAdapter(
                  child: ChecklistNewTaskButton(
                    onTap: () => setState(() => _isAddingNewTask = true),
                  ),
                ),
              ],
            ),
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
  final FocusNode newTaskFocusNode;
  final bool isAddingNewTask;
  final VoidCallback onUpdateTask;

  const ChecklistItemList({
    super.key,
    required this.options,
    required this.onUpdateTask,
    required this.isAddingNewTask,
    required this.newTaskFocusNode,
  });

  @override
  State<ChecklistItemList> createState() => _ChecklistItemListState();
}

class _ChecklistItemListState extends State<ChecklistItemList> {
  @override
  Widget build(BuildContext context) {
    final itemList = [
      const VSpace(6.0),
      ...widget.options.mapIndexed(
        (index, option) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: ChecklistItem(
            option: option,
            onSubmitted:
                index == widget.options.length - 1 ? widget.onUpdateTask : null,
            key: ValueKey(option.data.id),
            // only allow calling the callback for the last task in the list
          ),
        ),
      ),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: widget.isAddingNewTask
            ? NewTaskItem(focusNode: widget.newTaskFocusNode)
            : const SizedBox.shrink(),
      ),
      const VSpace(6.0),
    ];
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) => itemList[index],
        childCount: itemList.length,
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
                  onSubmitted: (taskDescription) {
                    context.read<ChecklistCellEditorBloc>().add(
                          ChecklistCellEditorEvent.updateTaskName(
                            widget.option.data,
                            taskDescription,
                          ),
                        );
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
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      constraints: BoxConstraints(minHeight: GridSize.popoverItemHeight),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const FlowyIconButton(
            width: 32,
            icon: FlowySvg(
              FlowySvgs.uncheck_s,
              blendMode: BlendMode.dst,
            ),
            hoverColor: Colors.transparent,
          ),
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
                hintText: LocaleKeys.grid_checklist_taskHint.tr(),
              ),
              onSubmitted: (taskDescription) {
                if (taskDescription.trim().isNotEmpty) {
                  context.read<ChecklistCellEditorBloc>().add(
                        ChecklistCellEditorEvent.newTask(
                          taskDescription.trim(),
                        ),
                      );
                }
                _textEditingController.clear();
              },
            ),
          ),
          FlowyTextButton(
            LocaleKeys.grid_checklist_submitNewTask.tr(),
            fontSize: 11,
            fillColor: Theme.of(context).colorScheme.primary,
            hoverColor: Theme.of(context).colorScheme.primaryContainer,
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
              _textEditingController.clear();
            },
          ),
        ],
      ),
    );
  }
}

@visibleForTesting
class ChecklistNewTaskButton extends StatelessWidget {
  final VoidCallback onTap;
  const ChecklistNewTaskButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: SizedBox(
        height: 30,
        child: FlowyButton(
          text: FlowyText.medium(LocaleKeys.grid_checklist_addNew.tr()),
          margin: const EdgeInsets.all(6),
          leftIcon: const FlowySvg(FlowySvgs.add_s),
          onTap: onTap,
        ),
      ),
    );
  }
}
