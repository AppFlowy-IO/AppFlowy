import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CheckboxCell extends StatefulWidget {
  final CellData cellData;

  const CheckboxCell({
    required this.cellData,
    Key? key,
  }) : super(key: key);

  @override
  State<CheckboxCell> createState() => _CheckboxCellState();
}

class _CheckboxCellState extends State<CheckboxCell> {
  late CheckboxCellBloc _cellBloc;

  @override
  void initState() {
    _cellBloc = getIt<CheckboxCellBloc>(param1: widget.cellData);
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
    _cellBloc.close();
    super.dispose();
  }
}
