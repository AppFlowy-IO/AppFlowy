import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/widgets/row/accessory/cell_accessory.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/url_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../desktop_grid/desktop_grid_url_cell.dart';
import '../desktop_row_detail/desktop_row_detail_url_cell.dart';
import '../mobile_grid/mobile_grid_url_cell.dart';
import '../mobile_row_detail/mobile_row_detail_url_cell.dart';

abstract class IEditableURLCellSkin {
  const IEditableURLCellSkin();

  factory IEditableURLCellSkin.fromStyle(EditableCellStyle style) {
    return switch (style) {
      EditableCellStyle.desktopGrid => DesktopGridURLSkin(),
      EditableCellStyle.desktopRowDetail => DesktopRowDetailURLSkin(),
      EditableCellStyle.mobileGrid => MobileGridURLCellSkin(),
      EditableCellStyle.mobileRowDetail => MobileRowDetailURLCellSkin(),
    };
  }

  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    URLCellBloc bloc,
    FocusNode focusNode,
    TextEditingController textEditingController,
    URLCellDataNotifier cellDataNotifier,
  );

  List<GridCellAccessoryBuilder> accessoryBuilder(
    GridCellAccessoryBuildContext context,
    URLCellDataNotifier cellDataNotifier,
  );
}

typedef URLCellDataNotifier = CellDataNotifier<String>;

class EditableURLCell extends EditableCellWidget {
  EditableURLCell({
    super.key,
    required this.databaseController,
    required this.cellContext,
    required this.skin,
  }) : _cellDataNotifier = CellDataNotifier(value: '');

  final DatabaseController databaseController;
  final CellContext cellContext;
  final IEditableURLCellSkin skin;
  final URLCellDataNotifier _cellDataNotifier;

  @override
  List<GridCellAccessoryBuilder> Function(
    GridCellAccessoryBuildContext buildContext,
  ) get accessoryBuilder => (context) {
        return skin.accessoryBuilder(context, _cellDataNotifier);
      };

  @override
  GridCellState<EditableURLCell> createState() => _GridURLCellState();
}

class _GridURLCellState extends GridEditableTextCell<EditableURLCell> {
  late final TextEditingController _textEditingController;
  late final cellBloc = URLCellBloc(
    cellController: makeCellController(
      widget.databaseController,
      widget.cellContext,
    ).as(),
  )..add(const URLCellEvent.initial());

  @override
  SingleListenerFocusNode focusNode = SingleListenerFocusNode();

  @override
  void initState() {
    super.initState();
    _textEditingController =
        TextEditingController(text: cellBloc.state.content);
  }

  @override
  void dispose() {
    widget._cellDataNotifier.dispose();
    _textEditingController.dispose();
    cellBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cellBloc,
      child: BlocListener<URLCellBloc, URLCellState>(
        listenWhen: (previous, current) => previous.content != current.content,
        listener: (context, state) {
          _textEditingController.text = state.content;
          widget._cellDataNotifier.value = state.content;
        },
        child: widget.skin.build(
          context,
          widget.cellContainerNotifier,
          cellBloc,
          focusNode,
          _textEditingController,
          widget._cellDataNotifier,
        ),
      ),
    );
  }

  @override
  Future<void> focusChanged() async {
    if (mounted &&
        !cellBloc.isClosed &&
        cellBloc.state.content != _textEditingController.text.trim()) {
      cellBloc.add(URLCellEvent.updateURL(_textEditingController.text.trim()));
    }
    return super.focusChanged();
  }

  @override
  String? onCopy() => cellBloc.state.content;
}
