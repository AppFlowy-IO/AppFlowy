import 'package:app_flowy/plugins/board/application/card/board_url_cell_bloc.dart';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'define.dart';

class BoardUrlCell extends StatefulWidget {
  final String groupId;
  final GridCellControllerBuilder cellControllerBuilder;

  const BoardUrlCell({
    required this.groupId,
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
        buildWhen: (previous, current) => previous.content != current.content,
        builder: (context, state) {
          if (state.content.isEmpty) {
            return const SizedBox();
          } else {
            return Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: BoardSizes.cardCellVPadding,
                ),
                child: RichText(
                  textAlign: TextAlign.left,
                  text: TextSpan(
                    text: state.content,
                    style: TextStyle(
                      color: theme.main2,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
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
