import 'dart:async';

import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cell_builder.dart';

class NumberCell extends GridCellWidget {
  final GridCell cellData;

  NumberCell({
    required this.cellData,
    Key? key,
  }) : super(key: key);

  @override
  State<NumberCell> createState() => _NumberCellState();
}

class _NumberCellState extends State<NumberCell> {
  late NumberCellBloc _cellBloc;
  late TextEditingController _controller;
  late FocusNode _focusNode;
  Timer? _delayOperation;

  @override
  void initState() {
    _cellBloc = getIt<NumberCellBloc>(param1: widget.cellData)..add(const NumberCellEvent.initial());
    _controller = TextEditingController(text: _cellBloc.state.content);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      widget.onFocus.value = _focusNode.hasFocus;
      focusChanged();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
          final number = num.tryParse(_controller.text);
          if (number != null) {
            _cellBloc.add(NumberCellEvent.updateCell(_controller.text));
          } else {
            _controller.text = "";
          }
        }
      });
    }
  }
}
