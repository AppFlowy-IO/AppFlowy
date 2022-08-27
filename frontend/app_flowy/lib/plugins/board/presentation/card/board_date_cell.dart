import 'package:app_flowy/plugins/board/application/card/board_date_cell_bloc.dart';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BoardDateCell extends StatefulWidget {
  final String groupId;
  final GridCellControllerBuilder cellControllerBuilder;

  const BoardDateCell({
    required this.groupId,
    required this.cellControllerBuilder,
    Key? key,
  }) : super(key: key);

  @override
  State<BoardDateCell> createState() => _BoardDateCellState();
}

class _BoardDateCellState extends State<BoardDateCell> {
  late BoardDateCellBloc _cellBloc;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as GridDateCellController;

    _cellBloc = BoardDateCellBloc(cellController: cellController)
      ..add(const BoardDateCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<BoardDateCellBloc, BoardDateCellState>(
        buildWhen: (previous, current) => previous.dateStr != current.dateStr,
        builder: (context, state) {
          if (state.dateStr.isEmpty) {
            return const SizedBox();
          } else {
            return Align(
              alignment: Alignment.centerLeft,
              child: FlowyText.regular(
                state.dateStr,
                fontSize: 13,
                color: context.read<AppTheme>().shader3,
              ),
            );
          }
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
