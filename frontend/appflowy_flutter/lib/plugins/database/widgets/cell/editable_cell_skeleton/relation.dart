import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/relation_cell_bloc.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../desktop_grid/desktop_grid_relation_cell.dart';
import '../desktop_row_detail/desktop_row_detail_relation_cell.dart';
import '../mobile_grid/mobile_grid_relation_cell.dart';
import '../mobile_row_detail/mobile_row_detail_relation_cell.dart';

abstract class IEditableRelationCellSkin {
  factory IEditableRelationCellSkin.fromStyle(EditableCellStyle style) {
    return switch (style) {
      EditableCellStyle.desktopGrid => DesktopGridRelationCellSkin(),
      EditableCellStyle.desktopRowDetail => DesktopRowDetailRelationCellSkin(),
      EditableCellStyle.mobileGrid => MobileGridRelationCellSkin(),
      EditableCellStyle.mobileRowDetail => MobileRowDetailRelationCellSkin(),
    };
  }

  const IEditableRelationCellSkin();

  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    RelationCellBloc bloc,
    RelationCellState state,
    PopoverController popoverController,
  );
}

class EditableRelationCell extends EditableCellWidget {
  EditableRelationCell({
    super.key,
    required this.databaseController,
    required this.cellContext,
    required this.skin,
  });

  final DatabaseController databaseController;
  final CellContext cellContext;
  final IEditableRelationCellSkin skin;

  @override
  GridCellState<EditableRelationCell> createState() => _RelationCellState();
}

class _RelationCellState extends GridCellState<EditableRelationCell> {
  final PopoverController _popover = PopoverController();
  late final cellBloc = RelationCellBloc(
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
      child: BlocBuilder<RelationCellBloc, RelationCellState>(
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
  String? onCopy() => "";
}
