import 'dart:async';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/text_cell/text_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/text_cell/text_cell_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileTextCell extends GridCellWidget {
  MobileTextCell({
    super.key,
    required this.cellControllerBuilder,
    GridCellStyle? style,
  }) {
    if (style != null) {
      cellStyle = (style as GridTextCellStyle);
    } else {
      cellStyle = const GridTextCellStyle();
    }
  }

  final CellControllerBuilder cellControllerBuilder;
  late final GridTextCellStyle cellStyle;

  @override
  GridEditableTextCell<MobileTextCell> createState() => _MobileTextCellState();
}

class _MobileTextCellState extends GridEditableTextCell<MobileTextCell> {
  late final TextCellBloc _cellBloc;
  late final TextEditingController _controller;

  @override
  SingleListenerFocusNode focusNode = SingleListenerFocusNode();

  @override
  void initState() {
    super.initState();
    final cellController =
        widget.cellControllerBuilder.build() as TextCellController;
    _cellBloc = TextCellBloc(cellController: cellController)
      ..add(const TextCellEvent.initial());
    _controller = TextEditingController(text: _cellBloc.state.content);
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
        child: TextField(
          controller: _controller,
          focusNode: focusNode,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15),
          decoration: InputDecoration(
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            hintText: widget.cellStyle.placeholder,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            isCollapsed: true,
          ),
          onTapOutside: (event) =>
              FocusManager.instance.primaryFocus?.unfocus(),
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
  Future<void> focusChanged() {
    _cellBloc.add(TextCellEvent.updateText(_controller.text));
    return super.focusChanged();
  }
}
