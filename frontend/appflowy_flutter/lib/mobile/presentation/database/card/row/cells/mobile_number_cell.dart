import 'dart:async';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/number_cell/number_cell_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileNumberCell extends GridCellWidget {
  MobileNumberCell({
    super.key,
    required this.cellControllerBuilder,
    this.hintText,
  });

  final CellControllerBuilder cellControllerBuilder;
  final String? hintText;

  @override
  GridEditableTextCell<MobileNumberCell> createState() => _NumberCellState();
}

class _NumberCellState extends GridEditableTextCell<MobileNumberCell> {
  late final NumberCellBloc _cellBloc;
  late final TextEditingController _controller;

  @override
  SingleListenerFocusNode focusNode = SingleListenerFocusNode();

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as NumberCellController;
    _cellBloc = NumberCellBloc(cellController: cellController)
      ..add(const NumberCellEvent.initial());
    _controller = TextEditingController(text: _cellBloc.state.cellContent);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: MultiBlocListener(
        listeners: [
          BlocListener<NumberCellBloc, NumberCellState>(
            listenWhen: (p, c) => p.cellContent != c.cellContent,
            listener: (context, state) => _controller.text = state.cellContent,
          ),
        ],
        child: TextField(
          controller: _controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            hintText: widget.hintText,
            contentPadding: EdgeInsets.zero,
            isCollapsed: true,
          ),
          // close keyboard when tapping outside of the text field
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
  Future<void> focusChanged() async {
    if (mounted &&
        _cellBloc.isClosed == false &&
        _controller.text != _cellBloc.state.cellContent) {
      _cellBloc.add(NumberCellEvent.updateCell(_controller.text));
    }
  }

  @override
  String? onCopy() => _cellBloc.state.cellContent;
}
