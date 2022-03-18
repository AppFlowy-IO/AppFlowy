import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/cell_bloc/text_cell_bloc.dart';
import 'package:app_flowy/workspace/application/grid/row_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The interface of base cell.

class GridTextCell extends StatefulWidget {
  final GridCellData cellData;
  const GridTextCell({
    required this.cellData,
    Key? key,
  }) : super(key: key);

  @override
  State<GridTextCell> createState() => _GridTextCellState();
}

class _GridTextCellState extends State<GridTextCell> {
  late TextEditingController _controller;
  final _focusNode = FocusNode();
  late TextCellBloc _cellBloc;

  @override
  void initState() {
    _cellBloc = getIt<TextCellBloc>(param1: widget.cellData);
    _controller = TextEditingController(text: _cellBloc.state.content);
    _focusNode.addListener(_focusChanged);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<TextCellBloc, TextCellState>(
        builder: (context, state) {
          return TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: (value) {},
            maxLines: 1,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              isDense: true,
            ),
          );
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    _focusNode.removeListener(_focusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _focusChanged() {
    _cellBloc.add(TextCellEvent.updateText(_controller.text));
  }
}
