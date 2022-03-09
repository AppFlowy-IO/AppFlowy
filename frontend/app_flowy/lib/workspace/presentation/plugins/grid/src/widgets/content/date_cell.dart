import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/cell_bloc/date_cell_bloc.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DateCell extends StatefulWidget {
  final Field field;
  final Cell? cell;

  const DateCell({
    required this.field,
    required this.cell,
    Key? key,
  }) : super(key: key);

  @override
  State<DateCell> createState() => _DateCellState();
}

class _DateCellState extends State<DateCell> {
  late DateCellBloc _cellBloc;

  @override
  void initState() {
    _cellBloc = getIt<DateCellBloc>(param1: widget.field, param2: widget.cell);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<DateCellBloc, DateCellState>(
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
