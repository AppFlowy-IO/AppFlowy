import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/checklist_cell/checklist_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/checklist_cell/checklist_cell_bloc.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/checklist_cell/checklist_progress_bar.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/checklist_cell/mobile_checklist_cell_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileChecklistCell extends GridCellWidget {
  final CellControllerBuilder cellControllerBuilder;
  late final ChecklistCellStyle cellStyle;
  MobileChecklistCell({
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
  GridCellState<MobileChecklistCell> createState() =>
      _MobileChecklistCellState();
}

class _MobileChecklistCellState extends GridCellState<MobileChecklistCell> {
  late ChecklistCellBloc _cellBloc;

  @override
  void initState() {
    super.initState();
    final cellController =
        widget.cellControllerBuilder.build() as ChecklistCellController;
    _cellBloc = ChecklistCellBloc(cellController: cellController)
      ..add(const ChecklistCellEvent.initial());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<ChecklistCellBloc, ChecklistCellState>(
        builder: (context, state) {
          if (widget.cellStyle.useRoundedBorders) {
            return InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              onTap: () => showMobileBottomSheet(
                context,
                padding: EdgeInsets.zero,
                backgroundColor: Theme.of(context).colorScheme.background,
                builder: (context) {
                  return MobileChecklistCellEditScreen(
                    cellController: widget.cellControllerBuilder.build()
                        as ChecklistCellController,
                  );
                },
              ),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 48,
                  minWidth: double.infinity,
                ),
                decoration: BoxDecoration(
                  border: Border.fromBorderSide(
                    BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
                ),
                child: Padding(
                  padding: widget.cellStyle.cellPadding ?? EdgeInsets.zero,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Row(
                      children: [
                        Expanded(
                          child: state.tasks.isEmpty
                              ? FlowyText(
                                  widget.cellStyle.placeholder,
                                  fontSize: 15,
                                  color: Theme.of(context).hintColor,
                                )
                              : ChecklistProgressBar(
                                  tasks: state.tasks,
                                  percent: state.percent,
                                  fontSize: 15,
                                ),
                        ),
                        const HSpace(6),
                        RotatedBox(
                          quarterTurns: 3,
                          child: Icon(
                            Icons.chevron_left,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                        const HSpace(2),
                      ],
                    ),
                  ),
                ),
              ),
            );
          } else {
            return FlowyButton(
              radius: BorderRadius.zero,
              hoverColor: Colors.transparent,
              text: Container(
                alignment: Alignment.centerLeft,
                padding:
                    widget.cellStyle.cellPadding ?? GridSize.cellContentInsets,
                child: state.tasks.isEmpty
                    ? FlowyText(
                        widget.cellStyle.placeholder,
                        fontSize: 15,
                        color: Theme.of(context).hintColor,
                      )
                    : ChecklistProgressBar(
                        tasks: state.tasks,
                        percent: state.percent,
                        fontSize: 15,
                      ),
              ),
              onTap: () => showMobileBottomSheet(
                context,
                padding: EdgeInsets.zero,
                backgroundColor: Theme.of(context).colorScheme.background,
                builder: (context) {
                  return MobileChecklistCellEditScreen(
                    cellController: widget.cellControllerBuilder.build()
                        as ChecklistCellController,
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }

  @override
  void requestBeginFocus() {}
}
