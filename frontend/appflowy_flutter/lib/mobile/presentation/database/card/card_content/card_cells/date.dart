import 'package:appflowy/mobile/presentation/database/card/card_content/card_cells/style.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/card_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/date_cell/date_cell_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileDateCardCell<CustomCardData> extends CardCell {
  const MobileDateCardCell({
    super.key,
    required this.cellControllerBuilder,
    this.renderHook,
  });

  final CellControllerBuilder cellControllerBuilder;
  final CellRenderHook<dynamic, CustomCardData>? renderHook;

  @override
  State<MobileDateCardCell> createState() => _DateCellState();
}

class _DateCellState extends State<MobileDateCardCell> {
  late final DateCellBloc _cellBloc;

  @override
  void initState() {
    super.initState();
    final cellController =
        widget.cellControllerBuilder.build() as DateCellController;

    _cellBloc = DateCellBloc(cellController: cellController)
      ..add(const DateCellEvent.initial());
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
      child: BlocBuilder<DateCellBloc, DateCellState>(
        buildWhen: (previous, current) => previous.dateStr != current.dateStr,
        builder: (context, state) {
          if (state.dateStr.isEmpty) {
            return const SizedBox();
          } else {
            final Widget? custom = widget.renderHook?.call(
              state.data,
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
                state.dateStr,
                style: cellStyle.secondaryTextStyle(),
              ),
            );
          }
        },
      ),
    );
  }
}
