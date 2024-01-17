import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/timestamp_cell/timestamp_cell_bloc.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileTimestampCell extends GridCellWidget {
  MobileTimestampCell({
    super.key,
    required this.cellControllerBuilder,
  });

  final CellControllerBuilder cellControllerBuilder;

  @override
  GridCellState<MobileTimestampCell> createState() => _TimestampCellState();
}

class _TimestampCellState extends GridCellState<MobileTimestampCell> {
  late final TimestampCellBloc _cellBloc;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as TimestampCellController;
    _cellBloc = TimestampCellBloc(cellController: cellController)
      ..add(const TimestampCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<TimestampCellBloc, TimestampCellState>(
        builder: (context, state) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: FlowyText(
                state.dateStr,
                fontSize: 15,
                maxLines: 1,
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

  @override
  String? onCopy() => _cellBloc.state.dateStr;

  @override
  void requestBeginFocus() {}
}
