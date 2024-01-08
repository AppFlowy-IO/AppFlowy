import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/row/editable_cell_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'number_cell_bloc.dart';

class GridNumberCellStyle extends GridCellStyle {
  String? placeholder;
  TextStyle? textStyle;
  EdgeInsets? cellPadding;

  GridNumberCellStyle({
    this.placeholder,
    this.textStyle,
    this.cellPadding,
  });
}

class GridNumberCell extends GridCellWidget {
  final NumberCellController cellController;
  late final GridNumberCellStyle cellStyle;

  GridNumberCell({
    required this.cellController,
    required GridCellStyle? style,
    super.key,
  }) {
    if (style != null) {
      cellStyle = (style as GridNumberCellStyle);
    } else {
      cellStyle = GridNumberCellStyle();
    }
  }

  @override
  GridEditableTextCell<GridNumberCell> createState() => _NumberCellState();
}

class _NumberCellState extends GridEditableTextCell<GridNumberCell> {
  late NumberCellBloc _cellBloc;
  late TextEditingController _controller;

  @override
  SingleListenerFocusNode focusNode = SingleListenerFocusNode();

  @override
  void initState() {
    super.initState();
    _cellBloc = NumberCellBloc(cellController: widget.cellController)
      ..add(const NumberCellEvent.initial());
    _controller = TextEditingController(text: _cellBloc.state.cellContent);
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
          onEditingComplete: () => focusNode.unfocus(),
          onSubmitted: (_) => focusNode.unfocus(),
          maxLines: null,
          style: Theme.of(context).textTheme.bodyMedium,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            contentPadding:
                widget.cellStyle.cellPadding ?? GridSize.cellContentInsets,
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            hintText: widget.cellStyle.placeholder,
            isDense: true,
          ),
          onTapOutside: (_) => focusNode.unfocus(),
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
    if (mounted) {
      if (_cellBloc.isClosed == false &&
          _controller.text != _cellBloc.state.cellContent) {
        _cellBloc.add(NumberCellEvent.updateCell(_controller.text));
      }
    }
  }

  @override
  String? onCopy() {
    return _cellBloc.state.cellContent;
  }
}
