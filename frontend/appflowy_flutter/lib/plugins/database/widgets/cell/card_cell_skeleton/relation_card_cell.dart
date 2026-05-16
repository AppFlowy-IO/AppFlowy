import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/relation_cell_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'card_cell.dart';

class RelationCardCellStyle extends CardCellStyle {
  RelationCardCellStyle({
    required super.padding,
    required this.textStyle,
    required this.wrap,
  });

  final TextStyle textStyle;
  final bool wrap;
}

class RelationCardCell extends CardCell<RelationCardCellStyle> {
  const RelationCardCell({
    super.key,
    required super.style,
    required this.databaseController,
    required this.cellContext,
  });

  final DatabaseController databaseController;
  final CellContext cellContext;

  @override
  State<RelationCardCell> createState() => _RelationCellState();
}

class _RelationCellState extends State<RelationCardCell> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        return RelationCellBloc(
          cellController: makeCellController(
            widget.databaseController,
            widget.cellContext,
          ).as(),
        );
      },
      child: BlocBuilder<RelationCellBloc, RelationCellState>(
        builder: (context, state) {
          if (state.rows.isEmpty) {
            return const SizedBox.shrink();
          }

          final children = state.rows.map(
            (row) {
              final isEmpty = row.name.isEmpty;
              return Text(
                isEmpty ? LocaleKeys.grid_row_titlePlaceholder.tr() : row.name,
                style: widget.style.textStyle.copyWith(
                  color: isEmpty ? Theme.of(context).hintColor : null,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              );
            },
          ).toList();

          return Container(
            alignment: AlignmentDirectional.topStart,
            padding: widget.style.padding,
            child: widget.style.wrap
                ? Wrap(spacing: 4, runSpacing: 4, children: children)
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: children,
                    ),
                  ),
          );
        },
      ),
    );
  }
}
