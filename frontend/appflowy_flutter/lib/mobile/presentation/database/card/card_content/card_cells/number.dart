import 'package:appflowy/mobile/presentation/database/card/card_content/card_cells/style.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/card_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/number_cell/number_cell_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileNumberCardCell<CustomCardData> extends CardCell {
  const MobileNumberCardCell({
    super.key,
    required this.cellControllerBuilder,
    CustomCardData? cardData,
    this.renderHook,
  });

  final CellRenderHook<String, CustomCardData>? renderHook;
  final CellControllerBuilder cellControllerBuilder;

  @override
  State<MobileNumberCardCell> createState() => _NumberCellState();
}

class _NumberCellState extends State<MobileNumberCardCell> {
  late final NumberCellBloc _cellBloc;

  @override
  void initState() {
    super.initState();
    final cellController =
        widget.cellControllerBuilder.build() as NumberCellController;

    _cellBloc = NumberCellBloc(cellController: cellController)
      ..add(const NumberCellEvent.initial());
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cellStyle = MobileCardCellStyle(context);
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<NumberCellBloc, NumberCellState>(
        buildWhen: (previous, current) =>
            previous.cellContent != current.cellContent,
        builder: (context, state) {
          if (state.cellContent.isEmpty) {
            return const SizedBox();
          } else {
            final Widget? custom = widget.renderHook?.call(
              state.cellContent,
              widget.cardData,
              context,
            );
            if (custom != null) {
              return custom;
            }

            return Container(
              alignment: Alignment.centerLeft,
              padding: cellStyle.padding,
              child: Text(
                state.cellContent,
                style: cellStyle.primaryTextStyle(),
              ),
            );
          }
        },
      ),
    );
  }
}
