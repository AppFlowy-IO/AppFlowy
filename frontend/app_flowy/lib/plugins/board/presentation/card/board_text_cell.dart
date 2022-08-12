import 'package:app_flowy/plugins/board/application/card/board_text_cell_bloc.dart';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BoardTextCell extends StatefulWidget {
  final GridCellControllerBuilder cellControllerBuilder;
  const BoardTextCell({required this.cellControllerBuilder, Key? key})
      : super(key: key);

  @override
  State<BoardTextCell> createState() => _BoardTextCellState();
}

class _BoardTextCellState extends State<BoardTextCell> {
  late BoardTextCellBloc _cellBloc;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as GridCellController;

    _cellBloc = BoardTextCellBloc(cellController: cellController)
      ..add(const BoardTextCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<BoardTextCellBloc, BoardTextCellState>(
        builder: (context, state) {
          return SizedBox(
            height: 30,
            child: FlowyText.medium(state.content),
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
