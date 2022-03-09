import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/cell_bloc/checkbox_cell_bloc.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CheckboxCell extends StatefulWidget {
  final Field field;
  final Cell? cell;

  const CheckboxCell({
    required this.field,
    required this.cell,
    Key? key,
  }) : super(key: key);

  @override
  State<CheckboxCell> createState() => _CheckboxCellState();
}

class _CheckboxCellState extends State<CheckboxCell> {
  late CheckboxCellBloc _cellBloc;

  @override
  void initState() {
    _cellBloc = getIt<CheckboxCellBloc>(param1: widget.field, param2: widget.cell);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<CheckboxCellBloc, CheckboxCellState>(
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
