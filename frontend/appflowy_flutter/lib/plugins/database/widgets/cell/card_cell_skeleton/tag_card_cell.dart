import 'package:appflowy/plugins/database/application/cell/bloc/tag_cell.bloc.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'card_cell.dart';

class TagCardCellStyle extends CardCellStyle {
  const TagCardCellStyle({
    required super.padding,
    required this.textStyle,
  });

  final TextStyle textStyle;
}

class TagCardCell extends CardCell<TagCardCellStyle> {
  const TagCardCell({
    super.key,
    required super.style,
    required this.databaseController,
    required this.cellContext,
  });

  final DatabaseController databaseController;
  final CellContext cellContext;

  @override
  State<TagCardCell> createState() => _TagCellState();
}

class _TagCellState extends State<TagCardCell> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        return TagCellBloc(
          cellController: makeCellController(
            widget.databaseController,
            widget.cellContext,
          ).as(),
        );
      },
      child: BlocBuilder<TagCellBloc, TagCellState>(
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
