import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/select_option_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../desktop_grid/desktop_grid_select_option_cell.dart';
import '../desktop_row_detail/desktop_row_detail_select_option_cell.dart';
import '../mobile_grid/mobile_grid_select_option_cell.dart';
import '../mobile_row_detail/mobile_row_detail_select_cell_option.dart';

abstract class IEditableSelectOptionCellSkin {
  const IEditableSelectOptionCellSkin();

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

  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    SelectOptionCellBloc bloc,
    PopoverController popoverController,
  );
}

class EditableSelectOptionCell extends EditableCellWidget {
  EditableSelectOptionCell({
    super.key,
    required this.databaseController,
    required this.cellContext,
    required this.skin,
    required this.fieldType,
  });

  final DatabaseController databaseController;
  final CellContext cellContext;
  final IEditableSelectOptionCellSkin skin;

  final FieldType fieldType;

  @override
  GridCellState<EditableSelectOptionCell> createState() =>
      _SelectOptionCellState();
}

class _SelectOptionCellState extends GridCellState<EditableSelectOptionCell> {
  final PopoverController _popover = PopoverController();

  late final cellBloc = SelectOptionCellBloc(
    cellController: makeCellController(
      widget.databaseController,
      widget.cellContext,
    ).as(),
  );

  @override
  void dispose() {
    cellBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cellBloc,
      child: widget.skin.build(
        context,
        widget.cellContainerNotifier,
        cellBloc,
        _popover,
      ),
    );
  }

  @override
  void onRequestFocus() => _popover.show();
}
