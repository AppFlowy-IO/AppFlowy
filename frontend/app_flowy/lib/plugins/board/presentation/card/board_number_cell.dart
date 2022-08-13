import 'package:app_flowy/plugins/board/application/card/board_number_cell_bloc.dart';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BoardNumberCell extends StatefulWidget {
  final GridCellControllerBuilder cellControllerBuilder;

  const BoardNumberCell({
    required this.cellControllerBuilder,
    Key? key,
  }) : super(key: key);

  @override
  State<BoardNumberCell> createState() => _BoardNumberCellState();
}

class _BoardNumberCellState extends State<BoardNumberCell> {
  late BoardNumberCellBloc _cellBloc;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as GridNumberCellController;

    _cellBloc = BoardNumberCellBloc(cellController: cellController)
      ..add(const BoardNumberCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<BoardNumberCellBloc, BoardNumberCellState>(
        builder: (context, state) {
          if (state.content.isEmpty) {
            return const SizedBox();
          } else {
            return Align(
              alignment: Alignment.centerLeft,
              child: FlowyText.regular(
                state.content,
                fontSize: 14,
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
