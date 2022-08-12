import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:flutter/material.dart';

class BoardDateCell extends StatefulWidget {
  final GridCellControllerBuilder cellControllerBuilder;

  const BoardDateCell({
    required this.cellControllerBuilder,
    Key? key,
  }) : super(key: key);

  @override
  State<BoardDateCell> createState() => _BoardDateCellState();
}

class _BoardDateCellState extends State<BoardDateCell> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
