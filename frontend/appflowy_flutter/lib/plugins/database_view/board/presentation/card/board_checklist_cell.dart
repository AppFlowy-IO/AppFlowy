import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/cell/cell_service.dart';
import '../../../grid/application/cell/checklist_cell_bloc.dart';
import '../../../grid/presentation/widgets/cell/checklist_cell/checklist_progress_bar.dart';

class BoardChecklistCell extends StatefulWidget {
  final CellControllerBuilder cellControllerBuilder;
  const BoardChecklistCell({required this.cellControllerBuilder, Key? key})
      : super(key: key);

  @override
  State<BoardChecklistCell> createState() => _BoardChecklistCellState();
}

class _BoardChecklistCellState extends State<BoardChecklistCell> {
  late ChecklistCellBloc _cellBloc;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as ChecklistCellController;
    _cellBloc = ChecklistCellBloc(cellController: cellController);
    _cellBloc.add(const ChecklistCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<ChecklistCellBloc, ChecklistCellState>(
        builder: (context, state) =>
            ChecklistProgressBar(percent: state.percent),
      ),
    );
  }
}
