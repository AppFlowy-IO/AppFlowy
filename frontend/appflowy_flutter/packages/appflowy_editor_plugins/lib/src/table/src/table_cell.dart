import 'package:appflowy_editor_plugins/src/table/src/models/table_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TableCell extends StatefulWidget {
  const TableCell({Key? key, required this.colIdx, required this.rowIdx})
      : super(key: key);

  final int colIdx;
  final int rowIdx;

  @override
  State<TableCell> createState() => _TableCellState();
}

class _TableCellState extends State<TableCell> {
  late TextEditingController _controller;

  @override
  void initState() {
    final text =
        context.read<TableData>().getCell(widget.colIdx, widget.rowIdx);

    _controller = TextEditingController(text: text);
    _controller.addListener(() => context
        .read<TableData>()
        .setCell(widget.colIdx, widget.rowIdx, _controller.text));

    super.initState();
  }

  @override
  Future<void> dispose() async {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //_controller.text =
    //    context.watch<TableData>().getCell(widget.colIdx, widget.rowIdx);

    return SizedBox(
      child: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
        ),
        //onChanged: (text) {
        //  context.read<TableData>().setCell(widget.colIdx, widget.rowIdx, text);
        //},
      ),
    );
  }
}
