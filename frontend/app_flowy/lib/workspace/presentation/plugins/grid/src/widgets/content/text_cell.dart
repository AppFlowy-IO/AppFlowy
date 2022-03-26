import 'dart:async';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The interface of base cell.

class GridTextCell extends StatefulWidget {
  final FutureCellData cellData;
  const GridTextCell({
    required this.cellData,
    Key? key,
  }) : super(key: key);

  @override
  State<GridTextCell> createState() => _GridTextCellState();
}

class _GridTextCellState extends State<GridTextCell> {
  late TextEditingController _controller;
  Timer? _delayOperation;
  final _focusNode = FocusNode();
  TextCellBloc? _cellBloc;

  @override
  void initState() {
    _cellBloc = getIt<TextCellBloc>(param1: widget.cellData);
    _controller = TextEditingController(text: _cellBloc!.state.content);
    _focusNode.addListener(save);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc!,
      child: BlocConsumer<TextCellBloc, TextCellState>(
        listener: (context, state) {
          if (_controller.text != state.content) {
            _controller.text = state.content;
          }
        },
        builder: (context, state) {
          return TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: (value) {
              Log.info("On change");
              save();
            },
            onEditingComplete: () {
              Log.info("On complete");
            },
            onSubmitted: (value) {
              Log.info("On submit");
            },
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
    _cellBloc?.close();
    _cellBloc = null;
    _focusNode.removeListener(save);
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> save() async {
    _delayOperation?.cancel();
    _delayOperation = Timer(const Duration(seconds: 2), () {
      _cellBloc?.add(TextCellEvent.updateText(_controller.text));
    });
    // and later, before the timer goes off...
  }
}
