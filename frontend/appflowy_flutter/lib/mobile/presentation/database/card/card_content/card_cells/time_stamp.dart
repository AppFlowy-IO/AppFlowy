import 'package:appflowy/mobile/presentation/database/card/card_content/card_cells/style.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/card_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/timestamp_cell/timestamp_cell_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileTimestampCardCell<CustomCardData> extends CardCell {
  const MobileTimestampCardCell({
    super.key,
    required this.cellControllerBuilder,
    this.renderHook,
  });

  final CellControllerBuilder cellControllerBuilder;
  final CellRenderHook<dynamic, CustomCardData>? renderHook;

  @override
  State<MobileTimestampCardCell> createState() => _TimestampCellState();
}

class _TimestampCellState extends State<MobileTimestampCardCell> {
  late final TimestampCellBloc _cellBloc;

  @override
  void initState() {
    super.initState();
    final cellController =
        widget.cellControllerBuilder.build() as TimestampCellController;

    _cellBloc = TimestampCellBloc(cellController: cellController)
      ..add(const TimestampCellEvent.initial());
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
      child: BlocBuilder<TimestampCellBloc, TimestampCellState>(
        buildWhen: (previous, current) => previous.dateStr != current.dateStr,
        builder: (context, state) {
          if (state.dateStr.isEmpty) {
            return const SizedBox.shrink();
          }
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
        },
      ),
    );
  }
}
