import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/time_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';

import '../desktop_grid/desktop_grid_time_cell.dart';
import '../desktop_row_detail/desktop_row_detail_time_cell.dart';
import '../mobile_grid/mobile_grid_time_cell.dart';
import '../mobile_row_detail/mobile_row_detail_time_cell.dart';

abstract class IEditableTimeCellSkin {
  const IEditableTimeCellSkin();

  factory IEditableTimeCellSkin.fromStyle(EditableCellStyle style) {
    return switch (style) {
      EditableCellStyle.desktopGrid => DesktopGridTimeCellSkin(),
      EditableCellStyle.desktopRowDetail => DesktopRowDetailTimeCellSkin(),
      EditableCellStyle.mobileGrid => MobileGridTimeCellSkin(),
      EditableCellStyle.mobileRowDetail => MobileRowDetailTimeCellSkin(),
    };
  }

  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    TimeCellBloc bloc,
    FocusNode focusNode,
    TextEditingController textEditingController,
    PopoverController popoverController,
  );
}

class EditableTimeCell extends EditableCellWidget {
  EditableTimeCell({
    super.key,
    required this.databaseController,
    required this.cellContext,
    required this.skin,
  });

  final DatabaseController databaseController;
  final CellContext cellContext;
  final IEditableTimeCellSkin skin;

  @override
  GridEditableTextCell<EditableTimeCell> createState() =>
      EditableTimeCellState();
}

@visibleForTesting
class EditableTimeCellState extends GridEditableTextCell<EditableTimeCell> {
  late final TextEditingController _textEditingController;
  final PopoverController _popover = PopoverController();
  late final cellBloc = TimeCellBloc(
    cellController: makeCellController(
      widget.databaseController,
      widget.cellContext,
    ).as(),
  );

  @override
  void initState() {
    super.initState();
    _textEditingController =
        TextEditingController(text: cellBloc.state.content);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    cellBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cellBloc,
      child: BlocListener<TimeCellBloc, TimeCellState>(
        listener: (context, state) =>
            _textEditingController.text = state.content,
        child: Builder(
          builder: (context) {
            return widget.skin.build(
              context,
              widget.cellContainerNotifier,
              cellBloc,
              focusNode,
              _textEditingController,
              _popover,
            );
          },
        ),
      ),
    );
  }

  @override
  SingleListenerFocusNode focusNode = SingleListenerFocusNode();

  @override
  void onRequestFocus() {
    final timeType = cellBloc.state.timeType;
    switch (timeType) {
      case TimeTypePB.PlainTime:
        focusNode.requestFocus();
        break;
      case TimeTypePB.Timer:
      case TimeTypePB.Stopwatch:
        _popover.show();
        break;
    }
  }

  @override
  String? onCopy() => cellBloc.state.content;

  @override
  Future<void> focusChanged() async {
    if (mounted &&
        !cellBloc.isClosed &&
        cellBloc.state.content != _textEditingController.text.trim()) {
      cellBloc
          .add(TimeCellEvent.updateTime(_textEditingController.text.trim()));
    }
    return super.focusChanged();
  }
}
