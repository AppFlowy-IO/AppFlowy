import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/cell/cell_container.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'extension.dart';

class SingleSelectCell extends StatefulWidget {
  final FutureCellData cellData;

  const SingleSelectCell({
    required this.cellData,
    Key? key,
  }) : super(key: key);

  @override
  State<SingleSelectCell> createState() => _SingleSelectCellState();
}

class _SingleSelectCellState extends State<SingleSelectCell> {
  late CellFocusNode _focusNode;
  late SelectionCellBloc _cellBloc;
  late TextEditingController _controller;

  @override
  void initState() {
    _cellBloc = getIt<SelectionCellBloc>(param1: widget.cellData);
    _controller = TextEditingController();
    _focusNode = CellFocusNode();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _focusNode.addCallback(context, () {
      Log.info(_focusNode.hasFocus);
    });
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<SelectionCellBloc, SelectionCellState>(
        builder: (context, state) {
          return SelectOptionTextField(
            focusNode: _focusNode,
            controller: _controller,
          );
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    _focusNode.dispose();
    super.dispose();
  }
}

//----------------------------------------------------------------
class MultiSelectCell extends StatefulWidget {
  final FutureCellData cellData;

  const MultiSelectCell({
    required this.cellData,
    Key? key,
  }) : super(key: key);

  @override
  State<MultiSelectCell> createState() => _MultiSelectCellState();
}

class _MultiSelectCellState extends State<MultiSelectCell> {
  late SelectionCellBloc _cellBloc;

  @override
  void initState() {
    _cellBloc = getIt<SelectionCellBloc>(param1: widget.cellData);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    super.dispose();
  }
}
