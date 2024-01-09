import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
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
  final NumberCellController cellController;

  const NumberCardCell({
    super.key,
    required super.style,
    required this.cellController,
  });

  @override
  State<NumberCardCell> createState() => _NumberCellState();
}

class _NumberCellState extends State<NumberCardCell> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        return NumberCellBloc(cellController: widget.cellController)
          ..add(const NumberCellEvent.initial());
      },
      child: BlocBuilder<NumberCellBloc, NumberCellState>(
        buildWhen: (previous, current) =>
            previous.cellContent != current.cellContent,
        builder: (context, state) {
          if (state.cellContent.isEmpty) {
            return const SizedBox.shrink();
          }

          return Container(
            alignment: AlignmentDirectional.centerStart,
            padding: widget.style.padding,
            child: Text(state.cellContent, style: widget.style.textStyle),
          );
        },
      ),
    );
  }
}
