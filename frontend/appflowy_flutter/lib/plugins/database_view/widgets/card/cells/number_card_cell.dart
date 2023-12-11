import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/number_cell/number_cell_bloc.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../define.dart';
import 'card_cell.dart';

class NumberCardCellStyle extends CardCellStyle {
  final double fontSize;

  NumberCardCellStyle(this.fontSize);
}

class NumberCardCell<CustomCardData>
    extends CardCell<CustomCardData, NumberCardCellStyle> {
  final CellRenderHook<String, CustomCardData>? renderHook;
  final CellControllerBuilder cellControllerBuilder;

  const NumberCardCell({
    required this.cellControllerBuilder,
    super.cardData,
    super.style,
    this.renderHook,
    super.key,
  });

  @override
  State<NumberCardCell> createState() => _NumberCellState();
}

class _NumberCellState extends State<NumberCardCell> {
  late NumberCellBloc _cellBloc;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as NumberCellController;

    _cellBloc = NumberCellBloc(cellController: cellController)
      ..add(const NumberCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<NumberCellBloc, NumberCellState>(
        buildWhen: (previous, current) =>
            previous.cellContent != current.cellContent,
        builder: (context, state) {
          if (state.cellContent.isEmpty) {
            return const SizedBox.shrink();
          }
          final Widget? custom = widget.renderHook?.call(
            state.cellContent,
            widget.cardData,
            context,
          );
          if (custom != null) {
            return custom;
          }

          return Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: CardSizes.cardCellPadding,
              child: FlowyText.regular(
                state.cellContent,
                fontSize: widget.style?.fontSize ?? 11,
                color: Theme.of(context).hintColor,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    super.dispose();
  }
}
