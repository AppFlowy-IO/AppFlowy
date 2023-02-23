import 'package:appflowy_editor_plugins/src/table/src/table_col.dart';
import 'package:flutter/material.dart';

class TableView extends StatefulWidget {
  const TableView({
    Key? key,
    this.data = const [
      ['1', '2'],
      ['3', '4']
    ],
  }) : super(key: key);

  final List<List<String>> data;

  @override
  State<TableView> createState() => _TableViewState();
}

class _TableViewState extends State<TableView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      width: 225,
      child: Row(
        children: [
          Container(
            height: 100,
            width: 1,
            color: Colors.grey,
          ),
          TableCol(data: widget.data[0]),
          Container(
            height: 100,
            width: 1,
            color: Colors.grey,
          ),
          TableCol(data: widget.data[1]),
          Container(
            height: 100,
            width: 1,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}
