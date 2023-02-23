import 'package:flutter/material.dart';

class TableCell extends StatefulWidget {
  const TableCell({
    Key? key,
    this.data = '',
  }) : super(key: key);

  final String data;

  @override
  State<TableCell> createState() => _TableCellState();
}

class _TableCellState extends State<TableCell> {
  late TextEditingController _controller;

  @override
  void initState() {
    _controller = TextEditingController(text: widget.data);
    super.initState();
  }

  @override
  Future<void> dispose() async {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            onChanged: (txt) {
              setState(() {
                _controller.text = txt;
              });
            }));
  }
}
