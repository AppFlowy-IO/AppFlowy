import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/number_cell/number_cell_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'card_cell.dart';

class NumberCardCellStyle extends CardCellStyle {
  final TextStyle textStyle;

  const NumberCardCellStyle({
    required super.padding,
    required this.textStyle,
  });
}

class NumberCardCell extends CardCell<NumberCardCellStyle> {
  final DatabaseController databaseController;
  final CellContext cellContext;

  const NumberCardCell({
    super.key,
    required super.style,
    required this.databaseController,
    required this.cellContext,
  });

  @override
  State<NumberCardCell> createState() => _NumberCellState();
}

class _NumberCellState extends State<NumberCardCell> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        return NumberCellBloc(
          cellController: makeCellController(
            widget.databaseController,
            widget.cellContext,
          ).as(),
        )..add(const NumberCellEvent.initial());
      },
      child: BlocBuilder<NumberCellBloc, NumberCellState>(
        buildWhen: (previous, current) => previous.content != current.content,
        builder: (context, state) {
          if (state.content.isEmpty) {
            return const SizedBox.shrink();
          }

          return Container(
            alignment: AlignmentDirectional.centerStart,
            padding: widget.style.padding,
            child: Text(state.content, style: widget.style.textStyle),
          );
        },
      ),
    );
  }
}
