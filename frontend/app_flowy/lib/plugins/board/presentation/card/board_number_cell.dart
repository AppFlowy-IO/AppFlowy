import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:flutter/material.dart';

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
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
