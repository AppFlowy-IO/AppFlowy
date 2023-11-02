import 'dart:async';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/text_cell/text_cell_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileTextCell extends GridCellWidget {
  final CellControllerBuilder cellControllerBuilder;

  final String? hintText;

  MobileTextCell({
    required this.cellControllerBuilder,
    this.hintText,
    super.key,
  });

  @override
  GridEditableTextCell<MobileTextCell> createState() => _MobileTextCellState();
}

class _MobileTextCellState extends GridEditableTextCell<MobileTextCell> {
  late TextCellBloc _cellBloc;
  late TextEditingController _controller;

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
          // TODO(yijing): update text style
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            hintText: widget.hintText,
            isCollapsed: true,
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
  Future<void> focusChanged() {
    _cellBloc.add(
      TextCellEvent.updateText(_controller.text),
    );
    return super.focusChanged();
  }
}
