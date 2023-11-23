import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cell_builder.dart';
import 'checklist_cell_bloc.dart';
import 'checklist_cell_editor.dart';
import 'checklist_progress_bar.dart';

class ChecklistCellStyle extends GridCellStyle {
  final String placeholder;
  final EdgeInsets? cellPadding;
  final bool showTasksInline;

  const ChecklistCellStyle({
    this.placeholder = "",
    this.cellPadding,
    this.showTasksInline = false,
  });
}

class GridChecklistCell extends GridCellWidget {
  final CellControllerBuilder cellControllerBuilder;
  late final ChecklistCellStyle cellStyle;
  GridChecklistCell({
    required this.cellControllerBuilder,
    GridCellStyle? style,
    super.key,
  }) {
    if (style != null) {
      cellStyle = (style as ChecklistCellStyle);
    } else {
      cellStyle = const ChecklistCellStyle();
    }
  }

  @override
  GridCellState<GridChecklistCell> createState() => GridChecklistCellState();
}

class GridChecklistCellState extends GridCellState<GridChecklistCell> {
  late ChecklistCellBloc _cellBloc;
  late final PopoverController _popover;
  bool showIncompleteOnly = false;

  @override
  void initState() {
    _popover = PopoverController();
    final cellController =
        widget.cellControllerBuilder.build() as ChecklistCellController;
    _cellBloc = ChecklistCellBloc(cellController: cellController)
      ..add(const ChecklistCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<ChecklistCellBloc, ChecklistCellState>(
        builder: (context, state) {
          if (widget.cellStyle.showTasksInline) {
            final tasks = List.from(state.tasks);
            if (showIncompleteOnly) {
              tasks.removeWhere((task) => task.isSelected);
            }
            final children = tasks
                .mapIndexed(
                  (index, task) => ChecklistItem(
                    task: task,
                    autofocus: state.newTask && index == tasks.length - 1,
                    onSubmitted: () {
                      if (index == tasks.length - 1) {
                        context
                            .read<ChecklistCellBloc>()
                            .add(const ChecklistCellEvent.createNewTask(""));
                      }
                    },
                  ),
                )
                .toList();
            return Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding:
                    widget.cellStyle.cellPadding ?? GridSize.cellContentInsets,
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
                              tasks: state.tasks,
                              percent: state.percent,
                            ),
                          ),
                          const HSpace(6.0),
                          FlowyIconButton(
                            tooltipText: showIncompleteOnly
                                ? LocaleKeys.grid_checklist_showComplete.tr()
                                : LocaleKeys.grid_checklist_hideComplete.tr(),
                            width: 32,
                            iconColorOnHover:
                                Theme.of(context).colorScheme.onSurface,
                            icon: FlowySvg(
                              showIncompleteOnly
                                  ? FlowySvgs.show_m
                                  : FlowySvgs.hide_m,
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
                    const VSpace(4),
                    ...children,
                    const ChecklistItemControl(),
                  ],
                ),
              ),
            );
          }

          return AppFlowyPopover(
            margin: EdgeInsets.zero,
            controller: _popover,
            constraints: BoxConstraints.loose(const Size(360, 400)),
            direction: PopoverDirection.bottomWithLeftAligned,
            triggerActions: PopoverTriggerFlags.none,
            popupBuilder: (BuildContext popoverContext) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.cellContainerNotifier.isFocus = true;
              });
              return GridChecklistCellEditor(
                cellController: widget.cellControllerBuilder.build()
                    as ChecklistCellController,
              );
            },
            onClose: () => widget.cellContainerNotifier.isFocus = false,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding:
                    widget.cellStyle.cellPadding ?? GridSize.cellContentInsets,
                child: state.tasks.isEmpty
                    ? FlowyText.medium(
                        widget.cellStyle.placeholder,
                        color: Theme.of(context).hintColor,
                      )
                    : ChecklistProgressBar(
                        tasks: state.tasks,
                        percent: state.percent,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void requestBeginFocus() {
    if (!widget.cellStyle.showTasksInline) {
      _popover.show();
    }
  }
}

class ChecklistItemControl extends StatefulWidget {
  const ChecklistItemControl({super.key});

  @override
  State<ChecklistItemControl> createState() => _ChecklistItemControlState();
}

class _ChecklistItemControlState extends State<ChecklistItemControl> {
  bool _isHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (_) => setState(() => _isHover = true),
      onExit: (_) => setState(() => _isHover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context
            .read<ChecklistCellBloc>()
            .add(const ChecklistCellEvent.createNewTask("")),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 0),
          child: SizedBox(
            height: 12,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: _isHover
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
