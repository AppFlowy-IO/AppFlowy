import 'dart:async';

import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cell_builder.dart';

class NumberCell extends StatefulWidget with GridCellWidget {
  final GridCellContextBuilder cellContextBuilder;

  NumberCell({
    required this.cellContextBuilder,
    Key? key,
  }) : super(key: key);

  @override
  State<NumberCell> createState() => _NumberCellState();
}

class _NumberCellState extends State<NumberCell> {
  late NumberCellBloc _cellBloc;
  late TextEditingController _controller;
  late SingleListenrFocusNode _focusNode;
  Timer? _delayOperation;

  @override
  void initState() {
    final cellContext = widget.cellContextBuilder.build();
    _cellBloc = getIt<NumberCellBloc>(param1: cellContext)..add(const NumberCellEvent.initial());
    _controller = TextEditingController(text: contentFromState(_cellBloc.state));
    _focusNode = SingleListenrFocusNode();
    _listenOnFocusNodeChanged();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _handleCellRequestFocus(context);
    return BlocProvider.value(
      value: _cellBloc,
      child: MultiBlocListener(
        listeners: [
          BlocListener<NumberCellBloc, NumberCellState>(
            listenWhen: (p, c) => p.content != c.content,
            listener: (context, state) => _controller.text = contentFromState(state),
          ),
        ],
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onEditingComplete: () => _focusNode.unfocus(),
          maxLines: null,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            isDense: true,
          ),
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    widget.beginFocus.removeAllListener();
    _delayOperation?.cancel();
    _cellBloc.close();
    _focusNode.removeAllListener();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant NumberCell oldWidget) {
    _listenOnFocusNodeChanged();
    super.didUpdateWidget(oldWidget);
  }

  Future<void> focusChanged() async {
    if (mounted) {
      _delayOperation?.cancel();
      _delayOperation = Timer(const Duration(milliseconds: 300), () {
        if (_cellBloc.isClosed == false && _controller.text != contentFromState(_cellBloc.state)) {
          _cellBloc.add(NumberCellEvent.updateCell(_controller.text));
        }
      });
    }
  }

  void _listenOnFocusNodeChanged() {
    widget.onFocus.value = _focusNode.hasFocus;
    _focusNode.setListener(() {
      widget.onFocus.value = _focusNode.hasFocus;
      focusChanged();
    });
  }

  void _handleCellRequestFocus(BuildContext context) {
    widget.beginFocus.setListener(() {
      if (_focusNode.hasFocus == false && _focusNode.canRequestFocus) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  String contentFromState(NumberCellState state) {
    return state.content.fold((l) => l, (r) => "");
  }
}
