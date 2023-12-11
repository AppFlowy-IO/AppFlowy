import 'package:appflowy/mobile/presentation/database/card/card_content/card_cells/card_cells.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/card_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/checklist_cell/checklist_cell_bloc.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class MobileChecklistCardCell extends CardCell {
  const MobileChecklistCardCell({
    super.key,
    required this.cellControllerBuilder,
  });

  final CellControllerBuilder cellControllerBuilder;

  @override
  State<MobileChecklistCardCell> createState() => _ChecklistCellState();
}

class _ChecklistCellState extends State<MobileChecklistCardCell> {
  late final ChecklistCellBloc _cellBloc;

  @override
  void initState() {
    super.initState();
    final cellController =
        widget.cellControllerBuilder.build() as ChecklistCellController;
    _cellBloc = ChecklistCellBloc(cellController: cellController)
      ..add(const ChecklistCellEvent.initial());
  }

  @override
  void dispose() {
    _cellBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cellStyle = MobileCardCellStyle(context);
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<ChecklistCellBloc, ChecklistCellState>(
        builder: (context, state) {
          if (state.tasks.isEmpty) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: cellStyle.padding,
            child: MobileChecklistProgressBar(
              tasks: state.tasks,
              percent: state.percent,
            ),
          );
        },
      ),
    );
  }
}

class MobileChecklistProgressBar extends StatefulWidget {
  const MobileChecklistProgressBar({
    super.key,
    required this.tasks,
    required this.percent,
  });

  final List<ChecklistSelectOption> tasks;
  final double percent;
  final int segmentLimit = 5;

  @override
  State<MobileChecklistProgressBar> createState() =>
      _MobileChecklistProgresssBarState();
}

class _MobileChecklistProgresssBarState
    extends State<MobileChecklistProgressBar> {
  @override
  Widget build(BuildContext context) {
    final cellStyle = MobileCardCellStyle(context);
    final numFinishedTasks = widget.tasks.where((e) => e.isSelected).length;
    final completedTaskColor = numFinishedTasks == widget.tasks.length
        ? AFThemeExtension.of(context).success
        : Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              if (widget.tasks.isNotEmpty &&
                  widget.tasks.length <= widget.segmentLimit)
                ...List<Widget>.generate(
                  widget.tasks.length,
                  (index) => Flexible(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(2)),
                        color: index < numFinishedTasks
                            ? completedTaskColor
                            : AFThemeExtension.of(context).progressBarBGColor,
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      height: 6.0,
                    ),
                  ),
                )
              else
                Expanded(
                  child: LinearPercentIndicator(
                    lineHeight: 6.0,
                    percent: widget.percent,
                    padding: EdgeInsets.zero,
                    progressColor: completedTaskColor,
                    backgroundColor:
                        AFThemeExtension.of(context).progressBarBGColor,
                    barRadius: const Radius.circular(2),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            "${(widget.percent * 100).round()}%",
            style: cellStyle.secondaryTextStyle(),
          ),
        ),
      ],
    );
  }
}
