import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/cell_bloc/cell_service.dart';
import 'package:app_flowy/workspace/application/grid/cell_bloc/date_cell_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DateCell extends StatefulWidget {
  final CellContext cellContext;

  const DateCell({
    required this.cellContext,
    Key? key,
  }) : super(key: key);

  @override
  State<DateCell> createState() => _DateCellState();
}

class _DateCellState extends State<DateCell> {
  late DateCellBloc _cellBloc;

  @override
  void initState() {
    _cellBloc = getIt<DateCellBloc>(param1: widget.cellContext);
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
    _cellBloc.close();
    super.dispose();
  }
}
