import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/bloc/summary_cell_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/text.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/text_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../desktop_grid/desktop_grid_text_cell.dart';
import '../desktop_row_detail/desktop_row_detail_text_cell.dart';
import '../mobile_grid/mobile_grid_text_cell.dart';
import '../mobile_row_detail/mobile_row_detail_text_cell.dart';

class EditableSummaryCell extends EditableCellWidget {
  EditableSummaryCell({
    super.key,
    required this.databaseController,
    required this.cellContext,
    required this.skin,
  });

  final DatabaseController databaseController;
  final CellContext cellContext;
  final IEditableTextCellSkin skin;

  @override
  GridEditableSummaryCell<EditableSummaryCell> createState() =>
      _SummaryCellState();
}

}

class _SummaryCellState extends GridEditableSummaryCell<EditableSummaryCell> {
  late final TextEditingController _textEditingController;
  late final cellBloc = SummaryCellBloc(
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
      child: BlocListener<SummaryCellBloc, SummaryCellState>(
        listener: (context, state) {
          _textEditingController.text = state.content;
        },
        child: Builder(
          builder: (context) {
            return widget.skin.build(
              context,
              widget.cellContainerNotifier,
              cellBloc,
              focusNode,
              _textEditingController,
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
    focusNode.requestFocus();
  }

  @override
  String? onCopy() => cellBloc.state.content;

  @override
  Future<void> focusChanged() {
    if (mounted &&
        !cellBloc.isClosed &&
        cellBloc.state.content != _textEditingController.text.trim()) {
      cellBloc
          .add(SummaryCellEvent.updateText(_textEditingController.text.trim()));
    }
    return super.focusChanged();
  }
}
