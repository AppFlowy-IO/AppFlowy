import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'extension.dart';
import 'selection_editor.dart';

class SingleSelectCell extends StatefulWidget {
  final CellData cellData;

  const SingleSelectCell({
    required this.cellData,
    Key? key,
  }) : super(key: key);

  @override
  State<SingleSelectCell> createState() => _SingleSelectCellState();
}

class _SingleSelectCellState extends State<SingleSelectCell> {
  late SelectionCellBloc _cellBloc;

  @override
  void initState() {
    _cellBloc = getIt<SelectionCellBloc>(param1: widget.cellData)..add(const SelectionCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<SelectionCellBloc, SelectionCellState>(
        builder: (context, state) {
          final children = state.selectedOptions.map((option) => SelectOptionTag(option: option)).toList();
          return SizedBox.expand(
            child: InkWell(
              onTap: () {
                SelectOptionEditor.show(context, state.cellData, state.options, state.selectedOptions);
              },
              child: Row(children: children),
            ),
          );
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    super.dispose();
  }
}

//----------------------------------------------------------------
class MultiSelectCell extends StatefulWidget {
  final CellData cellData;

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
    _cellBloc = getIt<SelectionCellBloc>(param1: widget.cellData)..add(const SelectionCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<SelectionCellBloc, SelectionCellState>(
        builder: (context, state) {
          final children = state.selectedOptions.map((option) => SelectOptionTag(option: option)).toList();
          return SizedBox.expand(
            child: InkWell(
              onTap: () {
                SelectOptionEditor.show(context, state.cellData, state.options, state.selectedOptions);
              },
              child: Row(children: children),
            ),
          );
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    super.dispose();
  }
}
