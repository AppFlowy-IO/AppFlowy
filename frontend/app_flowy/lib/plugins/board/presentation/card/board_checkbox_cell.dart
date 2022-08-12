import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:flutter/material.dart';

class BoardCheckboxCell extends StatefulWidget {
  final GridCellControllerBuilder cellControllerBuilder;

  const BoardCheckboxCell({
    required this.cellControllerBuilder,
    Key? key,
  }) : super(key: key);

  @override
  State<BoardCheckboxCell> createState() => _BoardCheckboxCellState();
}

class _BoardCheckboxCellState extends State<BoardCheckboxCell> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
