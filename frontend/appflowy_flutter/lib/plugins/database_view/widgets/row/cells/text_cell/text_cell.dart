import 'dart:async';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/text_cell/text_cell_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../grid/presentation/layout/sizes.dart';
import '../../cell_builder.dart';

class GridTextCellStyle extends GridCellStyle {
  String? placeholder;

  GridTextCellStyle({
    this.placeholder,
  });
}

class GridTextCell extends GridCellWidget {
  final CellControllerBuilder cellControllerBuilder;
  late final GridTextCellStyle? cellStyle;
  GridTextCell({
    required this.cellControllerBuilder,
    GridCellStyle? style,
    Key? key,
  }) : super(key: key) {
    if (style != null) {
      cellStyle = (style as GridTextCellStyle);
    } else {
      cellStyle = null;
    }
  }

  @override
  GridFocusNodeCellState<GridTextCell> createState() => _GridTextCellState();
}

class _GridTextCellState extends GridFocusNodeCellState<GridTextCell> {
  late TextCellBloc _cellBloc;
  late TextEditingController _controller;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as TextCellController;
    _cellBloc = TextCellBloc(cellController: cellController);
    _cellBloc.add(const TextCellEvent.initial());
    _controller = TextEditingController(text: _cellBloc.state.content);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocListener<TextCellBloc, TextCellState>(
        listener: (context, state) {
          if (_controller.text != state.content) {
            _controller.text = state.content;
          }
        },
        child: Padding(
          padding: EdgeInsets.only(
            left: GridSize.cellContentInsets.left,
            right: GridSize.cellContentInsets.right,
          ),
          child: TextField(
            controller: _controller,
            focusNode: focusNode,
            maxLines: null,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.only(
                top: GridSize.cellContentInsets.top,
                bottom: GridSize.cellContentInsets.bottom,
              ),
              border: InputBorder.none,
              hintText: widget.cellStyle?.placeholder,
              isDense: true,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    super.dispose();
  }

  @override
  String? onCopy() => _cellBloc.state.content;

  @override
  void onInsert(String value) {
    _cellBloc.add(TextCellEvent.updateText(value));
  }

  @override
  Future<void> focusChanged() {
    _cellBloc.add(
      TextCellEvent.updateText(_controller.text),
    );
    return super.focusChanged();
  }
}
