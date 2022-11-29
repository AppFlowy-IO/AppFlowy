import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/application/cell/checklist_cell_bloc.dart';
import 'package:app_flowy/plugins/grid/presentation/layout/sizes.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cell_builder.dart';
import 'checklist_cell_editor.dart';
import 'checklist_prograss_bar.dart';

class GridChecklistCell extends GridCellWidget {
  final GridCellControllerBuilder cellControllerBuilder;
  GridChecklistCell({required this.cellControllerBuilder, Key? key})
      : super(key: key);

  @override
  GridChecklistCellState createState() => GridChecklistCellState();
}

class GridChecklistCellState extends State<GridChecklistCell> {
  late PopoverController _popover;
  late ChecklistCellBloc _cellBloc;

  @override
  void initState() {
    _popover = PopoverController();
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
      child: BlocBuilder<ChecklistCellBloc, ChecklistCellState>(
        builder: (context, state) {
          return Stack(
            alignment: AlignmentDirectional.center,
            fit: StackFit.expand,
            children: [
              Padding(
                padding: GridSize.cellContentInsets,
                child: _wrapPopover(const ChecklistProgressBar()),
              ),
              InkWell(onTap: () => _popover.show()),
            ],
          );
        },
      ),
    );
  }

  Widget _wrapPopover(Widget child) {
    return AppFlowyPopover(
      controller: _popover,
      constraints: BoxConstraints.loose(const Size(260, 400)),
      direction: PopoverDirection.bottomWithLeftAligned,
      triggerActions: PopoverTriggerFlags.none,
      popupBuilder: (BuildContext context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onCellEditing.value = true;
        });
        return GridChecklistCellEditor(
          cellController: widget.cellControllerBuilder.build()
              as GridChecklistCellController,
        );
      },
      onClose: () => widget.onCellEditing.value = false,
      child: child,
    );
  }
}

class ChecklistProgressBar extends StatelessWidget {
  const ChecklistProgressBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChecklistCellBloc, ChecklistCellState>(
      builder: (context, state) {
        return ChecklistPrograssBar(
          percent: state.percent,
        );
      },
    );
  }
}
