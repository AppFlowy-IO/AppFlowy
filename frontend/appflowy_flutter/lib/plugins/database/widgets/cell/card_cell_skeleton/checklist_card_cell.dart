import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/checklist_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/checklist_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'card_cell.dart';

class ChecklistCardCellStyle extends CardCellStyle {
  ChecklistCardCellStyle({
    required super.padding,
    required this.textStyle,
  });

  final TextStyle textStyle;
}

class ChecklistCardCell extends CardCell<ChecklistCardCellStyle> {
  const ChecklistCardCell({
    super.key,
    required super.style,
    required this.databaseController,
    required this.cellContext,
  });

  final DatabaseController databaseController;
  final CellContext cellContext;

  @override
  State<ChecklistCardCell> createState() => _ChecklistCellState();
}

class _ChecklistCellState extends State<ChecklistCardCell> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        return ChecklistCellBloc(
          cellController: makeCellController(
            widget.databaseController,
            widget.cellContext,
          ).as(),
        );
      },
      child: BlocBuilder<ChecklistCellBloc, ChecklistCellState>(
        builder: (context, state) {
          if (state.tasks.isEmpty) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: widget.style.padding,
            child: ChecklistProgressBar(
              tasks: state.tasks,
              percent: state.percent,
              textStyle: widget.style.textStyle,
            ),
          );
        },
      ),
    );
  }
}
