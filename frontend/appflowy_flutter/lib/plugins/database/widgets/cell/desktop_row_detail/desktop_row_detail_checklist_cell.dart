import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/checklist_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/checklist_cell_editor.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/checklist_progress_bar.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../editable_cell_skeleton/checklist.dart';

class DesktopRowDetailChecklistCellSkin extends IEditableChecklistCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    ChecklistCellBloc bloc,
    ChecklistCellState state,
    PopoverController popoverController,
  ) {
    return ChecklistItems(
      context: context,
      cellContainerNotifier: cellContainerNotifier,
      bloc: bloc,
      state: state,
      popoverController: popoverController,
    );
  }
}

class ChecklistItems extends StatefulWidget {
  const ChecklistItems({
    super.key,
    required this.context,
    required this.cellContainerNotifier,
    required this.bloc,
    required this.state,
    required this.popoverController,
  });

  final BuildContext context;
  final CellContainerNotifier cellContainerNotifier;
  final ChecklistCellBloc bloc;
  final ChecklistCellState state;
  final PopoverController popoverController;

  @override
  State<ChecklistItems> createState() => _ChecklistItemsState();
}

class _ChecklistItemsState extends State<ChecklistItems> {
  bool showIncompleteOnly = false;

  @override
  Widget build(BuildContext context) {
    final tasks = [...widget.state.tasks];
    if (showIncompleteOnly) {
      tasks.removeWhere((task) => task.isSelected);
    }
    // final children = tasks
    //     .mapIndexed(
    //       (index, task) => Padding(
    //         padding: const EdgeInsets.symmetric(vertical: 2.0),
    //         child: ChecklistItem(
    //           key: ValueKey('${task.data.id}$index'),
    //           task: task,
    //           autofocus: widget.state.newTask && index == tasks.length - 1,
    //           onSubmitted: () {
    //             if (index == tasks.length - 1) {
    //               // create a new task under the last task if the users press enter
    //               widget.bloc.add(const ChecklistCellEvent.createNewTask(''));
    //             }
    //           },
    //         ),
    //       ),
    //     )
    //     .toList();
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ChecklistProgressBar(
                    tasks: widget.state.tasks,
                    percent: widget.state.percent,
                  ),
                ),
                const HSpace(6.0),
                FlowyIconButton(
                  tooltipText: showIncompleteOnly
                      ? LocaleKeys.grid_checklist_showComplete.tr()
                      : LocaleKeys.grid_checklist_hideComplete.tr(),
                  width: 32,
                  iconColorOnHover: Theme.of(context).colorScheme.onSurface,
                  icon: FlowySvg(
                    showIncompleteOnly ? FlowySvgs.show_m : FlowySvgs.hide_m,
                    size: const Size.square(16),
                  ),
                  onPressed: () {
                    setState(
                      () => showIncompleteOnly = !showIncompleteOnly,
                    );
                  },
                ),
              ],
            ),
          ),
          const VSpace(2.0),
          _ChecklistCellEditors(tasks: tasks),
          ChecklistItemControl(cellNotifer: widget.cellContainerNotifier),
        ],
      ),
    );
  }
}

class _ChecklistCellEditors extends StatelessWidget {
  const _ChecklistCellEditors({
    required this.tasks,
  });

  final List<ChecklistSelectOption> tasks;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ChecklistCellBloc>();
    final state = bloc.state;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...tasks.mapIndexed(
          (index, task) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: ChecklistItem(
              key: ValueKey('${task.data.id}$index'),
              task: task,
              autofocus: state.newTask && index == tasks.length - 1,
              onSubmitted: () {
                if (index == tasks.length - 1) {
                  // create a new task under the last task if the users press enter
                  bloc.add(const ChecklistCellEvent.createNewTask(''));
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class ChecklistItemControl extends StatelessWidget {
  const ChecklistItemControl({super.key, required this.cellNotifer});

  final CellContainerNotifier cellNotifer;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: cellNotifer,
      child: Consumer<CellContainerNotifier>(
        builder: (buildContext, notifier, _) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context
              .read<ChecklistCellBloc>()
              .add(const ChecklistCellEvent.createNewTask("")),
          child: Container(
            margin: const EdgeInsets.fromLTRB(8.0, 2.0, 8.0, 0),
            height: 12,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: notifier.isHover
                  ? FlowyTooltip(
                      message: LocaleKeys.grid_checklist_addNew.tr(),
                      child: Row(
                        children: [
                          const Flexible(child: Center(child: Divider())),
                          const HSpace(12.0),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.square(12),
                              maximumSize: const Size.square(12),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () => context
                                .read<ChecklistCellBloc>()
                                .add(
                                  const ChecklistCellEvent.createNewTask(""),
                                ),
                            child: FlowySvg(
                              FlowySvgs.add_s,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          const HSpace(12.0),
                          const Flexible(child: Center(child: Divider())),
                        ],
                      ),
                    )
                  : const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}
