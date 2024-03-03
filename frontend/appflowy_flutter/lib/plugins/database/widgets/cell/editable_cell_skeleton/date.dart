import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/date_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../desktop_grid/desktop_grid_date_cell.dart';
import '../desktop_row_detail/desktop_row_detail_date_cell.dart';
import '../mobile_grid/mobile_grid_date_cell.dart';
import '../mobile_row_detail/mobile_row_detail_date_cell.dart';

abstract class IEditableDateCellSkin {
  const IEditableDateCellSkin();

  factory IEditableDateCellSkin.fromStyle(EditableCellStyle style) {
    return switch (style) {
      EditableCellStyle.desktopGrid => DesktopGridDateCellSkin(),
      EditableCellStyle.desktopRowDetail => DesktopRowDetailDateCellSkin(),
      EditableCellStyle.mobileGrid => MobileGridDateCellSkin(),
      EditableCellStyle.mobileRowDetail => MobileRowDetailDateCellSkin(),
    };
  }

  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    DateCellBloc bloc,
    DateCellState state,
    PopoverController popoverController,
  );
}

class EditableDateCell extends EditableCellWidget {
  EditableDateCell({
    super.key,
    required this.databaseController,
    required this.cellContext,
    required this.skin,
  });

  final DatabaseController databaseController;
  final CellContext cellContext;
  final IEditableDateCellSkin skin;

  @override
  GridCellState<EditableDateCell> createState() => _DateCellState();
}

class _DateCellState extends GridCellState<EditableDateCell> {
  final PopoverController _popover = PopoverController();
  late final cellBloc = DateCellBloc(
    cellController: makeCellController(
      widget.databaseController,
      widget.cellContext,
    ).as(),
  )..add(const DateCellEvent.initial());

  @override
  void dispose() {
    cellBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cellBloc,
      child: BlocBuilder<DateCellBloc, DateCellState>(
        builder: (context, state) {
          return widget.skin.build(
            context,
            widget.cellContainerNotifier,
            cellBloc,
            state,
            _popover,
          );
        },
      ),
    );
  }

  @override
  void onRequestFocus() {
    _popover.show();
    widget.cellContainerNotifier.isFocus = true;
  }

  @override
  String? onCopy() => cellBloc.state.dateStr;
}
