import 'dart:async';

import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/cell/cell_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NumberCell extends StatefulWidget {
  final CellData cellData;

  const NumberCell({
    required this.cellData,
    Key? key,
  }) : super(key: key);

  @override
  State<NumberCell> createState() => _NumberCellState();
}

class _NumberCellState extends State<NumberCell> {
  late NumberCellBloc _cellBloc;
  late TextEditingController _controller;
  late CellFocusNode _focusNode;
  Timer? _delayOperation;

  @override
  void initState() {
    _cellBloc = getIt<NumberCellBloc>(param1: widget.cellData);
    _controller = TextEditingController(text: _cellBloc.state.content);
    _focusNode = CellFocusNode();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _focusNode.addCallback(context, focusChanged);

    return BlocProvider.value(
      value: _cellBloc,
      child: BlocConsumer<NumberCellBloc, NumberCellState>(
        listener: (context, state) {
          if (_controller.text != state.content) {
            _controller.text = state.content;
          }
        },
        builder: (context, state) {
          return TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: (value) => focusChanged(),
            onEditingComplete: () => _focusNode.unfocus(),
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
    _delayOperation?.cancel();
    _cellBloc.close();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> focusChanged() async {
    if (mounted) {
      _delayOperation?.cancel();
      _delayOperation = Timer(const Duration(milliseconds: 300), () {
        if (_cellBloc.isClosed == false && _controller.text != _cellBloc.state.content) {
          _cellBloc.add(NumberCellEvent.updateCell(_controller.text));
        }
      });
    }
  }
}
