import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/cell_bloc/number_cell_bloc.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/meta.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NumberCell extends StatefulWidget {
  final Field field;
  final Cell? cell;

  const NumberCell({
    required this.field,
    required this.cell,
    Key? key,
  }) : super(key: key);

  @override
  State<NumberCell> createState() => _NumberCellState();
}

class _NumberCellState extends State<NumberCell> {
  late NumberCellBloc _cellBloc;

  @override
  void initState() {
    _cellBloc = getIt<NumberCellBloc>(param1: widget.field, param2: widget.cell);
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
