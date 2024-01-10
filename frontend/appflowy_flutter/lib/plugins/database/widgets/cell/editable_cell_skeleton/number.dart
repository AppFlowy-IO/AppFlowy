import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/number_cell/number_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../desktop_grid/desktop_grid_number_cell.dart';
import '../desktop_row_detail/desktop_row_detail_number_cell.dart';
import '../mobile_grid/mobile_grid_number_cell.dart';
import '../mobile_row_detail/mobile_row_detail_number_cell.dart';

abstract class IEditableNumberCellSkin {
  const IEditableNumberCellSkin();

  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    NumberCellBloc bloc,
    FocusNode focusNode,
    TextEditingController textEditingController,
  );

  factory IEditableNumberCellSkin.fromStyle(EditableCellStyle style) {
    return switch (style) {
      EditableCellStyle.desktopGrid => DesktopGridNumberCellSkin(),
      EditableCellStyle.desktopRowDetail => DesktopRowDetailNumberCellSkin(),
      EditableCellStyle.mobileGrid => MobileGridNumberCellSkin(),
      EditableCellStyle.mobileRowDetail => MobileRowDetailNumberCellSkin(),
    };
  }
}

class EditableNumberCell extends EditableCellWidget {
  final NumberCellController cellController;
  final IEditableNumberCellSkin skin;

  EditableNumberCell({
    required this.cellController,
    required this.skin,
    super.key,
  });

  @override
  GridEditableTextCell<EditableNumberCell> createState() => _NumberCellState();
}

class _NumberCellState extends GridEditableTextCell<EditableNumberCell> {
  late final TextEditingController _textEditingController;
  late final cellBloc = NumberCellBloc(cellController: widget.cellController)
    ..add(const NumberCellEvent.initial());

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
  }

  @override
  Future<void> dispose() async {
    _textEditingController.dispose();
    cellBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cellBloc,
      child: MultiBlocListener(
        listeners: [
          BlocListener<NumberCellBloc, NumberCellState>(
            listenWhen: (p, c) => p.cellContent != c.cellContent,
            listener: (context, state) =>
                _textEditingController.text = state.cellContent,
          ),
        ],
        child: widget.skin.build(
          context,
          widget.cellContainerNotifier,
          cellBloc,
          focusNode,
          _textEditingController,
        ),
      ),
    );
  }

  @override
  SingleListenerFocusNode focusNode = SingleListenerFocusNode();

  @override
  void requestBeginFocus() {
    focusNode.requestFocus(); //TODO YAY for other styles
  }

  @override
  String? onCopy() => cellBloc.state.cellContent;

  @override
  Future<void> focusChanged() async {
    if (mounted && !cellBloc.isClosed) {
      cellBloc.add(NumberCellEvent.updateCell(_textEditingController.text));
    }
  }
}
