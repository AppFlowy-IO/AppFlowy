import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/select_option_cell/extension.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/select_option_cell/select_option_cell_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'card_cell.dart';

class SelectOptionCardCellStyle extends CardCellStyle {
  final double tagFontSize;
  final bool wrap;
  final EdgeInsets tagPadding;

  SelectOptionCardCellStyle({
    required super.padding,
    required this.tagFontSize,
    required this.wrap,
    required this.tagPadding,
  });
}

class SelectOptionCardCell extends CardCell<SelectOptionCardCellStyle> {
  final SelectOptionCellController cellController;

  const SelectOptionCardCell({
    super.key,
    required super.style,
    required this.cellController,
  });

  @override
  State<SelectOptionCardCell> createState() => _SelectOptionCellState();
}

class _SelectOptionCellState extends State<SelectOptionCardCell> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        return SelectOptionCellBloc(cellController: widget.cellController)
          ..add(const SelectOptionCellEvent.initial());
      },
      child: BlocBuilder<SelectOptionCellBloc, SelectOptionCellState>(
        buildWhen: (previous, current) {
          return previous.selectedOptions != current.selectedOptions;
        },
        builder: (context, state) {
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
                ? Wrap(spacing: 4, runSpacing: 2, children: children)
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
