import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:flutter/material.dart';

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
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
