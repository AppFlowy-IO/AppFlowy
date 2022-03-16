import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/cell_bloc/cell_service.dart';
import 'package:app_flowy/workspace/application/grid/cell_bloc/number_cell_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NumberCell extends StatefulWidget {
  final CellContext cellContext;

  const NumberCell({
    required this.cellContext,
    Key? key,
  }) : super(key: key);

  @override
  State<NumberCell> createState() => _NumberCellState();
}

class _NumberCellState extends State<NumberCell> {
  late NumberCellBloc _cellBloc;

  @override
  void initState() {
    _cellBloc = getIt<NumberCellBloc>(param1: widget.cellContext);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<NumberCellBloc, NumberCellState>(
        builder: (context, state) {
          return Container();
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    await _cellBloc.close();
    super.dispose();
  }
}
