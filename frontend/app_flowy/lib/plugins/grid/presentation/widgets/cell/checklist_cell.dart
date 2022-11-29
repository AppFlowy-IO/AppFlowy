import 'package:flutter/material.dart';

import 'cell_builder.dart';

class GridChecklistCell extends GridCellWidget {
  GridChecklistCell({Key? key}) : super(key: key);

  @override
  ChecklistCellState createState() => ChecklistCellState();
}

class ChecklistCellState extends State<GridChecklistCell> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
