import 'dart:async';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/plugins/grid/application/prelude.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cell_builder.dart';

class GridNumberCell extends GridCellWidget {
  final GridCellControllerBuilder cellContorllerBuilder;

  GridNumberCell({
    required this.cellContorllerBuilder,
    Key? key,
  }) : super(key: key);

  @override
  GridFocusNodeCellState<GridNumberCell> createState() => _NumberCellState();
}

class _NumberCellState extends GridFocusNodeCellState<GridNumberCell> {
  late NumberCellBloc _cellBloc;
  late TextEditingController _controller;
  Timer? _delayOperation;

  @override
  void initState() {
    final cellContext = widget.cellContorllerBuilder.build();
    _cellBloc = getIt<NumberCellBloc>(param1: cellContext)
      ..add(const NumberCellEvent.initial());
    _controller =
        TextEditingController(text: contentFromState(_cellBloc.state));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: MultiBlocListener(
        listeners: [
          BlocListener<NumberCellBloc, NumberCellState>(
            listenWhen: (p, c) => p.content != c.content,
            listener: (context, state) =>
                _controller.text = contentFromState(state),
          ),
        ],
        child: TextField(
          controller: _controller,
          focusNode: focusNode,
          onEditingComplete: () => focusNode.unfocus(),
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
    _delayOperation?.cancel();
    _cellBloc.close();
    super.dispose();
  }

  @override
  Future<void> focusChanged() async {
    if (mounted) {
      _delayOperation?.cancel();
      _delayOperation = Timer(const Duration(milliseconds: 300), () {
        if (_cellBloc.isClosed == false &&
            _controller.text != contentFromState(_cellBloc.state)) {
          _cellBloc.add(NumberCellEvent.updateCell(_controller.text));
        }
      });
    }
  }

  String contentFromState(NumberCellState state) {
    return state.content.fold((l) => l, (r) => "");
  }

  @override
  String? onCopy() {
    return _cellBloc.state.content.fold((content) => content, (r) => null);
  }

  @override
  void onInsert(String value) {
    _cellBloc.add(NumberCellEvent.updateCell(value));
  }
}
