import 'package:flutter/material.dart';

import 'package:appflowy/plugins/database/application/cell/bloc/media_cell_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/widgets/cell/desktop_grid/desktop_grid_media_cell.dart';
import 'package:appflowy/plugins/database/widgets/cell/desktop_row_detail/desktop_row_detail_media_cell.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/cell/cell_controller_builder.dart';

abstract class IEditableMediaCellSkin {
  const IEditableMediaCellSkin();

  factory IEditableMediaCellSkin.fromStyle(EditableCellStyle style) {
    return switch (style) {
      EditableCellStyle.desktopGrid => DekstopGridMediaCellSkin(),
      EditableCellStyle.desktopRowDetail => DekstopRowDetailMediaCellSkin(),
      // TODO(Mathias): Implement the rest of the styles
      EditableCellStyle.mobileGrid => DekstopGridMediaCellSkin(),
      EditableCellStyle.mobileRowDetail => DekstopGridMediaCellSkin(),
    };
  }

  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    PopoverController popoverController,
    MediaCellBloc bloc,
  );
}

class EditableMediaCell extends EditableCellWidget {
  EditableMediaCell({
    super.key,
    required this.databaseController,
    required this.cellContext,
    required this.skin,
  });

  final DatabaseController databaseController;
  final CellContext cellContext;
  final IEditableMediaCellSkin skin;

  @override
  GridEditableTextCell<EditableMediaCell> createState() =>
      _EditableMediaCellState();
}

class _EditableMediaCellState extends GridEditableTextCell<EditableMediaCell> {
  final PopoverController popoverController = PopoverController();

  late final cellBloc = MediaCellBloc(
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
      value: cellBloc..add(const MediaCellEvent.initial()),
      child: Builder(
        builder: (context) => widget.skin.build(
          context,
          widget.cellContainerNotifier,
          popoverController,
          cellBloc,
        ),
      ),
    );
  }

  @override
  SingleListenerFocusNode focusNode = SingleListenerFocusNode();

  @override
  void onRequestFocus() => popoverController.show();

  @override
  String? onCopy() => null;
}
