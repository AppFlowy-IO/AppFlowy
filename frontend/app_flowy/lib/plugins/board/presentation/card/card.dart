import 'package:app_flowy/plugins/board/application/card/card_bloc.dart';
import 'package:app_flowy/plugins/board/application/card/card_data_controller.dart';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'card_cell_builder.dart';

class BoardCard extends StatefulWidget {
  final String gridId;
  final CardDataController dataController;
  final BoardCellBuilder cellBuilder;

  const BoardCard({
    required this.gridId,
    required this.dataController,
    required this.cellBuilder,
    Key? key,
  }) : super(key: key);

  @override
  State<BoardCard> createState() => _BoardCardState();
}

class _BoardCardState extends State<BoardCard> {
  late BoardCardBloc _cardBloc;

  @override
  void initState() {
    _cardBloc = BoardCardBloc(
      gridId: widget.gridId,
      dataController: widget.dataController,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cardBloc,
      child: BlocBuilder<BoardCardBloc, BoardCardState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: _makeCells(context, state.gridCellMap),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _makeCells(BuildContext context, GridCellMap cellMap) {
    return cellMap.values.map(
      (cellId) {
        final child = widget.cellBuilder.buildCell(cellId);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: child,
        );
      },
    ).toList();
  }
}
