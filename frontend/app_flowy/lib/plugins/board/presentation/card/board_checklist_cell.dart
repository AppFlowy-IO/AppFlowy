import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/application/cell/checklist_cell_bloc.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/cell/checklist_cell/checklist_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BoardChecklistCell extends StatefulWidget {
  final GridCellControllerBuilder cellControllerBuilder;
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
        widget.cellControllerBuilder.build() as GridChecklistCellController;
    _cellBloc = ChecklistCellBloc(cellController: cellController);
    _cellBloc.add(const ChecklistCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: const ChecklistProgressBar(),
    );
  }
}
