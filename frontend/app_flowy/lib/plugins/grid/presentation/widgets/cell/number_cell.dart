import 'dart:async';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/plugins/grid/application/prelude.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../layout/sizes.dart';
import 'cell_builder.dart';

class GridNumberCell extends GridCellWidget {
  final GridCellControllerBuilder cellControllerBuilder;

  GridNumberCell({
    required this.cellControllerBuilder,
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
    final cellController = widget.cellControllerBuilder.build();
    _cellBloc = getIt<NumberCellBloc>(param1: cellController)
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
        child: Padding(
          padding: GridSize.cellContentInsets,
          child: TextField(
            controller: _controller,
            focusNode: focusNode,
            onEditingComplete: () => focusNode.unfocus(),
            onSubmitted: (_) => focusNode.unfocus(),
            maxLines: 1,
            style: Theme.of(context).textTheme.bodyMedium,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _delayOperation = null;
    _cellBloc.close();
    super.dispose();
  }

  @override
  Future<void> focusChanged() async {
    if (mounted) {
      _delayOperation?.cancel();
      _delayOperation = Timer(const Duration(milliseconds: 30), () {
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
