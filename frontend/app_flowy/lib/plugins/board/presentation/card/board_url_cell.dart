import 'package:app_flowy/plugins/board/application/card/board_url_cell_bloc.dart';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BoardUrlCell extends StatefulWidget {
  final GridCellControllerBuilder cellControllerBuilder;

  const BoardUrlCell({
    required this.cellControllerBuilder,
    Key? key,
  }) : super(key: key);

  @override
  State<BoardUrlCell> createState() => _BoardUrlCellState();
}

class _BoardUrlCellState extends State<BoardUrlCell> {
  late BoardURLCellBloc _cellBloc;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as GridURLCellController;
    _cellBloc = BoardURLCellBloc(cellController: cellController);
    _cellBloc.add(const BoardURLCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<BoardURLCellBloc, BoardURLCellState>(
        builder: (context, state) {
          final richText = RichText(
            textAlign: TextAlign.left,
            text: TextSpan(
              text: state.content,
              style: TextStyle(
                color: theme.main2,
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          );

          return Align(
            alignment: Alignment.centerLeft,
            child: richText,
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
