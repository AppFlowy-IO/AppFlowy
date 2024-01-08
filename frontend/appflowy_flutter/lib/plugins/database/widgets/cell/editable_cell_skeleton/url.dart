import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/widgets/row/accessory/cell_accessory.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/url_cell/url_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/row/editable_cell_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../desktop_grid/desktop_grid_url_cell.dart';
import '../desktop_row_detail/desktop_row_detail_url_cell.dart';
import '../mobile_grid/mobile_grid_url_cell.dart';
import '../mobile_row_detail/mobile_row_detail_url_cell.dart';

abstract class IEditableURLCellSkin {
  const IEditableURLCellSkin();

  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    URLCellBloc bloc,
    FocusNode focusNode,
    TextEditingController textEditingController,
  );

  List<GridCellAccessoryBuilder> accessoryBuilder(
    GridCellAccessoryBuildContext buildContext,
  );

  factory IEditableURLCellSkin.fromStyle(EditableCellStyle style) {
    return switch (style) {
      EditableCellStyle.desktopGrid => DesktopGridURLSkin(),
      EditableCellStyle.desktopRowDetail => DesktopRowDetailURLSkin(),
      EditableCellStyle.mobileGrid => MobileGridURLCellSkin(),
      EditableCellStyle.mobileRowDetail => MobileRowDetailURLCellSkin(),
    };
  }
}

enum GridURLCellAccessoryType {
  copyURL,
  visitURL,
}

typedef URLCellDataNotifier = CellDataNotifier<String>;

class EditableURLCell extends EditableCellWidget {
  final URLCellController cellController;
  final IEditableURLCellSkin skin;
  final URLCellDataNotifier _cellDataNotifier;

  EditableURLCell({
    super.key,
    required this.cellController,
    required this.skin,
  }) : _cellDataNotifier = CellDataNotifier(value: '');

  @override
  List<GridCellAccessoryBuilder> Function(
    GridCellAccessoryBuildContext buildContext,
  ) get accessoryBuilder => skin.accessoryBuilder;

  @override
  GridCellState<EditableURLCell> createState() => _GridURLCellState();
}

class _GridURLCellState extends GridEditableTextCell<EditableURLCell> {
  late final TextEditingController _textEditingController;

  URLCellBloc get cellBloc => context.read<URLCellBloc>();

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
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        return URLCellBloc(cellController: widget.cellController)
          ..add(const URLCellEvent.initial());
      },
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
        ),
      ),
    );
  }

  @override
  Future<void> focusChanged() async {
    cellBloc.add(URLCellEvent.updateURL(_textEditingController.text.trim()));
    return super.focusChanged();
  }

  @override
  String? onCopy() => cellBloc.state.content;
}
