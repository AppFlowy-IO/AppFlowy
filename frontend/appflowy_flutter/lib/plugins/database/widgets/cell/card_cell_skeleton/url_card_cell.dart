import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/url_cell_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'card_cell.dart';

class URLCardCellStyle extends CardCellStyle {
  URLCardCellStyle({
    required super.padding,
    required this.textStyle,
  });

  final TextStyle textStyle;
}

class URLCardCell extends CardCell<URLCardCellStyle> {
  const URLCardCell({
    super.key,
    required super.style,
    required this.databaseController,
    required this.cellContext,
  });

  final DatabaseController databaseController;
  final CellContext cellContext;

  @override
  State<URLCardCell> createState() => _URLCellState();
}

class _URLCellState extends State<URLCardCell> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        return URLCellBloc(
          cellController: makeCellController(
            widget.databaseController,
            widget.cellContext,
          ).as(),
        );
      },
      child: BlocBuilder<URLCellBloc, URLCellState>(
        buildWhen: (previous, current) => previous.content != current.content,
        builder: (context, state) {
          if (state.content.isEmpty) {
            return const SizedBox.shrink();
          }
          return Container(
            alignment: AlignmentDirectional.centerStart,
            padding: widget.style.padding,
            child: Text(
              state.content,
              style: widget.style.textStyle,
            ),
          );
        },
      ),
    );
  }
}
