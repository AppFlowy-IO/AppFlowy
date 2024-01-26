import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/extension.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/select_option_cell_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'card_cell.dart';

class SelectOptionCardCellStyle extends CardCellStyle {
  SelectOptionCardCellStyle({
    required super.padding,
    required this.tagFontSize,
    required this.wrap,
    required this.tagPadding,
  });

  final double tagFontSize;
  final bool wrap;
  final EdgeInsets tagPadding;
}

class SelectOptionCardCell extends CardCell<SelectOptionCardCellStyle> {
  const SelectOptionCardCell({
    super.key,
    required super.style,
    required this.databaseController,
    required this.cellContext,
  });

  final DatabaseController databaseController;
  final CellContext cellContext;

  @override
  State<SelectOptionCardCell> createState() => _SelectOptionCellState();
}

class _SelectOptionCellState extends State<SelectOptionCardCell> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        return SelectOptionCellBloc(
          cellController: makeCellController(
            widget.databaseController,
            widget.cellContext,
          ).as(),
        )..add(const SelectOptionCellEvent.initial());
      },
      child: BlocBuilder<SelectOptionCellBloc, SelectOptionCellState>(
        buildWhen: (previous, current) {
          return previous.selectedOptions != current.selectedOptions;
        },
        builder: (context, state) {
          if (state.selectedOptions.isEmpty) {
            return const SizedBox.shrink();
          }

          final children = state.selectedOptions
              .map(
                (option) => SelectOptionTag(
                  option: option,
                  fontSize: widget.style.tagFontSize,
                  padding: widget.style.tagPadding,
                ),
              )
              .toList();

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
