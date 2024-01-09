import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/select_option_cell/select_option_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../desktop_grid/desktop_grid_select_option_cell.dart';
import '../desktop_row_detail/desktop_row_detail_select_option_cell.dart';
import '../mobile_grid/mobile_grid_select_option_cell.dart';
import '../mobile_row_detail/mobile_row_detail_select_cell_option.dart';

abstract class IEditableSelectOptionCellSkin {
  const IEditableSelectOptionCellSkin();

  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    SelectOptionCellBloc bloc,
    SelectOptionCellState state,
    PopoverController popoverController,
  );

  factory IEditableSelectOptionCellSkin.fromStyle(EditableCellStyle style) {
    return switch (style) {
      EditableCellStyle.desktopGrid => DesktopGridSelectOptionCellSkin(),
      EditableCellStyle.desktopRowDetail =>
        DesktopRowDetailSelectOptionCellSkin(),
      EditableCellStyle.mobileGrid => MobileGridSelectOptionCellSkin(),
      EditableCellStyle.mobileRowDetail =>
        MobileRowDetailSelectOptionCellSkin(),
    };
  }
}

class EditableSelectOptionCell extends EditableCellWidget {
  final SelectOptionCellController cellController;
  final IEditableSelectOptionCellSkin builder;

  EditableSelectOptionCell({
    super.key,
    required this.cellController,
    required this.builder,
  });

  @override
  GridCellState<EditableSelectOptionCell> createState() =>
      _SelectOptionCellState();
}

class _SelectOptionCellState extends GridCellState<EditableSelectOptionCell> {
  final PopoverController _popover = PopoverController();

  SelectOptionCellBloc get cellBloc => context.read<SelectOptionCellBloc>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        return SelectOptionCellBloc(cellController: widget.cellController)
          ..add(const SelectOptionCellEvent.initial());
      },
      child: BlocBuilder<SelectOptionCellBloc, SelectOptionCellState>(
        builder: (context, state) {
          return widget.builder.build(
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
  void requestBeginFocus() => _popover.show();
}
